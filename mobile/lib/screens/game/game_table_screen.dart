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
import 'widgets/playing_card.dart';
import 'widgets/player_hand.dart';
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
      // App coming back — resume music
      if (_musicPlaying) MusicService.instance.resume();
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
      final myInfo = onlineState.players.where((p) => p.id == gs.myPlayerId).firstOrNull;
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

    // Haptic feedback when it becomes my turn
    if (isMyTurn && !_wasMyTurn) {
      HapticFeedback.mediumImpact();
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

    return Scaffold(
      backgroundColor: const Color(0xFF0D3B13),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar + Players in one header
            _CombinedHeader(
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
                if (_musicPlaying) {
                  MusicService.instance.play();
                } else {
                  MusicService.instance.stop();
                }
              },
              turnTimeoutSeconds: config.turnTimeoutSeconds,
              gameState: gs,
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
                    ? visibleHand.where((c) => c.id == gs.selectedCardIds.first).firstOrNull
                    : null,
                onDrawDeck: isMyTurn && turnStep == 'draw'
                    ? () { HapticFeedback.lightImpact(); isOffline ? notifier.offlineDrawFromDeck() : notifier.onlineAction({'type': 'draw_deck'}); }
                    : null,
                onDrawDiscard: isMyTurn && turnStep == 'draw' && topDiscard != null
                    && !(isOffline && engine != null && engine.isDiscardDuplicate())
                    ? () { HapticFeedback.lightImpact(); _confirmDrawFromDiscard(context, notifier, isOffline, hasOpened, config); }
                    : null,
                // Tap on a meld to lay off selected card
                onTapMeld: isMyTurn && turnStep == 'play' && hasOpened && gs.selectedCardIds.length == 1
                    ? (meldId) {
                        final cardId = gs.selectedCardIds.first;
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
                        HapticFeedback.mediumImpact();
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
                color: const Color(0xFFC0392B).withOpacity(0.9),
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                child: Row(
                  children: [
                    Expanded(child: Text(gs.error!, style: const TextStyle(color: Colors.white, fontSize: 12))),
                    GestureDetector(
                      onTap: () => notifier.clearSelection(),
                      child: const Icon(Icons.close, color: Colors.white54, size: 16),
                    ),
                  ],
                ),
              ),

            // Warning: drew from discard, must open or 100pts penalty
            if (drewFromDiscard && !hasOpened && isMyTurn && turnStep == 'play')
              Container(
                width: double.infinity,
                color: const Color(0xFFE65100).withOpacity(0.95),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '⚠️ Vous avez pioché du talon ! Vous devez ouvrir ou recevoir 100 pts de pénalité.',
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
                  notifier.stageMeld(
                    gs.selectedCardIds,
                    selectedCards,
                    meldType!.name,
                    meldPoints,
                    selectedCards.any((c) => c.isJoker),
                  );
                } : null,
                onConfirmOpen: canConfirmOpening ? () => notifier.confirmOpening() : null,
                onDirectMeld: hasOpened && meldIsValid ? () {
                  if (isOffline) {
                    notifier.offlineMeld();
                  } else {
                    notifier.onlineAction({'type': 'meld', 'cardIds': gs.selectedCardIds});
                    notifier.clearSelection();
                  }
                } : null,
                onDiscard: gs.selectedCardIds.length == 1 && gs.stagedMelds.isEmpty ? () {
                  HapticFeedback.mediumImpact();
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

            // Hand (only show cards NOT in staged melds)
            PlayerHandWidget(
              cards: visibleHand,
              selectedIds: gs.selectedCardIds.toSet(),
              validHighlightIds: validHighlightIds,
              onTapCard: (id) => notifier.toggleCardSelection(id),
              onReorder: (from, to) => notifier.reorderCard(from, to),
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
        title: const Text('Quitter la partie ?'),
        content: const Text('Ta progression sera perdue.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Rester')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); ref.read(gameProvider.notifier).disconnectOnline(); GoRouter.of(ctx).go('/'); },
            child: const Text('Quitter', style: TextStyle(color: Colors.red)),
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

  void _showScoreBoard(BuildContext ctx, GameProviderState gs) {
    showModalBottomSheet(context: ctx, builder: (_) => ScoreBoardWidget(gameState: gs));
  }
}

// ─── Top Bar ─────────────────────────────────────────────────

class _CombinedHeader extends StatelessWidget {
  final String playerName;
  final bool isMyTurn;
  final String turnStep;
  final int round;
  final int maxRounds;
  final VoidCallback onBack;
  final VoidCallback onScore;
  final bool musicPlaying;
  final VoidCallback onToggleMusic;
  final int turnTimeoutSeconds;
  final GameProviderState gameState;

  const _CombinedHeader({
    required this.playerName, required this.isMyTurn, required this.turnStep,
    required this.round, required this.maxRounds, required this.onBack, required this.onScore,
    required this.musicPlaying, required this.onToggleMusic,
    this.turnTimeoutSeconds = 60,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = isMyTurn
        ? (turnStep == 'draw' ? '☝ Piochez !' : '🃏 Jouez !')
        : '⏳ Tour de $playerName...';
    final statusColor = isMyTurn ? const Color(0xFF4CAF50) : const Color(0xFFE8A317);

    // Build player items
    final items = <_PInfo>[];
    final isOffline = gameState.mode == GameMode.offline;
    if (isOffline && gameState.offlineEngine != null) {
      final st = gameState.offlineEngine!.state;
      for (int i = 0; i < st.players.length; i++) {
        final p = st.players[i];
        items.add(_PInfo(p.name, p.hand.length, i == st.currentPlayerIndex, p.totalScore, p.isBot,
            hasOpened: p.hasOpened, openingScore: p.openingScore));
      }
    } else if (gameState.onlineState != null) {
      for (int i = 0; i < gameState.onlineState!.players.length; i++) {
        final p = gameState.onlineState!.players[i];
        items.add(_PInfo(p.name, p.handCount, i == gameState.onlineState!.currentPlayerIndex, p.totalScore, p.isBot,
            hasOpened: p.hasOpened, openingScore: p.openingScore));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF5C3317).withOpacity(0.95),
        border: const Border(bottom: BorderSide(color: Color(0xFFD4A017), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Turn status + controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: const Icon(Icons.arrow_back, color: Color(0xFFFFD700), size: 18),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withOpacity(0.5), width: 1),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _TurnTimer(isMyTurn: isMyTurn, seconds: turnTimeoutSeconds),
                if (round > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                    child: Text('$round/$maxRounds', style: const TextStyle(color: Colors.white60, fontSize: 9)),
                  ),
                ],
                GestureDetector(
                  onTap: onToggleMusic,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(musicPlaying ? Icons.music_note : Icons.music_off, color: const Color(0xFFFFD700), size: 18),
                  ),
                ),
                GestureDetector(
                  onTap: onScore,
                  child: const Icon(Icons.scoreboard, color: Color(0xFFFFD700), size: 18),
                ),
              ],
            ),
          ),
          // Row 2: Player chips (compact)
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (_, i) => _PlayerChip(info: items[i]),
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

/// Animated countdown timer that resets each turn
class _TurnTimer extends StatefulWidget {
  final bool isMyTurn;
  final int seconds;
  const _TurnTimer({required this.isMyTurn, required this.seconds});

  @override
  State<_TurnTimer> createState() => _TurnTimerState();
}

class _TurnTimerState extends State<_TurnTimer> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _TurnTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset timer when turn changes
    if (oldWidget.isMyTurn != widget.isMyTurn) {
      _remaining = widget.seconds;
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
    final color = isLow ? Colors.redAccent : Colors.white60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isLow ? Colors.red.withOpacity(0.2) : Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: isLow ? Border.all(color: Colors.redAccent.withOpacity(0.5)) : null,
      ),
      child: Text(
        '⏱ ${_remaining}s',
        style: TextStyle(color: color, fontSize: 11, fontWeight: isLow ? FontWeight.bold : FontWeight.normal),
      ),
    );
  }
}

