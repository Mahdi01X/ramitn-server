import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/game_provider.dart';
import '../../engine/game_engine.dart';
import '../../engine/meld_validator.dart';
import '../../models/card.dart' as models;
import '../../models/meld.dart';
import '../../models/game_config.dart';
import '../../core/theme.dart';
import '../../services/music_service.dart';
import '../../services/sfx_service.dart';
import 'widgets/playing_card.dart';
import 'widgets/fan_hand_widget.dart';
import 'widgets/opponent_hand_widget.dart';
import 'widgets/felt_table.dart';
import 'widgets/game_action_bar.dart';
import 'widgets/score_board_widget.dart';

class GameTableScreen extends ConsumerStatefulWidget {
  const GameTableScreen({super.key});

  @override
  ConsumerState<GameTableScreen> createState() => _GameTableScreenState();
}

class _GameTableScreenState extends ConsumerState<GameTableScreen> with WidgetsBindingObserver {
  bool _hotSeatReady = false;
  String? _lastPlayerIdShown;
  bool _musicPlaying = true;
  bool _wasMyTurn = false;
  bool _isResuming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MusicService.instance.play();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MusicService.instance.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App going to background — pause music
      if (_musicPlaying) MusicService.instance.pause();
    } else if (state == AppLifecycleState.resumed) {
      // App coming back — resume music and force a clean rebuild
      if (_musicPlaying) MusicService.instance.resume();
      // Force a rebuild to ensure fresh UI state after resume
      if (mounted) {
        setState(() => _isResuming = true);
        // Schedule a microtask to reset after frame completes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _isResuming = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    // Phase routing
    if (gs.phase == 'roundEnd' || gs.phase == 'round_end' || gs.phase == LocalGamePhase.roundEnd.name) {
      return _RoundEndScreen(gameState: gs, notifier: notifier);
    }
    if (gs.phase == 'gameEnd' || gs.phase == 'game_end' || gs.phase == LocalGamePhase.gameEnd.name) {
      return _GameEndScreen(gameState: gs);
    }
    // Feature 5: Frich vote phase
    if (gs.phase == LocalGamePhase.frichVote.name) {
      return _FrichVoteScreen(gameState: gs, notifier: notifier);
    }

    final isOffline = gs.mode == GameMode.offline;
    final engine = gs.offlineEngine;
    final onlineState = gs.onlineState;

    // Waiting for game state in online mode
    if (!isOffline && onlineState == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D3B13),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFFFD700)),
              SizedBox(height: 16),
              Text('Chargement de la partie...', style: TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    // Extract current state
    String playerName = '';
    String playerId = '';
    bool isMyTurn = false;
    bool isHumanHotSeat = false;
    String turnStep = gs.turnStep;
    List<models.Card> myHand = [];
    models.Card? topDiscard;
    int drawPileCount = 0;
    List<Meld> tableMelds = [];
    GameConfig config = const GameConfig();
    bool hasOpened = false;
    bool drewFromDiscard = false;

    if (isOffline && engine != null) {
      final st = engine.state;
      // Always show the first human player's hand (not the bot's hand during bot turn)
      final humanPlayer = st.players.firstWhere((p) => !p.isBot, orElse: () => st.currentPlayer);
      playerName = st.currentPlayer.name;
      playerId = humanPlayer.id;
      isMyTurn = !st.currentPlayer.isBot;
      isHumanHotSeat = isMyTurn && st.players.where((p) => !p.isBot).length > 1;
      myHand = humanPlayer.hand;
      topDiscard = st.discardPile.isNotEmpty ? st.discardPile.last : null;
      drawPileCount = st.drawPile.length;
      tableMelds = st.tableMelds;
      config = st.config;
      hasOpened = humanPlayer.hasOpened;
      drewFromDiscard = humanPlayer.drewFromDiscard;
    } else if (onlineState != null) {
      playerName = onlineState.currentPlayer?.name ?? '';
      playerId = onlineState.currentPlayer?.id ?? '';
      isMyTurn = gs.isMyTurn;
      // Sort hand according to user's custom arrangement
      final handOrder = gs.onlineHandOrder;
      if (handOrder.isNotEmpty) {
        final handMap = {for (var c in onlineState.myHand) c.id: c};
        myHand = handOrder.where((id) => handMap.containsKey(id)).map((id) => handMap[id]!).toList();
        // Add any cards not in order (shouldn't happen, but safety)
        for (final c in onlineState.myHand) {
          if (!handOrder.contains(c.id)) myHand.add(c);
        }
      } else {
        myHand = onlineState.myHand;
      }
      topDiscard = onlineState.topDiscard;
      drawPileCount = onlineState.drawPileCount;
      tableMelds = onlineState.tableMelds;
      config = onlineState.config;
      // Find my player info for hasOpened
      final myInfoMatches = onlineState.players.where((p) => p.id == gs.myPlayerId);
      final myInfo = myInfoMatches.isNotEmpty ? myInfoMatches.first : null;
      hasOpened = myInfo?.hasOpened ?? false;
      turnStep = onlineState.turnStep;
    }

    // Hot-seat handoff
    if (isHumanHotSeat && playerId != _lastPlayerIdShown) _hotSeatReady = false;
    if (isHumanHotSeat && !_hotSeatReady) {
      return _HotSeatHandoffScreen(
        playerName: playerName,
        onReady: () => setState(() { _hotSeatReady = true; _lastPlayerIdShown = playerId; }),
        onQuit: () => _showQuitDialog(context),
      );
    }
    if (isOffline) _lastPlayerIdShown = playerId;

    // Haptic + sfx feedback when it becomes my turn
    if (isMyTurn && !_wasMyTurn) {
      SfxService.instance.yourTurn();
    }
    _wasMyTurn = isMyTurn;

    // ─── Staging: filter out staged card IDs from visible hand ───
    final stagedCardIds = gs.stagedMelds.expand((m) => m.cardIds).toSet();
    final visibleHand = myHand.where((c) => !stagedCardIds.contains(c.id)).toList();

    // ─── Real-time selection validation ──────────────────
    final selectedCards = visibleHand.where((c) => gs.selectedCardIds.contains(c.id)).toList();
    final meldType = selectedCards.length >= 3 ? validateMeld(selectedCards, config) : null;
    final meldIsValid = meldType != null;
    final meldPoints = selectedCards.isNotEmpty ? calculateMeldPoints(selectedCards, config) : 0;
    final validHighlightIds = meldIsValid ? gs.selectedCardIds.toSet() : <int>{};

    // ─── Staging totals ──────────────────────────────────
    final stagedTotal = gs.stagedMelds.fold<int>(0, (s, m) => s + m.points);
    final stagedHasCleanRun = gs.stagedMelds.any((m) => m.type == 'run' && !m.hasJoker);
    final previewTotal = stagedTotal + (meldIsValid ? meldPoints : 0);
    final canConfirmOpening = !hasOpened
        && gs.stagedMelds.isNotEmpty
        && stagedTotal >= config.openingThreshold
        && stagedHasCleanRun;

    // Build player info for grouped melds display
    final playerInfosForTable = <({String id, String name, int openingScore, bool hasOpened})>[];
    if (isOffline && engine != null) {
      for (final p in engine.state.players) {
        playerInfosForTable.add((id: p.id, name: p.name, openingScore: p.openingScore, hasOpened: p.hasOpened));
      }
    } else if (onlineState != null) {
      for (final p in onlineState.players) {
        playerInfosForTable.add((id: p.id, name: p.name, openingScore: p.openingScore, hasOpened: p.hasOpened));
      }
    }

    // Build opponent info
    final opponents = <_PInfo>[];
    if (isOffline && engine != null) {
      for (final p in engine.state.players) {
        if (p.id != playerId) {
          opponents.add(_PInfo(p.name, p.hand.length,
              p.id == engine.state.currentPlayer.id, p.totalScore, p.isBot,
              hasOpened: p.hasOpened, openingScore: p.openingScore));
        }
      }
    } else if (onlineState != null) {
      for (int i = 0; i < onlineState.players.length; i++) {
        final p = onlineState.players[i];
        if (p.id != gs.myPlayerId) {
          opponents.add(_PInfo(p.name, p.handCount,
              i == onlineState.currentPlayerIndex, p.totalScore, p.isBot,
              hasOpened: p.hasOpened, openingScore: p.openingScore));
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D3B13),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Opponent hand(s) at top ───
            if (opponents.isNotEmpty)
              OpponentHandWidget.multi(
                opponents: opponents.map((o) => OpponentInfo(
                  name: o.name,
                  handCount: o.handCount,
                  isActive: o.active,
                  totalScore: o.score,
                  hasOpened: o.hasOpened,
                  openingScore: o.openingScore,
                )).toList(),
              ),

            // ─── Compact header ───
            _CompactHeader(
              playerName: playerName,
              isMyTurn: isMyTurn,
              turnStep: turnStep,
              round: isOffline ? engine?.state.round ?? 0 : 0,
              maxRounds: isOffline ? config.maxRounds : 0,
              onBack: () => _showQuitDialog(context),
              onScore: () => _showScoreBoard(context, gs),
              musicPlaying: _musicPlaying,
              onToggleMusic: () {
                setState(() => _musicPlaying = !_musicPlaying);
                if (_musicPlaying) { MusicService.instance.play(); }
                else { MusicService.instance.stop(); }
              },
              onOpenAudioSelector: () => _showAudioSelector(context),
              turnTimeoutSeconds: config.turnTimeoutSeconds,
              isFirstTurn: isOffline ? (engine?.state.turnCount ?? 0) < (engine?.state.players.length ?? 1) : false,
            ),

            // Felt table
            Expanded(
              child: FeltTable(
                drawPileCount: drawPileCount,
                topDiscard: topDiscard,
                tableMelds: tableMelds,
                stagedMelds: gs.stagedMelds,
                turnStep: turnStep,
                isMyTurn: isMyTurn,
                openingPoints: previewTotal,
                hasOpened: hasOpened,
                config: config,
                currentPlayerId: playerId,
                playerInfos: playerInfosForTable,
                selectedCard: gs.selectedCardIds.length == 1 && hasOpened
                    ? (visibleHand.where((c) => c.id == gs.selectedCardIds.first).isNotEmpty
                        ? visibleHand.where((c) => c.id == gs.selectedCardIds.first).first
                        : null)
                    : null,
                onDrawDeck: isMyTurn && turnStep == 'draw'
                    ? () { SfxService.instance.cardDraw(); isOffline ? notifier.offlineDrawFromDeck() : notifier.onlineAction({'type': 'draw_deck'}); }
                    : null,
                onDrawDiscard: isMyTurn && turnStep == 'draw' && topDiscard != null
                    && !(isOffline && engine != null && engine.isDiscardDuplicate())
                    && !(!isOffline && topDiscard != null && !topDiscard!.isJoker && config.duplicateProtection
                        && myHand.any((c) => !c.isJoker && c.rank == topDiscard!.rank && c.suit == topDiscard!.suit))
                    ? () { SfxService.instance.cardDraw(); _confirmDrawFromDiscard(context, notifier, isOffline, hasOpened, config); }
                    : null,
                // Tap on a meld to lay off selected card
                onTapMeld: isMyTurn && turnStep == 'play' && hasOpened && gs.selectedCardIds.length == 1
                    ? (meldId) {
                        final cardId = gs.selectedCardIds.first;
                        SfxService.instance.layoff();
                        if (isOffline) {
                          final msg = notifier.offlineLayoffDrag(cardId, meldId);
                          if (msg != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg), backgroundColor: const Color(0xFF4CAF50), duration: const Duration(seconds: 2)),
                            );
                          }
                        } else {
                          notifier.onlineAction({'type': 'layoff', 'cardId': cardId, 'meldId': meldId});
                        }
                        notifier.clearSelection();
                      }
                    : null,
                // Drag card onto a meld (layoff)
                onDropOnMeld: isMyTurn && turnStep == 'play' && hasOpened
                    ? (cardId, meldId) {
                        if (isOffline) {
                          final msg = notifier.offlineLayoffDrag(cardId, meldId);
                          if (msg != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg), backgroundColor: const Color(0xFF4CAF50), duration: const Duration(seconds: 2)),
                            );
                          }
                        } else {
                          notifier.onlineAction({'type': 'layoff', 'cardId': cardId, 'meldId': meldId});
                        }
                      }
                    : null,
                // Drag card to discard pile
                onDropDiscard: isMyTurn && turnStep == 'play' && gs.stagedMelds.isEmpty
                    ? (cardId) {
                        SfxService.instance.cardDiscard();
                        if (isOffline) {
                          notifier.offlineDiscard(cardId);
                        } else {
                          notifier.onlineAction({'type': 'discard', 'cardId': cardId});
                        }
                        notifier.clearSelection();
                      }
                    : null,
              ),
            ),

            // Error
            if (gs.error != null)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFC0392B).withOpacity(0.95),
                      const Color(0xFF922B21).withOpacity(0.95),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, -2)),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(gs.error!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
                    GestureDetector(
                      onTap: () => notifier.clearSelection(),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                        ),
                        child: const Icon(Icons.close, color: Colors.white70, size: 14),
                      ),
                    ),
                  ],
                ),
              ),

            // Warning: drew from discard, must open or 100pts penalty
            if (drewFromDiscard && !hasOpened && isMyTurn && turnStep == 'play')
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE65100).withOpacity(0.95),
                      const Color(0xFFBF360C).withOpacity(0.95),
                    ],
                  ),
                  border: Border(
                    top: BorderSide(color: const Color(0xFFFF8F00).withOpacity(0.6), width: 1),
                    bottom: BorderSide(color: const Color(0xFFFF8F00).withOpacity(0.3), width: 1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Vous avez pioché du talon ! Ouvrez ou recevez 100 pts de pénalité.',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Action bar (play step only)
            if (isMyTurn && turnStep == 'play')
              GameActionBar(
                selectedCount: gs.selectedCardIds.length,
                selectionIsValid: meldIsValid,
                selectionPoints: meldPoints,
                selectionType: meldType?.name,
                stagedMelds: gs.stagedMelds,
                stagedTotalPoints: stagedTotal,
                stagedHasCleanRun: stagedHasCleanRun,
                canConfirmOpening: canConfirmOpening,
                hasOpened: hasOpened,
                openingRequired: config.openingThreshold,
                canDiscard: gs.selectedCardIds.length == 1 && gs.stagedMelds.isEmpty,
                onStageMeld: meldIsValid ? () {
                  SfxService.instance.meldPlace();
                  notifier.stageMeld(
                    gs.selectedCardIds,
                    selectedCards,
                    meldType!.name,
                    meldPoints,
                    selectedCards.any((c) => c.isJoker),
                  );
                } : null,
                onConfirmOpen: canConfirmOpening ? () { SfxService.instance.openingConfirm(); notifier.confirmOpening(); } : null,
                onDirectMeld: hasOpened && meldIsValid ? () {
                  SfxService.instance.meldPlace();
                  if (isOffline) {
                    notifier.offlineMeld();
                  } else {
                    notifier.onlineAction({'type': 'meld', 'cardIds': gs.selectedCardIds});
                    notifier.clearSelection();
                  }
                } : null,
                onDiscard: gs.selectedCardIds.length == 1 && gs.stagedMelds.isEmpty ? () {
                  SfxService.instance.cardDiscard();
                  final cardId = gs.selectedCardIds.first;
                  if (isOffline) {
                    notifier.offlineDiscard(cardId);
                  } else {
                    notifier.onlineAction({'type': 'discard', 'cardId': cardId});
                  }
                  notifier.clearSelection();
                } : null,
                onClear: () => notifier.clearSelection(),
                onUnstageMeld: (id) => notifier.unstageMeld(id),
              ),

            // Hand (fan layout — all cards visible)
            FanHandWidget(
              cards: visibleHand,
              selectedIds: gs.selectedCardIds.toSet(),
              validHighlightIds: validHighlightIds,
              newlyDrawnCardId: gs.newlyDrawnCardId,
              onTapCard: (id) { SfxService.instance.cardTap(); notifier.toggleCardSelection(id); },
              onReorder: (from, to) { SfxService.instance.cardSlide(); notifier.reorderCard(from, to); },
              onReorderGroup: (cardIds, insertIdx) { SfxService.instance.cardSlide(); notifier.reorderGroup(cardIds, insertIdx); },
              onDragToDiscard: isMyTurn && turnStep == 'play' && gs.stagedMelds.isEmpty
                  ? (cardId) {
                      SfxService.instance.cardDiscard();
                      if (isOffline) { notifier.offlineDiscard(cardId); }
                      else { notifier.onlineAction({'type': 'discard', 'cardId': cardId}); }
                      notifier.clearSelection();
                    }
                  : null,
              onDropDrawnCard: isMyTurn && turnStep == 'draw'
                  ? (insertIndex) {
                      SfxService.instance.cardDraw();
                      if (isOffline) { notifier.offlineDrawFromDeck(); }
                      else { notifier.onlineAction({'type': 'draw_deck'}); }
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showQuitDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B0E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.15),
              ),
              child: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Quitter la partie ?', style: TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Ta progression sera perdue. Es-tu sûr de vouloir quitter ?',
          style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Rester', style: TextStyle(color: CafeTunisienColors.goldLight, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); ref.read(gameProvider.notifier).disconnectOnline(); GoRouter.of(ctx).go('/'); },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  /// Show a confirmation dialog before drawing from the discard pile.
  /// Warns the player that if they can't open (reach opening threshold), they lose 100pts.
  void _confirmDrawFromDiscard(BuildContext ctx, GameNotifier notifier, bool isOffline, bool hasOpened, GameConfig config) {
    if (hasOpened) {
      // Already opened — no penalty risk, draw directly
      if (isOffline) {
        notifier.offlineDrawFromDiscard();
      } else {
        notifier.onlineAction({'type': 'draw_discard'});
      }
      return;
    }

    // Not opened yet — show warning
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dCtx) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B0E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('⚠️', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Expanded(child: Text('Attention !', style: TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(
          'Si tu pioches cette carte et que tu n\'arrives pas à ouvrir (${config.openingThreshold} pts minimum avec une suite sans joker), tu perdras la manche avec une pénalité de 100 points !\n\nEs-tu sûr ?',
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dCtx);
              if (isOffline) {
                notifier.offlineDrawFromDiscard();
              } else {
                notifier.onlineAction({'type': 'draw_discard'});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Je prends le risque !'),
          ),
        ],
      ),
    );
  }

  void _showAudioSelector(BuildContext ctx) {
    // Start fetching radios immediately
    List<RadioStation> radioStations = [];
    bool loadingRadios = true;

    fetchTunisianRadios().then((stations) {
      radioStations = stations;
      loadingRadios = false;
    });

    showModalBottomSheet(
      context: ctx,
      backgroundColor: const Color(0xFF1A0E06),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          final music = MusicService.instance;
          final currentMode = music.mode;
          final currentStation = music.currentStation;

          // Refresh when radios load
          if (loadingRadios) {
            fetchTunisianRadios().then((stations) {
              radioStations = stations;
              loadingRadios = false;
              if (context.mounted) setSheetState(() {});
            });
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('🎧 Audio', style: TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  music.currentLabel,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
                const SizedBox(height: 12),

                // Volume slider
                Row(
                  children: [
                    const Icon(Icons.volume_down_rounded, color: Colors.white38, size: 18),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: const Color(0xFFFFD700),
                          inactiveTrackColor: Colors.white12,
                          thumbColor: const Color(0xFFFFD700),
                          overlayColor: const Color(0xFFFFD700).withOpacity(0.15),
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        ),
                        child: Slider(
                          value: music.volume,
                          onChanged: (v) {
                            music.setVolume(v);
                            setSheetState(() {});
                          },
                        ),
                      ),
                    ),
                    const Icon(Icons.volume_up_rounded, color: Colors.white38, size: 18),
                  ],
                ),
                const SizedBox(height: 8),

                // Off button
                _AudioOptionTile(
                  emoji: '🔇',
                  title: 'Audio off',
                  subtitle: 'Silence total',
                  isSelected: currentMode == AudioMode.off,
                  onTap: () {
                    music.switchOff();
                    setState(() => _musicPlaying = false);
                    setSheetState(() {});
                  },
                ),

                // Local music
                _AudioOptionTile(
                  emoji: '🎵',
                  title: 'Yasmina',
                  subtitle: 'Musique du café tunisien',
                  isSelected: currentMode == AudioMode.localMusic,
                  onTap: () {
                    music.switchToLocalMusic();
                    setState(() => _musicPlaying = true);
                    setSheetState(() {});
                  },
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(width: 30, height: 1, color: Colors.white12),
                    const SizedBox(width: 8),
                    Text('📻 Radios Tunisiennes en direct', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Expanded(child: Container(height: 1, color: Colors.white12)),
                  ],
                ),
                const SizedBox(height: 6),

                // Radio stations — dynamically loaded
                if (loadingRadios)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700))),
                        SizedBox(width: 10),
                        Text('Chargement des radios...', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 230),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: radioStations.length,
                      itemBuilder: (_, i) {
                        final station = radioStations[i];
                        final isActive = currentMode == AudioMode.radio &&
                            currentStation?.url == station.url;
                        return _AudioOptionTile(
                          emoji: station.emoji,
                          title: station.name,
                          subtitle: isActive && music.isLoading
                              ? '⏳ Connexion...'
                              : isActive && music.lastError != null
                                  ? '❌ Erreur — touchez pour réessayer'
                                  : isActive && music.isPlaying
                                      ? '▶ En cours de lecture'
                                      : station.description ?? 'Radio en direct',
                          isSelected: isActive,
                          isLive: true,
                          onTap: () async {
                            setSheetState(() {});
                            await music.switchToRadio(station);
                            setState(() => _musicPlaying = true);
                            if (context.mounted) setSheetState(() {});
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showScoreBoard(BuildContext ctx, GameProviderState gs) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: const Color(0xFF1A0E06),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ScoreBoardWidget(gameState: gs),
    );
  }
}

