
import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import '../models/card.dart' as models;
import '../engine/game_engine.dart';
import '../services/socket_service.dart';
import 'auth_provider.dart';

// ─── Game Mode ───────────────────────────────────────────────

enum GameMode { offline, online }

// ─── Staged Meld (pre-opening temp paquet) ───────────────────

class StagedMeld {
  final String id;
  final List<models.Card> cards;
  final List<int> cardIds;
  final String type; // 'run' or 'set'
  final int points;
  final bool hasJoker;

  const StagedMeld({
    required this.id,
    required this.cards,
    required this.cardIds,
    required this.type,
    required this.points,
    required this.hasJoker,
  });
}

// ─── Game Provider State ─────────────────────────────────────

class GameProviderState {
  final GameMode mode;
  final GameState? onlineState;
  final OfflineGameEngine? offlineEngine;
  final String? myPlayerId;
  final List<int> selectedCardIds;
  final List<StagedMeld> stagedMelds; // Pre-opening temp paquets
  final String? error;
  final int offlineCurrentPlayerIdx;
  final List<int> onlineHandOrder; // Client-side card arrangement for online
  final Map<String, dynamic>? onlineRoundResults; // Results from server round_end event
  final int _version;

  const GameProviderState({
    this.mode = GameMode.offline,
    this.onlineState,
    this.offlineEngine,
    this.myPlayerId,
    this.selectedCardIds = const [],
    this.stagedMelds = const [],
    this.error,
    this.offlineCurrentPlayerIdx = 0,
    this.onlineHandOrder = const [],
    this.onlineRoundResults,
    int version = 0,
  }) : _version = version;

  bool get isMyTurn {
    if (mode == GameMode.online && onlineState != null) {
      return onlineState!.currentPlayer?.id == myPlayerId;
    }
    if (mode == GameMode.offline && offlineEngine != null) {
      return !offlineEngine!.state.currentPlayer.isBot;
    }
    return false;
  }

  String get phase {
    if (mode == GameMode.online) return onlineState?.phase ?? 'waiting';
    if (offlineEngine != null) return offlineEngine!.state.phase.name;
    return 'waiting';
  }

  String get turnStep {
    if (mode == GameMode.online) return onlineState?.turnStep ?? 'draw';
    if (offlineEngine != null) return offlineEngine!.state.turnStep.name;
    return 'draw';
  }

  GameProviderState copyWith({
    GameMode? mode,
    GameState? onlineState,
    OfflineGameEngine? offlineEngine,
    String? myPlayerId,
    List<int>? selectedCardIds,
    List<StagedMeld>? stagedMelds,
    String? error,
    int? offlineCurrentPlayerIdx,
    List<int>? onlineHandOrder,
    Map<String, dynamic>? onlineRoundResults,
  }) => GameProviderState(
    mode: mode ?? this.mode,
    onlineState: onlineState ?? this.onlineState,
    offlineEngine: offlineEngine ?? this.offlineEngine,
    myPlayerId: myPlayerId ?? this.myPlayerId,
    selectedCardIds: selectedCardIds ?? this.selectedCardIds,
    stagedMelds: stagedMelds ?? this.stagedMelds,
    error: error,
    offlineCurrentPlayerIdx: offlineCurrentPlayerIdx ?? this.offlineCurrentPlayerIdx,
    onlineHandOrder: onlineHandOrder ?? this.onlineHandOrder,
    onlineRoundResults: onlineRoundResults ?? this.onlineRoundResults,
    version: _version + 1,
  );
}

// ─── Game Notifier ───────────────────────────────────────────

class GameNotifier extends StateNotifier<GameProviderState> {
  final SocketService _socket;
  final Ref _ref;
  StreamSubscription? _stateSub;
  StreamSubscription? _errorSub;
  Timer? _turnTimer;

  GameNotifier(this._socket, this._ref) : super(const GameProviderState());

  // ─── Offline Mode ──────────────────────────────────────

  void startOfflineGame({
    required List<({String id, String name, bool isBot})> players,
    GameConfig config = const GameConfig(),
  }) {
    _turnTimer?.cancel();
    final engine = OfflineGameEngine(playerInfos: players, config: config);
    engine.startRound();

    state = GameProviderState(
      mode: GameMode.offline,
      offlineEngine: engine,
      myPlayerId: players.first.id,
    );

    // Auto-vote frich for bots (they always accept)
    // Don't auto-vote bots yet — wait for human to see cards and decide
  }