// ─── Player Chip (reused in CombinedHeader) ──────────────────

class _PlayerChip extends StatefulWidget {
  final _PInfo info;
  const _PlayerChip({required this.info});

  @override
  State<_PlayerChip> createState() => _PlayerChipState();
}

class _PlayerChipState extends State<_PlayerChip> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _pulse = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    if (widget.info.active) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PlayerChip old) {
    super.didUpdateWidget(old);
    if (widget.info.active && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.info.active && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.info;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: p.active
                ? Color.lerp(const Color(0xFFD4A017), const Color(0xFFFFD700), _pulse.value)
                : Colors.white10,
            borderRadius: BorderRadius.circular(20),
            border: p.active
                ? Border.all(color: const Color(0xFFFFD700), width: 2)
                : Border.all(color: Colors.white10, width: 0.5),
            boxShadow: p.active
                ? [BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(_pulse.value * 0.5),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Turn arrow indicator
              if (p.active)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Text('▶', style: TextStyle(fontSize: 10, color: Colors.white)),
                ),
              // Icon
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.active ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.08),
                ),
                child: Icon(
                  p.isBot ? Icons.smart_toy : Icons.person,
                  size: 14,
                  color: p.active ? Colors.white : Colors.white54,
                ),
              ),
              const SizedBox(width: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: TextStyle(
                      color: p.active ? Colors.white : Colors.white70,
                      fontWeight: p.active ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${p.handCount}🃏',
                        style: TextStyle(
                          color: p.active ? Colors.white70 : Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${p.score}pts',
                        style: TextStyle(
                          color: p.active ? Colors.white70 : Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (p.hasOpened) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '✓${p.openingScore}',
                            style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

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
      backgroundColor: CafeTunisienColors.tableGreen,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 16),
                Text(
                  isOffline
                      ? 'Fin de manche ${engine?.state.round ?? 0}'
                      : 'Fin de manche',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (!isOffline && onlineResults != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${onlineResults['winnerName']} gagne la manche !',
                      style: const TextStyle(color: CafeTunisienColors.goldLight, fontSize: 18),
                    ),
                  ),
                const SizedBox(height: 24),
                if (isOffline && engine != null)
                  ...engine.state.players.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Card(child: ListTile(
                      leading: CircleAvatar(backgroundColor: p.score == 0 ? Colors.green : Colors.orange, child: Text('${p.score}')),
                      title: Text(p.name), subtitle: Text('Total: ${p.totalScore} pts'),
                      trailing: p.score == 0 ? const Icon(Icons.star, color: Colors.amber) : null,
                    )),
                  )),
                if (!isOffline && onlineResults != null && onlineResults['results'] != null)
                  ...(onlineResults['results'] as List).map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Card(child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: r['penalty'] == 0 ? Colors.green : Colors.orange,
                        child: Text('${r['penalty']}'),
                      ),
                      title: Text(r['name']?.toString() ?? ''),
                      subtitle: Text('Cartes restantes: ${r['cardsLeft']}'),
                      trailing: r['penalty'] == 0 ? const Icon(Icons.star, color: Colors.amber) : null,
                    )),
                  )),
                if (!isOffline && onlineResults != null && onlineResults['scores'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        const Text('Scores totaux', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        ...(onlineResults['scores'] as List).map((s) => Text(
                          '${s['name']}: ${s['totalScore']} pts',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        )),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    if (isOffline) {
                      notifier.offlineNextRound();
                    } else {
                      GoRouter.of(context).go('/');
                    }
                  },
                  icon: Icon(isOffline ? Icons.play_arrow : Icons.home),
                  label: Text(isOffline ? 'Manche suivante' : 'Retour à l\'accueil'),
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
      backgroundColor: CafeTunisienColors.tableGreen,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 16),
                const Text('Partie terminée !', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('$winnerName gagne !', style: const TextStyle(color: CafeTunisienColors.goldLight, fontSize: 22)),
                const SizedBox(height: 24),
                if (engine != null)
                  ...engine.state.players.map((p) => Card(child: ListTile(
                    leading: CircleAvatar(child: Text('${p.totalScore}')),
                    title: Text(p.name),
                    trailing: p.id == engine.state.winnerId ? const Icon(Icons.emoji_events, color: Colors.amber, size: 30) : null,
                  ))),
                const SizedBox(height: 32),
                ElevatedButton.icon(onPressed: () => context.go('/'), icon: const Icon(Icons.home), label: const Text('Retour à l\'accueil')),
              ],
            ),
          ),
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
      backgroundColor: CafeTunisienColors.tableGreen,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔄', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 24),
                const Text('Passez le téléphone à :', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 12),
                Text(playerName, style: const TextStyle(color: CafeTunisienColors.goldLight, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                const Text('Les autres joueurs, ne regardez pas !', style: TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 40),
                SizedBox(width: 240, height: 56,
                  child: ElevatedButton.icon(
                    onPressed: onReady, icon: const Icon(Icons.visibility, size: 24),
                    label: const Text('C\'est moi, je suis prêt !', style: TextStyle(fontSize: 15)),
                    style: ElevatedButton.styleFrom(backgroundColor: CafeTunisienColors.gold, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: onQuit, child: const Text('Quitter la partie', style: TextStyle(color: Colors.white38))),
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
    final humanPlayer = players.where((p) => !p.isBot).firstOrNull;
    final myHand = humanPlayer?.hand ?? [];
    final alreadyVoted = humanPlayer != null && votes.containsKey(humanPlayer.id);

    return Scaffold(
      backgroundColor: const Color(0xFF0D3B13),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF5C3317).withOpacity(0.95),
                border: const Border(bottom: BorderSide(color: Color(0xFFD4A017), width: 1)),
              ),
              child: Row(
                children: [
                  const Text('🔄', style: TextStyle(fontSize: 24)),
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
                    ),
                    onPressed: () => notifier.offlineVoteFrich(true),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Non, on joue !'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFD700),
                      side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
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