// ─── Compact Header ─────────────────────────────────────────

class _CompactHeader extends StatelessWidget {
  final String playerName;
  final bool isMyTurn;
  final String turnStep;
  final int round;
  final int maxRounds;
  final VoidCallback onBack;
  final VoidCallback onScore;
  final bool musicPlaying;
  final VoidCallback onToggleMusic;
  final VoidCallback onOpenAudioSelector;
  final int turnTimeoutSeconds;
  final bool isFirstTurn;

  const _CompactHeader({
    required this.playerName, required this.isMyTurn, required this.turnStep,
    required this.round, required this.maxRounds, required this.onBack, required this.onScore,
    required this.musicPlaying, required this.onToggleMusic, required this.onOpenAudioSelector,
    this.turnTimeoutSeconds = 60,
    this.isFirstTurn = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDraw = turnStep == 'draw';
    final statusColor = isMyTurn
        ? (isDraw ? const Color(0xFFE8A317) : const Color(0xFF4CAF50))
        : const Color(0xFF78909C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF4A2208),
            const Color(0xFF3E1F00).withOpacity(0.97),
            const Color(0xFF2C1508).withOpacity(0.9),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: const Color(0xFFD4A017).withOpacity(0.5), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Back button
          _HeaderIconBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
            size: 14,
          ),
          const SizedBox(width: 4),

          // Player name + turn status
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withOpacity(0.2),
                    statusColor.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
              ),
              child: Row(
                children: [
                  // Turn indicator dot
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                      boxShadow: isMyTurn
                          ? [BoxShadow(color: statusColor.withOpacity(0.6), blurRadius: 6)]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Status text
                  Expanded(
                    child: Text(
                      isMyTurn
                          ? (isDraw ? 'Piochez une carte' : 'Jouez vos cartes')
                          : 'Tour de $playerName...',
                      style: TextStyle(
                        color: isMyTurn ? Colors.white : Colors.white60,
                        fontSize: 11,
                        fontWeight: isMyTurn ? FontWeight.w700 : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Timer
          _TurnTimer(isMyTurn: isMyTurn, seconds: turnTimeoutSeconds, isFirstTurn: isFirstTurn),

          // Round badge
          if (round > 0) ...[
            const SizedBox(width: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.15)),
              ),
              child: Text(
                '$round/$maxRounds',
                style: TextStyle(color: CafeTunisienColors.gold.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ),
          ],

          // Music / Radio selector
          _HeaderIconBtn(
            icon: musicPlaying ? Icons.radio_rounded : Icons.music_off_rounded,
            onTap: onOpenAudioSelector,
            size: 15,
          ),

          // Score button
          _HeaderIconBtn(
            icon: Icons.leaderboard_rounded,
            onTap: onScore,
            size: 15,
          ),
        ],
      ),
    );
  }
}