  /// Feature 5: Frich vote — human player votes, then bots vote randomly
  void offlineVoteFrich(bool wantFrich) {
    final engine = state.offlineEngine;
    if (engine == null) return;

    // Find first human player who hasn't voted
    for (final p in engine.state.players) {
      if (!p.isBot && !engine.state.frichVotes.containsKey(p.id)) {
        engine.voteFrich(p.id, wantFrich);
        break;
      }
    }

    // Check if more human players need to vote
    final humansPending = engine.state.players.where(
      (p) => !p.isBot && !engine.state.frichVotes.containsKey(p.id)
    ).isNotEmpty;

    if (humansPending) {
      _notifyOffline();
      return; // Wait for next human vote
    }

    // All humans voted — now bots vote (50% chance each)
    _autoBotFrichVote();

    _notifyOffline();

    // If frich happened (reshuffle) → still in frichVote phase with new cards
    if (engine.state.phase == LocalGamePhase.frichVote) return;

    // Game started — start turn timer
    _startTurnTimer();
    _processBotTurns();
  }

  /// Skip frich entirely
  void skipFrichPhase() {
    final engine = state.offlineEngine;
    if (engine == null) return;
    engine.skipFrich();
    _notifyOffline();
    _startTurnTimer();
    _processBotTurns();
  }

  void _autoBotFrichVote() {
    final engine = state.offlineEngine;
    if (engine == null || engine.state.phase != LocalGamePhase.frichVote) return;
    final rng = Random();
    for (final p in engine.state.players) {
      if (p.isBot && !engine.state.frichVotes.containsKey(p.id)) {
        engine.voteFrich(p.id, rng.nextBool()); // 50% chance
      }
    }
  }

  /// Feature 1: Turn timer — auto-play after timeout
  void _startTurnTimer() {
    _turnTimer?.cancel();
    final engine = state.offlineEngine;
    if (engine == null) return;
    if (engine.state.phase != LocalGamePhase.playerTurn) return;
    if (engine.state.currentPlayer.isBot) return; // Bots play by themselves

    final timeout = engine.state.config.turnTimeoutSeconds;
    _turnTimer = Timer(Duration(seconds: timeout), () {
      _autoPlayTimeout();
    });
  }

  void _cancelTurnTimer() {
    _turnTimer?.cancel();
    _turnTimer = null;
  }

  void _autoPlayTimeout() {
    final engine = state.offlineEngine;
    if (engine == null) return;
    if (engine.state.phase != LocalGamePhase.playerTurn) return;
    if (engine.state.currentPlayer.isBot) return;

    try {
      engine.autoPlayTurn();
      state = state.copyWith(stagedMelds: [], selectedCardIds: []);
      _notifyOffline();
      _processBotTurns();
    } catch (e) {
      state = state.copyWith(error: 'Auto-play: $e');
    }
  }