/// Small icon button for the header bar
class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _HeaderIconBtn({required this.icon, required this.onTap, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: CafeTunisienColors.goldLight, size: size),
      ),
    );
  }
}

/// Animated countdown timer that resets each turn
class _TurnTimer extends StatefulWidget {
  final bool isMyTurn;
  final int seconds;
  final bool isFirstTurn;
  const _TurnTimer({required this.isMyTurn, required this.seconds, this.isFirstTurn = false});

  @override
  State<_TurnTimer> createState() => _TurnTimerState();
}

class _TurnTimerState extends State<_TurnTimer> {
  late int _remaining;
  Timer? _timer;

  /// First turn after dealing = 60s for organizing cards
  static const int _firstTurnSeconds = 60;

  int get _effectiveSeconds => widget.isFirstTurn ? _firstTurnSeconds : widget.seconds;

  @override
  void initState() {
    super.initState();
    _remaining = _effectiveSeconds;
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _TurnTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset timer when turn changes OR when isFirstTurn changes
    if (oldWidget.isMyTurn != widget.isMyTurn || oldWidget.isFirstTurn != widget.isFirstTurn) {
      _remaining = _effectiveSeconds;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 0 && mounted) {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLow = _remaining <= 10;
    final isCritical = _remaining <= 5;
    final color = isCritical ? Colors.red : isLow ? Colors.redAccent : Colors.white60;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: isLow
            ? LinearGradient(
                colors: [
                  Colors.red.withOpacity(isCritical ? 0.4 : 0.2),
                  Colors.red.withOpacity(isCritical ? 0.25 : 0.1),
                ],
              )
            : null,
        color: isLow ? null : Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: isLow ? Border.all(color: Colors.redAccent.withOpacity(0.6)) : null,
        boxShadow: isCritical
            ? [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 8)]
            : null,
      ),
      child: Text(
        '⏱ ${_remaining}s',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: isLow ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

// ─── Data class for player info ──────────────────────────────

class _PInfo {
  final String name; final int handCount; final bool active; final int score; final bool isBot;
  final bool hasOpened; final int openingScore;
  _PInfo(this.name, this.handCount, this.active, this.score, this.isBot, {this.hasOpened = false, this.openingScore = 0});
}

// ─── Round End ───────────────────────────────────────────────

class _RoundEndScreen extends StatelessWidget {
  final GameProviderState gameState;
  final GameNotifier notifier;
  const _RoundEndScreen({required this.gameState, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final isOffline = gameState.mode == GameMode.offline;
    final engine = gameState.offlineEngine;
    final onlineResults = gameState.onlineRoundResults;
    return Scaffold(
      backgroundColor: const Color(0xFF0A140B),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Trophy with double glow
                Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      CafeTunisienColors.gold.withOpacity(0.35),
                      CafeTunisienColors.gold.withOpacity(0.08),
                      Colors.transparent,
                    ], stops: const [0.0, 0.5, 1.0]),
                    boxShadow: [
                      BoxShadow(color: CafeTunisienColors.gold.withOpacity(0.2), blurRadius: 30, spreadRadius: 5),
                    ],
                  ),
                  child: const Center(child: Text('🏆', style: TextStyle(fontSize: 56))),
                ),
                const SizedBox(height: 16),
                Text(
                  isOffline ? 'Fin de manche ${engine?.state.round ?? 0}' : 'Fin de manche',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Container(width: 60, height: 2, decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  gradient: LinearGradient(colors: [Colors.transparent, CafeTunisienColors.gold, Colors.transparent]),
                )),
                if (!isOffline && onlineResults != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text('${onlineResults['winnerName']} gagne la manche !',
                      style: const TextStyle(color: CafeTunisienColors.goldLight, fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(height: 24),
                // Player scores
                if (isOffline && engine != null)
                  ...engine.state.players.map((p) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: p.score == 0 ? const Color(0xFF1B5E20).withOpacity(0.3) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.score == 0 ? const Color(0xFF4CAF50).withOpacity(0.4) : Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.score == 0 ? const Color(0xFF4CAF50).withOpacity(0.2) : CafeTunisienColors.gold.withOpacity(0.15),
                        ),
                        child: Center(child: Text('${p.score}', style: TextStyle(
                          color: p.score == 0 ? const Color(0xFF4CAF50) : CafeTunisienColors.goldLight, fontWeight: FontWeight.bold, fontSize: 14))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(p.isBot ? Icons.smart_toy : Icons.person, color: Colors.white54, size: 16),
                          const SizedBox(width: 6),
                          Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        ]),
                        Text('Total: ${p.totalScore} pts', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      ])),
                      if (p.score == 0) const Icon(Icons.star, color: Colors.amber, size: 24),
                    ]),
                  )),
                if (!isOffline && onlineResults != null && onlineResults['results'] != null)
                  ...(onlineResults['results'] as List).map((r) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: r['penalty'] == 0 ? const Color(0xFF1B5E20).withOpacity(0.3) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: r['penalty'] == 0 ? const Color(0xFF4CAF50).withOpacity(0.4) : Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: CafeTunisienColors.gold.withOpacity(0.15)),
                        child: Center(child: Text('${r['penalty']}', style: const TextStyle(color: CafeTunisienColors.goldLight, fontWeight: FontWeight.bold, fontSize: 14))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r['name']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        Text('Cartes restantes: ${r['cardsLeft']}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      ])),
                      if (r['penalty'] == 0) const Icon(Icons.star, color: Colors.amber, size: 24),
                    ]),
                  )),
                if (!isOffline && onlineResults != null && onlineResults['scores'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(children: [
                      const Text('Scores totaux', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      const SizedBox(height: 8),
                      ...(onlineResults['scores'] as List).map((s) => Text(
                        '${s['name']}: ${s['totalScore']} pts',
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                      )),
                    ]),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isOffline) { notifier.offlineNextRound(); }
                      else { GoRouter.of(context).go('/'); }
                    },
                    icon: Icon(isOffline ? Icons.play_arrow : Icons.home, size: 22),
                    label: Text(isOffline ? 'Manche suivante' : 'Retour à l\'accueil', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CafeTunisienColors.gold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 6,
                      shadowColor: CafeTunisienColors.gold.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Game End ────────────────────────────────────────────────

class _GameEndScreen extends StatelessWidget {
  final GameProviderState gameState;
  const _GameEndScreen({required this.gameState});

  @override
  Widget build(BuildContext context) {
    final engine = gameState.offlineEngine;
    String winnerName = '';
    if (engine != null) {
      final w = engine.state.players.firstWhere((p) => p.id == engine.state.winnerId, orElse: () => engine.state.players.first);
      winnerName = w.name;
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0A140B),
      body: SafeArea(
        child: Stack(
          children: [
            // Decorative sparkle particles
            ...List.generate(8, (i) => Positioned(
              left: (i * 47.0 + 20) % MediaQuery.of(context).size.width,
              top: (i * 73.0 + 40) % (MediaQuery.of(context).size.height * 0.6),
              child: Text('✦', style: TextStyle(
                fontSize: 10 + (i % 3) * 4.0,
                color: CafeTunisienColors.gold.withOpacity(0.1 + (i % 4) * 0.05),
              )),
            )),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Celebration with double ring
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          CafeTunisienColors.gold.withOpacity(0.4),
                          CafeTunisienColors.gold.withOpacity(0.1),
                          Colors.transparent,
                        ], stops: const [0.0, 0.5, 1.0]),
                        boxShadow: [
                          BoxShadow(color: CafeTunisienColors.gold.withOpacity(0.25), blurRadius: 50, spreadRadius: 15),
                        ],
                        border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.2), width: 2),
                      ),
                      child: const Center(child: Text('🎉', style: TextStyle(fontSize: 60))),
                    ),
                    const SizedBox(height: 20),
                    const Text('Partie terminée !', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Container(width: 80, height: 2, decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      gradient: LinearGradient(colors: [Colors.transparent, CafeTunisienColors.gold, Colors.transparent]),
                    )),
                    const SizedBox(height: 12),
                    Text('$winnerName gagne ! 🎊', style: const TextStyle(color: CafeTunisienColors.goldLight, fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 24),
                    if (engine != null)
                      ...engine.state.players.map((p) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: p.id == engine.state.winnerId ? CafeTunisienColors.gold.withOpacity(0.12) : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.id == engine.state.winnerId ? CafeTunisienColors.gold.withOpacity(0.4) : Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.id == engine.state.winnerId ? CafeTunisienColors.gold.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                        ),
                        child: Center(child: Text('${p.totalScore}', style: TextStyle(
                          color: p.id == engine.state.winnerId ? CafeTunisienColors.goldLight : Colors.white70,
                          fontWeight: FontWeight.bold, fontSize: 15))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
                      if (p.id == engine.state.winnerId)
                        const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                    ]),
                  )),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home, size: 22),
                    label: const Text('Retour à l\'accueil', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CafeTunisienColors.gold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 6,
                      shadowColor: CafeTunisienColors.gold.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}