  void offlineDrawFromDeck() {
    try {
      _cancelTurnTimer();
      state.offlineEngine!.drawFromDeck();
      _notifyOffline();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void offlineDrawFromDiscard() {
    try {
      _cancelTurnTimer();
      state.offlineEngine!.drawFromDiscard();
      _notifyOffline();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Stage a paquet temporarily (for opening flow).
  /// Cards are visually removed from hand but not committed to engine yet.
  void stageMeld(List<int> cardIds, List<models.Card> cards, String type, int points, bool hasJoker) {
    final staged = StagedMeld(
      id: 'staged_${DateTime.now().millisecondsSinceEpoch}',
      cards: cards,
      cardIds: cardIds,
      type: type,
      points: points,
      hasJoker: hasJoker,
    );
    state = state.copyWith(
      stagedMelds: [...state.stagedMelds, staged],
      selectedCardIds: [],
    );
  }

  /// Remove a staged paquet (put cards back in hand).
  void unstageMeld(String stagedId) {
    state = state.copyWith(
      stagedMelds: state.stagedMelds.where((m) => m.id != stagedId).toList(),
    );
  }

  /// Clear all staged melds.
  void clearStaged() {
    state = state.copyWith(stagedMelds: []);
  }

  /// Confirm opening: send all staged melds to the engine at once.
  void confirmOpening() {
    if (state.mode == GameMode.online) {
      for (final staged in state.stagedMelds) {
        _socket.emit('game_action', {
          'action': {'type': 'meld', 'cardIds': staged.cardIds}
        });
      }
      _socket.emit('game_action', {
        'action': {'type': 'confirm_opening'}
      });
      state = state.copyWith(stagedMelds: [], selectedCardIds: []);
      return;
    }
    try {
      // Deduplicate: remove any staged melds that use the same card IDs
      final seenCardIds = <int>{};
      final uniqueStagedMelds = <StagedMeld>[];
      for (final m in state.stagedMelds) {
        if (m.cardIds.any((id) => seenCardIds.contains(id))) continue; // Skip duplicates
        seenCardIds.addAll(m.cardIds);
        uniqueStagedMelds.add(m);
      }

      final allMeldCardIds = uniqueStagedMelds.map((m) => m.cardIds).toList();
      state.offlineEngine!.meldBatch(allMeldCardIds);
      state = state.copyWith(stagedMelds: [], selectedCardIds: []);
      _notifyOffline();
    } catch (e) {
      // On error: keep staged melds so user can adjust, but show error
      state = state.copyWith(error: e.toString(), selectedCardIds: []);
    }
  }

  /// Post-opening: place a single meld directly.
  void offlineMeld() {
    try {
      state.offlineEngine!.meld(state.selectedCardIds);
      state = state.copyWith(selectedCardIds: []);
      _notifyOffline();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void offlineLayoff(int cardId, String meldId, String position) {
    try {
      state.offlineEngine!.layoff(cardId, meldId, position);
      _notifyOffline();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Drag & drop layoff: auto-detects position + joker swap
  /// Returns a message about joker recovery if applicable.
  String? offlineLayoffDrag(int cardId, String meldId) {
    try {
      final joker = state.offlineEngine!.layoffWithJokerSwap(cardId, meldId);
      state = state.copyWith(selectedCardIds: []);
      _notifyOffline();
      if (joker != null) {
        return '🃏 Joker récupéré !';
      }
      return null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  void offlineDiscard(int cardId) {
    try {
      _cancelTurnTimer();
      state.offlineEngine!.discard(cardId);
      state = state.copyWith(stagedMelds: [], selectedCardIds: []);
      _notifyOffline();
      _processBotTurns();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void offlineNextRound() {
    _cancelTurnTimer();
    state.offlineEngine!.startRound();
    _notifyOffline();
    // Don't auto-vote bots — frich screen will show cards first, then ask
  }

  Future<void> _processBotTurns() async {
    final engine = state.offlineEngine;
    if (engine == null) return;

    while (engine.state.phase == LocalGamePhase.playerTurn &&
           engine.state.currentPlayer.isBot) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (engine.state.phase != LocalGamePhase.playerTurn) break;
      if (!engine.state.currentPlayer.isBot) break;

      try {
        // Step 1: Draw
        final drawResult = engine.executeBotDraw();
        if (drawResult) {
          _notifyOffline();
          await Future.delayed(const Duration(milliseconds: 500));
        }

        if (engine.state.phase != LocalGamePhase.playerTurn) break;
        if (!engine.state.currentPlayer.isBot) break;

        // Step 2: Try opening or melds — one at a time with delay
        bool didMeld = true;
        while (didMeld) {
          didMeld = engine.executeBotSingleMeld();
          if (didMeld) {
            _notifyOffline();
            await Future.delayed(const Duration(milliseconds: 800));
          }
          if (engine.state.phase != LocalGamePhase.playerTurn) break;
        }
        if (engine.state.phase != LocalGamePhase.playerTurn) break;

        // Step 3: Try layoffs — one at a time with delay
        bool didLayoff = true;
        while (didLayoff) {
          didLayoff = engine.executeBotSingleLayoff();
          if (didLayoff) {
            _notifyOffline();
            await Future.delayed(const Duration(milliseconds: 600));
          }
          if (engine.state.phase != LocalGamePhase.playerTurn) break;
        }
        if (engine.state.phase != LocalGamePhase.playerTurn) break;

        // Step 3b: Try joker recovery
        bool didRecover = true;
        while (didRecover) {
          didRecover = engine.executeBotJokerRecovery();
          if (didRecover) {
            _notifyOffline();
            await Future.delayed(const Duration(milliseconds: 600));
          }
          if (engine.state.phase != LocalGamePhase.playerTurn) break;
        }
        if (engine.state.phase != LocalGamePhase.playerTurn) break;

        // Step 4: Discard
        if (engine.state.currentPlayer.isBot &&
            engine.state.currentPlayer.hand.isNotEmpty) {
          engine.executeBotDiscard();
          _notifyOffline();
        }
      } catch (e) {
        state = state.copyWith(error: 'Bot error: $e');
        break;
      }
    }

    // After bots finish, start timer for human player
    if (engine.state.phase == LocalGamePhase.playerTurn &&
        !engine.state.currentPlayer.isBot) {
      _startTurnTimer();
    }
  }

  // ─── Card Selection ────────────────────────────────────

  void toggleCardSelection(int cardId) {
    final selected = List<int>.from(state.selectedCardIds);
    if (selected.contains(cardId)) {
      selected.remove(cardId);
    } else {
      selected.add(cardId);
    }
    state = state.copyWith(selectedCardIds: selected);
  }

  void clearSelection() {
    state = state.copyWith(selectedCardIds: []);
  }

  /// Reorder a card in the player's hand (drag & drop).
  /// [oldIndex] = current index in visible hand, [newIndex] = desired final index in visible hand.
  void reorderCard(int oldIndex, int newIndex) {
    if (state.mode == GameMode.online) {
      final order = [...state.onlineHandOrder];
      final stagedIds = state.stagedMelds.expand((m) => m.cardIds).toSet();
      final visibleOrder = order.where((id) => !stagedIds.contains(id)).toList();
      if (oldIndex < 0 || oldIndex >= visibleOrder.length) return;
      if (newIndex < 0 || newIndex >= visibleOrder.length) return;
      if (oldIndex == newIndex) return;

      final cardId = visibleOrder.removeAt(oldIndex);
      visibleOrder.insert(newIndex, cardId);

      // Rebuild full order: staged cards stay in place, visible cards in new order
      final newOrder = <int>[];
      int vi = 0;
      for (final id in order) {
        if (stagedIds.contains(id)) {
          newOrder.add(id);
        } else {
          if (vi < visibleOrder.length) newOrder.add(visibleOrder[vi++]);
        }
      }
      // Add any remaining
      while (vi < visibleOrder.length) { newOrder.add(visibleOrder[vi++]); }

      state = state.copyWith(onlineHandOrder: newOrder);
      return;
    }

    final engine = state.offlineEngine;
    if (engine == null) return;
    final hand = engine.state.currentPlayer.hand;

    final stagedIds = state.stagedMelds.expand((m) => m.cardIds).toSet();
    final visibleCards = hand.where((c) => !stagedIds.contains(c.id)).toList();
    if (oldIndex < 0 || oldIndex >= visibleCards.length) return;
    if (newIndex < 0 || newIndex >= visibleCards.length) return;
    if (oldIndex == newIndex) return;

    // Reorder in visible list
    final card = visibleCards.removeAt(oldIndex);
    visibleCards.insert(newIndex, card);

    // Rebuild engine hand: staged cards stay in their slots, visible cards in new order
    final newHand = <models.Card>[];
    int vi = 0;
    for (final c in hand) {
      if (stagedIds.contains(c.id)) {
        newHand.add(c);
      } else {
        if (vi < visibleCards.length) newHand.add(visibleCards[vi++]);
      }
    }
    while (vi < visibleCards.length) { newHand.add(visibleCards[vi++]); }

    hand.clear();
    hand.addAll(newHand);
    _notifyOffline();
  }

  /// Reorder a group of selected cards, moving them all to [targetIndex] in the visible hand.
  void reorderGroup(List<int> cardIds, int targetIndex) {
    final engine = state.offlineEngine;
    if (engine == null) return;
    final hand = engine.state.currentPlayer.hand;
    final stagedIds = state.stagedMelds.expand((m) => m.cardIds).toSet();
    final visibleCards = hand.where((c) => !stagedIds.contains(c.id)).toList();

    final groupIdSet = cardIds.toSet();
    // Extract group cards in their current order
    final groupCards = visibleCards.where((c) => groupIdSet.contains(c.id)).toList();
    // Remove group cards from visible
    final remaining = visibleCards.where((c) => !groupIdSet.contains(c.id)).toList();
    // Insert group at target
    final clamped = targetIndex.clamp(0, remaining.length);
    remaining.insertAll(clamped, groupCards);

    // Rebuild engine hand
    final newHand = <models.Card>[];
    int vi = 0;
    for (final c in hand) {
      if (stagedIds.contains(c.id)) {
        newHand.add(c);
      } else {
        if (vi < remaining.length) newHand.add(remaining[vi++]);
      }
    }
    while (vi < remaining.length) { newHand.add(remaining[vi++]); }

    hand.clear();
    hand.addAll(newHand);
    clearSelection();
    _notifyOffline();
  }

  // ─── Online Mode ───────────────────────────────────────

  /// Connect to the server with a display name (no JWT required).
  void connectOnline({String? displayName}) {
    final auth = _ref.read(authProvider);
    final name = displayName ?? auth.displayName ?? 'Joueur';
    final id = auth.userId ?? 'p_${DateTime.now().millisecondsSinceEpoch}';

    _socket.connect(name, playerId: id);

    _stateSub?.cancel();
    _stateSub = _socket.on('game_state_update').listen((data) {
      try {
        final gameState = GameState.fromJson(data['state']);

        // Merge hand order: keep user's arrangement, add new cards, remove gone cards
        final serverHandIds = gameState.myHand.map((c) => c.id).toSet();
        final currentOrder = state.onlineHandOrder;
        // Keep existing cards that are still in hand, in user's order
        final keptOrder = currentOrder.where((id) => serverHandIds.contains(id)).toList();
        // Add new cards (not in existing order) at the end
        final newCards = serverHandIds.where((id) => !keptOrder.contains(id)).toList();
        final mergedOrder = [...keptOrder, ...newCards];

        state = state.copyWith(
          mode: GameMode.online,
          onlineState: gameState,
          myPlayerId: _socket.playerId ?? id,
          onlineHandOrder: mergedOrder,
          error: null,
        );
      } catch (e) {
        print('❌ Error parsing game state: $e');
        state = state.copyWith(error: 'Erreur de synchronisation');
      }
    });

    _errorSub?.cancel();
    _errorSub = _socket.on('game_error').listen((data) {
      state = state.copyWith(error: data['message']?.toString() ?? 'Erreur serveur');
    });

    // Listen for round_end to store results
    _socket.on('round_end').listen((data) {
      state = state.copyWith(
        onlineRoundResults: data,
      );
    });

    // Listen for forfeit (opponent disconnected)
    _socket.on('game_over_forfeit').listen((data) {
      state = state.copyWith(
        error: '🏆 ${data['winnerName'] ?? 'Joueur'} gagne ! ${data['reason'] ?? 'L\'adversaire a quitté.'}',
      );
    });
  }

  void createRoom({int numPlayers = 2}) {
    _socket.emit('create_room', {'numPlayers': numPlayers});
  }

  void joinRoom(String code) {
    _socket.emit('join_room', {'roomCode': code});
  }

  void setReady() {
    _socket.emit('ready');
  }

  void startOnlineGame() {
    _socket.emit('start_game');
  }

  void onlineAction(Map<String, dynamic> action) {
    _socket.emit('game_action', {'action': action});
  }

  void sendChat(String message) {
    _socket.emit('chat_message', {'message': message});
  }

  void joinMatchmaking(int preferredPlayers) {
    _socket.emit('join_matchmaking', {'preferredPlayers': preferredPlayers});
  }

  void resign() {
    _socket.emit('resign');
  }

  void disconnectOnline() {
    _stateSub?.cancel();
    _errorSub?.cancel();
    _socket.disconnect();
  }

  void _notifyOffline() {
    // Trigger rebuild by creating new state reference
    state = state.copyWith(
      offlineCurrentPlayerIdx: state.offlineEngine?.state.currentPlayerIndex ?? 0,
    );
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _stateSub?.cancel();
    _errorSub?.cancel();
    super.dispose();
  }
}

// ─── Providers ───────────────────────────────────────────────

final socketServiceProvider = Provider<SocketService>((ref) => SocketService());

final gameProvider = StateNotifierProvider<GameNotifier, GameProviderState>((ref) {
  final socket = ref.watch(socketServiceProvider);
  return GameNotifier(socket, ref);
});




