// ─── Hot-Seat Handoff ────────────────────────────────────────

class _HotSeatHandoffScreen extends StatelessWidget {
  final String playerName;
  final VoidCallback onReady;
  final VoidCallback onQuit;
  const _HotSeatHandoffScreen({required this.playerName, required this.onReady, required this.onQuit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A140B),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated ring icon
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      CafeTunisienColors.gold.withOpacity(0.15),
                      Colors.transparent,
                    ]),
                    border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.35), width: 2),
                    boxShadow: [
                      BoxShadow(color: CafeTunisienColors.gold.withOpacity(0.15), blurRadius: 20, spreadRadius: 5),
                    ],
                  ),
                  child: const Center(child: Text('🔄', style: TextStyle(fontSize: 46))),
                ),
                const SizedBox(height: 28),
                Text('Passez le téléphone à :', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15)),
                const SizedBox(height: 12),
                // Player name with glow
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.3)),
                    color: CafeTunisienColors.gold.withOpacity(0.08),
                  ),
                  child: Text(playerName, style: const TextStyle(color: CafeTunisienColors.goldLight, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
                const SizedBox(height: 14),
                Container(width: 60, height: 2, decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  gradient: LinearGradient(colors: [Colors.transparent, CafeTunisienColors.gold, Colors.transparent]),
                )),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.red.withOpacity(0.08),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_off, color: Colors.red.withOpacity(0.5), size: 16),
                      const SizedBox(width: 8),
                      Text('Les autres joueurs, ne regardez pas !', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(width: 280, height: 54,
                  child: ElevatedButton.icon(
                    onPressed: onReady,
                    icon: const Icon(Icons.visibility, size: 22),
                    label: const Text('C\'est moi, je suis prêt !', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CafeTunisienColors.gold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: CafeTunisienColors.gold.withOpacity(0.4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onQuit,
                  child: Text('Quitter la partie', style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ─── Frich Vote Screen ─────────────────────────────────────────

class _FrichVoteScreen extends StatelessWidget {
  final GameProviderState gameState;
  final GameNotifier notifier;
  const _FrichVoteScreen({required this.gameState, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final engine = gameState.offlineEngine;
    final votes = engine?.state.frichVotes ?? {};
    final players = engine?.state.players ?? [];
    final humanPlayerMatches = players.where((p) => !p.isBot);
    final humanPlayer = humanPlayerMatches.isNotEmpty ? humanPlayerMatches.first : null;
    final myHand = humanPlayer?.hand ?? [];
    final alreadyVoted = humanPlayer != null && votes.containsKey(humanPlayer.id);

    return Scaffold(
      backgroundColor: const Color(0xFF0D3B13),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  const Color(0xFF3E1F00).withOpacity(0.95),
                  const Color(0xFF5C3317).withOpacity(0.8),
                ]),
                border: Border(bottom: BorderSide(color: CafeTunisienColors.gold.withOpacity(0.5), width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CafeTunisienColors.gold.withOpacity(0.15),
                    ),
                    child: const Center(child: Text('🔄', style: TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Frich ?',
                          style: TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Manche ${engine?.state.round ?? 1} — Regardez vos cartes avant de décider',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Vote results (shown after human voted)
            if (alreadyVoted) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4A017).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text('Résultats des votes', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 8),
                    ...players.map((p) {
                      final voted = votes.containsKey(p.id);
                      final accepted = votes[p.id] ?? false;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(p.isBot ? Icons.smart_toy : Icons.person, color: Colors.white54, size: 16),
                            const SizedBox(width: 6),
                            Text(p.name, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(width: 8),
                            if (voted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: accepted ? const Color(0xFF4CAF50).withOpacity(0.3) : Colors.red.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  accepted ? '✓ Oui' : '✗ Non',
                                  style: TextStyle(color: accepted ? const Color(0xFF4CAF50) : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              )
                            else
                              const Text('⏳', style: TextStyle(color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text('En attente des résultats...', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],

            // Question + buttons (before voting)
            if (!alreadyVoted) ...[
              const Spacer(),
              Text(
                'Voulez-vous remélanger ?',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 17, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Si tous acceptent → nouvelles cartes',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Oui, Frich !'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 6,
                      shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
                    ),
                    onPressed: () => notifier.offlineVoteFrich(true),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Non, on joue !'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CafeTunisienColors.goldLight,
                      side: BorderSide(color: CafeTunisienColors.gold.withOpacity(0.6), width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => notifier.offlineVoteFrich(false),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            if (alreadyVoted) const Spacer(),

            // Show the player's hand at the bottom
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF5C3317).withOpacity(0.5),
                border: Border(top: BorderSide(color: const Color(0xFFD4A017).withOpacity(0.3))),
              ),
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Column(
                children: [
                  Text(
                    '${humanPlayer?.name ?? "Vous"} — ${myHand.length} cartes',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 90,
                    child: myHand.isEmpty
                        ? const Center(child: Text('Aucune carte', style: TextStyle(color: Colors.white38)))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: myHand.length,
                            itemBuilder: (_, i) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: PlayingCard(
                                  card: myHand[i],
                                  width: 48,
                                  height: 70,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ___ Audio Option Tile ___
class _AudioOptionTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isLive;
  final VoidCallback onTap;
  const _AudioOptionTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    this.isLive = false,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD700).withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD700).withOpacity(0.5)
                : Colors.white.withOpacity(0.06),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.08), blurRadius: 8)]
              : null,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (isLive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 0.5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.redAccent, size: 6),
                              SizedBox(width: 3),
                              Text('LIVE', style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                ),
                child: const Icon(Icons.check_rounded, color: Color(0xFFFFD700), size: 16),
              )
            else
              Icon(Icons.play_circle_outline_rounded, color: Colors.white.withOpacity(0.15), size: 22),
          ],
        ),
      ),
    );
  }
}
