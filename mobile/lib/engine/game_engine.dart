import 'dart:math';
import '../models/card.dart';
import '../models/meld.dart';
import '../models/game_config.dart';
import 'deck.dart';
import 'meld_validator.dart';

// ─── Local Player (offline mode, full data) ──────────────────

class LocalPlayer {
  final String id;
  final String name;
  List<Card> hand;
  List<Meld> melds;
  int score;
  int totalScore;
  bool hasOpened;
  int openingScore;
  bool isBot;
  /// True if the player drew from the discard pile this turn.
  /// If they can't open/meld by end of turn, they get 100 pts penalty.
  bool drewFromDiscard;

  LocalPlayer({
    required this.id,
    required this.name,
    List<Card>? hand,
    List<Meld>? melds,
    this.score = 0,
    this.totalScore = 0,
    this.hasOpened = false,
    this.openingScore = 0,
    this.isBot = false,
    this.drewFromDiscard = false,
  })  : hand = hand ?? [],
        melds = melds ?? [];
}

// ─── Local Game State ────────────────────────────────────────

enum LocalGamePhase { waiting, frichVote, playerTurn, roundEnd, gameEnd }
enum LocalTurnStep { draw, play }

class LocalGameState {
  final String id;
  final GameConfig config;
  LocalGamePhase phase;
  LocalTurnStep turnStep;
  List<LocalPlayer> players;
  int currentPlayerIndex;
  List<Card> drawPile;
  List<Card> discardPile;
  List<Meld> tableMelds;
  int round;
  int turnCount;
  String? winnerId;
  /// Tracks frich votes: playerId → true/false
  Map<String, bool> frichVotes;

  LocalGameState({
    required this.id,
    required this.config,
    this.phase = LocalGamePhase.waiting,
    this.turnStep = LocalTurnStep.draw,
    required this.players,
    this.currentPlayerIndex = 0,
    List<Card>? drawPile,
    List<Card>? discardPile,
    List<Meld>? tableMelds,
    this.round = 0,
    this.turnCount = 0,
    this.winnerId,
    Map<String, bool>? frichVotes,
  })  : drawPile = drawPile ?? [],
        discardPile = discardPile ?? [],
        tableMelds = tableMelds ?? [],
        frichVotes = frichVotes ?? {};

  LocalPlayer get currentPlayer => players[currentPlayerIndex];
}

// ─── Game Engine (offline) ───────────────────────────────────

class OfflineGameEngine {
  late LocalGameState state;

  OfflineGameEngine({
    required List<({String id, String name, bool isBot})> playerInfos,
    GameConfig config = const GameConfig(),
  }) {
    final players = playerInfos
        .map((p) => LocalPlayer(id: p.id, name: p.name, isBot: p.isBot))
        .toList();

    state = LocalGameState(
      id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
      config: config.copyWith(numPlayers: playerInfos.length),
      players: players,
    );
  }

  /// Start a new round
  void startRound({int? seed}) {
    final deck = shuffleDeck(createDeck(numJokers: state.config.numJokers), seed: seed);
    final (hands, remaining) = deal(deck, state.players.length, state.config.cardsPerPlayer);

    for (int i = 0; i < state.players.length; i++) {
      state.players[i].hand = hands[i];
      state.players[i].melds = [];
      state.players[i].hasOpened = false;
      state.players[i].openingScore = 0;
      state.players[i].drewFromDiscard = false;
      state.players[i].score = 0;
    }

    // Feature 7: Rotate first player each round (round is 1-based after increment)
    final firstPlayerIdx = (state.round) % state.players.length;

    // First player gets 1 extra card (15 instead of 14) — Rami Tunisien rule
    if (remaining.isNotEmpty) {
      state.players[firstPlayerIdx].hand.add(remaining.first);
      state.discardPile = [];
      state.drawPile = remaining.sublist(1);
    } else {
      state.discardPile = [];
      state.drawPile = [];
    }

    state.tableMelds = [];
    state.round++;
    state.currentPlayerIndex = firstPlayerIdx;
    state.turnCount = 0;
    state.winnerId = null;
    state.frichVotes = {};

    // Feature 5: Start with frich vote phase
    state.phase = LocalGamePhase.frichVote;
    state.turnStep = LocalTurnStep.play;
  }

  /// Feature 5: Vote for frich (reshuffle). Returns true if round restarted.
  bool voteFrich(String playerId, bool wantFrich) {
    if (state.phase != LocalGamePhase.frichVote) return false;
    state.frichVotes[playerId] = wantFrich;

    // Check if all players have voted
    if (state.frichVotes.length < state.players.length) return false;

    // If ANY player refused → start game normally
    if (state.frichVotes.values.any((v) => !v)) {
      _beginPlay();
      return false;
    }

    // All agreed → reshuffle (decrement round since startRound will re-increment)
    state.round--;
    startRound(seed: DateTime.now().millisecondsSinceEpoch);
    return true;
  }

  /// Skip frich and go straight to play
  void skipFrich() {
    if (state.phase == LocalGamePhase.frichVote) {
      _beginPlay();
    }
  }

  void _beginPlay() {
    state.phase = LocalGamePhase.playerTurn;
    // First player already has 15 cards → starts at play step (must discard/meld)
    state.turnStep = LocalTurnStep.play;
  }

  /// Draw from deck
  void drawFromDeck() {
    _assertPhase(LocalGamePhase.playerTurn);
    _assertStep(LocalTurnStep.draw);

    if (state.drawPile.isEmpty) {
      if (state.discardPile.length <= 1) throw Exception('No cards to draw');
      // Reshuffle
      final top = state.discardPile.removeLast();
      state.drawPile = shuffleDeck(state.discardPile);
      state.discardPile = [top];
    }

    final card = state.drawPile.removeAt(0);
    state.currentPlayer.hand.add(card);
    state.currentPlayer.drewFromDiscard = false;
    state.turnStep = LocalTurnStep.play;
  }

  /// Draw from discard pile — sets drewFromDiscard flag.
  /// Feature 8: Cannot take if you already have a duplicate (same rank+suit).
  void drawFromDiscard() {
    _assertPhase(LocalGamePhase.playerTurn);
    _assertStep(LocalTurnStep.draw);
    if (state.discardPile.isEmpty) throw Exception('Discard pile empty');

    final topCard = state.discardPile.last;
    // Feature 8: Check for duplicate in hand
    if (!topCard.isJoker) {
      final hasDuplicate = state.currentPlayer.hand.any((c) =>
          !c.isJoker && c.rank == topCard.rank && c.suit == topCard.suit);
      if (hasDuplicate) {
        throw Exception('Vous avez déjà un doublon de cette carte');
      }
    }

    final card = state.discardPile.removeLast();
    state.currentPlayer.hand.add(card);
    state.currentPlayer.drewFromDiscard = true;
    state.turnStep = LocalTurnStep.play;
  }

  /// Check if the top discard is a duplicate of a card in hand
  bool isDiscardDuplicate() {
    if (state.discardPile.isEmpty) return false;
    final topCard = state.discardPile.last;
    if (topCard.isJoker) return false;
    return state.currentPlayer.hand.any((c) =>
        !c.isJoker && c.rank == topCard.rank && c.suit == topCard.suit);
  }

  /// Place a meld (only works after opening, or when opening is not required)
  void meld(List<int> cardIds) {
    _assertPhase(LocalGamePhase.playerTurn);
    _assertStep(LocalTurnStep.play);

    final player = state.currentPlayer;
    if (!player.hasOpened && state.config.openingThreshold > 0) {
      throw Exception('Vous devez d\'abord ouvrir (utilisez meldBatch pour l\'ouverture)');
    }

    // Must keep at least 1 card to discard
    if (cardIds.length >= player.hand.length) {
      throw Exception('Vous devez garder au moins 1 carte pour défausser.');
    }

    final cards = cardIds.map((id) {
      final c = player.hand.firstWhere((c) => c.id == id,
          orElse: () => throw Exception('Card $id not in hand'));
      return c;
    }).toList();

    final type = validateMeld(cards, state.config);
    if (type == null) throw Exception('Invalid meld');

    // Sort run cards by rank for clean display
    final sortedCards = type == MeldType.run ? _sortRunCards(cards) : cards;

    final newMeld = Meld(
      id: 'meld_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      type: type,
      cards: sortedCards,
      ownerId: player.id,
    );

    player.hand.removeWhere((c) => cardIds.contains(c.id));
    player.melds.add(newMeld);
    state.tableMelds.add(newMeld);
  }

  /// Place multiple melds at once (for opening).
  /// Validates that total points >= threshold and at least one clean run.
  void meldBatch(List<List<int>> meldCardIds) {
    _assertPhase(LocalGamePhase.playerTurn);
    _assertStep(LocalTurnStep.play);

    final player = state.currentPlayer;

    // Step 1: Build melds with ORIGINAL card order (for accurate point calculation)
    final validationMelds = <Meld>[];
    final allCardIds = <int>[];

    for (final cardIds in meldCardIds) {
      final cards = cardIds.map((id) {
        final c = player.hand.firstWhere((c) => c.id == id,
            orElse: () => throw Exception('Card $id not in hand'));
        return c;
      }).toList();

      final type = validateMeld(cards, state.config);
      if (type == null) throw Exception('Un des paquets est invalide');

      validationMelds.add(Meld(
        id: 'meld_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}_${validationMelds.length}',
        type: type,
        cards: cards, // Original order for point calculation
        ownerId: player.id,
      ));
      allCardIds.addAll(cardIds);
    }

    // Edge case: cannot meld ALL remaining cards — must keep at least 1 to discard
    if (allCardIds.length >= player.hand.length) {
      throw Exception('Vous devez garder au moins 1 carte pour défausser.');
    }

    // Step 2: Validate opening requirements using ORIGINAL card order
    if (!player.hasOpened && state.config.openingThreshold > 0) {
      final opening = validateOpening(validationMelds, state.config);
      if (!opening.valid) {
        throw Exception(opening.reason ?? 'Ouverture invalide');
      }
      player.openingScore = opening.points;
    }

    // Step 3: Build display melds with SORTED runs (only after validation passes)
    final displayMelds = validationMelds.map((m) {
      final sortedCards = m.type == MeldType.run ? _sortRunCards(m.cards) : m.cards;
      return Meld(id: m.id, type: m.type, cards: sortedCards, ownerId: m.ownerId);
    }).toList();

    // All valid — commit
    player.hand.removeWhere((c) => allCardIds.contains(c.id));
    for (final m in displayMelds) {
      player.melds.add(m);
      state.tableMelds.add(m);
    }
    player.hasOpened = true;
  }

  /// Lay off a card onto a meld (with explicit position)
  void layoff(int cardId, String targetMeldId, String position) {
    _assertPhase(LocalGamePhase.playerTurn);
    _assertStep(LocalTurnStep.play);

    final player = state.currentPlayer;
    if (!player.hasOpened) throw Exception('Vous devez d\'abord ouvrir');
    if (player.hand.length <= 1) throw Exception('Gardez au moins 1 carte pour défausser');

    final card = player.hand.firstWhere((c) => c.id == cardId,
        orElse: () => throw Exception('Card not in hand'));

    final meldIdx = state.tableMelds.indexWhere((m) => m.id == targetMeldId);
    if (meldIdx == -1) throw Exception('Meld not found');

    if (!canLayoff(card, state.tableMelds[meldIdx], position, state.config)) {
      throw Exception('Impossible de poser cette carte ici');
    }

    final meld = state.tableMelds[meldIdx];
    final newCards = position == 'start' ? [card, ...meld.cards] : [...meld.cards, card];
    // Feature 2: Auto-sort runs after layoff
    final sortedCards = meld.type == MeldType.run ? _sortRunCards(newCards) : newCards;
    state.tableMelds[meldIdx] = Meld(id: meld.id, type: meld.type, cards: sortedCards, ownerId: meld.ownerId);
    player.hand.removeWhere((c) => c.id == cardId);
  }

  /// Auto-detect layoff position (start or end) and apply.
  String? layoffAuto(int cardId, String targetMeldId) {
    _assertPhase(LocalGamePhase.playerTurn);
    _assertStep(LocalTurnStep.play);

    final player = state.currentPlayer;
    if (!player.hasOpened) throw Exception('Vous devez d\'abord ouvrir');
    if (player.hand.length <= 1) return null; // Must keep 1 card to discard

    final card = player.hand.firstWhere((c) => c.id == cardId,
        orElse: () => throw Exception('Card not in hand'));

    final meldIdx = state.tableMelds.indexWhere((m) => m.id == targetMeldId);
    if (meldIdx == -1) throw Exception('Meld not found');

    final meld = state.tableMelds[meldIdx];

    if (canLayoff(card, meld, 'end', state.config)) {
      final newCards = [...meld.cards, card];
      final sortedCards = meld.type == MeldType.run ? _sortRunCards(newCards) : newCards;
      state.tableMelds[meldIdx] = Meld(id: meld.id, type: meld.type, cards: sortedCards, ownerId: meld.ownerId);
      player.hand.removeWhere((c) => c.id == cardId);
      return 'end';
    }
    if (canLayoff(card, meld, 'start', state.config)) {
      final newCards = [card, ...meld.cards];
      final sortedCards = meld.type == MeldType.run ? _sortRunCards(newCards) : newCards;
      state.tableMelds[meldIdx] = Meld(id: meld.id, type: meld.type, cards: sortedCards, ownerId: meld.ownerId);
      player.hand.removeWhere((c) => c.id == cardId);
      return 'start';
    }
    return null;
  }

  /// Lay off a card and swap out a joker if the card replaces it.
  Card? layoffWithJokerSwap(int cardId, String targetMeldId) {
    _assertPhase(LocalGamePhase.playerTurn);
    _assertStep(LocalTurnStep.play);

    final player = state.currentPlayer;
    if (!player.hasOpened) throw Exception('Vous devez d\'abord ouvrir');

    final card = player.hand.firstWhere((c) => c.id == cardId,
        orElse: () => throw Exception('Card not in hand'));

    final meldIdx = state.tableMelds.indexWhere((m) => m.id == targetMeldId);
    if (meldIdx == -1) throw Exception('Meld not found');

    final meld = state.tableMelds[meldIdx];
    final jokerInMeld = meld.cards.where((c) => c.isJoker).toList();

    // Run: try replacing joker with this card
    if (jokerInMeld.isNotEmpty && meld.type == MeldType.run && !card.isJoker) {
      for (final joker in jokerInMeld) {
        final jokerIdx = meld.cards.indexOf(joker);
        final testCards = List<Card>.from(meld.cards);
        testCards[jokerIdx] = card;
        if (validateMeld(testCards, state.config) != null) {
          // Auto-sort the resulting run
          final sortedCards = _sortRunCards(testCards);
          state.tableMelds[meldIdx] = Meld(id: meld.id, type: meld.type, cards: sortedCards, ownerId: meld.ownerId);
          player.hand.removeWhere((c) => c.id == cardId);
          player.hand.add(joker);
          return joker;
        }
      }
    }

    // Feature 3: Set — joker can ONLY be recovered when set becomes a full carré (4 distinct suits)
    if (jokerInMeld.isNotEmpty && meld.type == MeldType.set && !card.isJoker) {
      final realCards = meld.cards.where((c) => !c.isJoker).toList();
      if (realCards.isNotEmpty && card.rank == realCards.first.rank) {
        final existingSuits = realCards.map((c) => c.suit).toSet();
        if (!existingSuits.contains(card.suit)) {
          // Replace joker with card
          final joker = jokerInMeld.first;
          final jokerIdx = meld.cards.indexOf(joker);
          final testCards = List<Card>.from(meld.cards);
          testCards[jokerIdx] = card;

          // Check if this makes a valid carré (4 cards, 4 distinct suits)
          final resultRealCards = testCards.where((c) => !c.isJoker).toList();
          final resultSuits = resultRealCards.map((c) => c.suit).toSet();
          final isFullCarre = resultRealCards.length == 4 && resultSuits.length == 4;

          if (isFullCarre && validateMeld(testCards, state.config) != null) {
            state.tableMelds[meldIdx] = Meld(id: meld.id, type: meld.type, cards: testCards, ownerId: meld.ownerId);
            player.hand.removeWhere((c) => c.id == cardId);
            player.hand.add(joker);
            return joker;
          }
          // Not a full carré → just do normal layoff (no joker recovery)
        }
      }
    }

    // No joker swap — try normal layoff (checks keep-1-card)
    final pos = layoffAuto(cardId, targetMeldId);
    if (pos == null) throw Exception('Impossible de poser cette carte sur ce paquet');
    return null;
  }

  /// Discard a card (ends play phase)
  void discard(int cardId) {
    _assertPhase(LocalGamePhase.playerTurn);
    _assertStep(LocalTurnStep.play);

    final player = state.currentPlayer;
    final card = player.hand.firstWhere((c) => c.id == cardId,
        orElse: () => throw Exception('Card not in hand'));

    // Penalty: drew from discard pile but didn't open → 100 pts
    if (player.drewFromDiscard && !player.hasOpened) {
      player.hand.removeWhere((c) => c.id == cardId);
      state.discardPile.add(card);
      // Apply 100pts penalty (accumulated — will be added at _endRound)
      player.score += 100;
      player.drewFromDiscard = false;
      _advanceTurn();
      return;
    }

    player.hand.removeWhere((c) => c.id == cardId);
    state.discardPile.add(card);
    player.drewFromDiscard = false;

    // Check round end
    if (player.hand.isEmpty) {
      _endRound(player.id);
      return;
    }

    _advanceTurn();
  }

  // ═══════════════════════════════════════════════════════════
  // BOT AI — Step-by-step methods for animated turns
  // ═══════════════════════════════════════════════════════════

  /// Feature 1: Auto-play for human player when timer expires
  void autoPlayTurn() {
    if (state.phase != LocalGamePhase.playerTurn) return;
    final player = state.currentPlayer;

    // Step 1: Draw if needed
    if (state.turnStep == LocalTurnStep.draw) {
      drawFromDeck();
    }

    // Step 2: Try layoffs if opened
    if (player.hasOpened && player.hand.length > 1) {
      bool didLayoff = true;
      int maxAttempts = 20;
      while (didLayoff && maxAttempts-- > 0) {
        didLayoff = false;
        for (final card in List<Card>.from(player.hand)) {
          if (player.hand.length <= 1) break;
          for (final m in state.tableMelds) {
            try {
              final pos = layoffAuto(card.id, m.id);
              if (pos != null) { didLayoff = true; break; }
            } catch (_) {}
          }
          if (didLayoff) break;
        }
      }
    }

    if (player.hand.isEmpty) { _endRound(player.id); return; }

    // Step 3: Discard worst card (never jokers, never placeable cards)
    final discardable = player.hand.where((c) => !c.isJoker).toList();
    if (discardable.isEmpty) {
      discard(player.hand.last.id);
      return;
    }
    final scored = discardable.map((card) {
      int pts = getCardPoints(card, state.config);
      for (final m in state.tableMelds) {
        if (canLayoffAny(card, m, state.config)) { pts -= 50; break; }
      }
      return (card: card, score: pts);
    }).toList()..sort((a, b) => b.score.compareTo(a.score));
    discard(scored.first.card.id);
  }

  /// Step 1: Bot draws a card. Returns true if drew.
  bool executeBotDraw() {
    final player = state.currentPlayer;
    if (!player.isBot) return false;
    if (state.phase != LocalGamePhase.playerTurn) return false;
    if (state.turnStep != LocalTurnStep.draw) return false;

    // Feature 4: Smart draw — check if top discard is useful
    if (state.discardPile.isNotEmpty) {
      final topCard = state.discardPile.last;
      // Don't draw discard if it's a duplicate (Feature 8)
      if (!isDiscardDuplicate()) {
        // Check if it can complete a meld or layoff
        bool useful = false;
        // Check layoff potential
        if (player.hasOpened) {
          for (final m in state.tableMelds) {
            if (canLayoffAny(topCard, m, state.config)) { useful = true; break; }
          }
        }
        // Check meld potential in hand
        if (!useful) {
          for (int i = 0; i < player.hand.length - 1; i++) {
            for (int j = i + 1; j < player.hand.length; j++) {
              if (validateMeld([topCard, player.hand[i], player.hand[j]], state.config) != null) {
                useful = true; break;
              }
            }
            if (useful) break;
          }
        }
        if (useful) {
          try { drawFromDiscard(); return true; } catch (_) {}
        }
      }
    }

    drawFromDeck();
    return true;
  }

  /// Step 2: Bot tries to place ONE meld (or do full opening).
  /// Returns true if a meld was placed.
  bool executeBotSingleMeld() {
    final player = state.currentPlayer;
    if (!player.isBot) return false;
    if (state.phase != LocalGamePhase.playerTurn) return false;
    if (state.turnStep != LocalTurnStep.play) return false;

    if (!player.hasOpened) {
      // Try opening (places all opening melds at once via meldBatch)
      return _tryBotOpening();
    } else {
      // Post-opening: try to place one valid meld
      if (player.hand.length <= 1) return false;
      final found = _findBestMeld(player.hand);
      if (found != null && found.length < player.hand.length) {
        try {
          meld(found.map((c) => c.id).toList());
          return true;
        } catch (_) {}
      }
      return false;
    }
  }

  /// Step 3: Bot tries ONE layoff on any table meld. Returns true if placed.
  bool executeBotSingleLayoff() {
    final player = state.currentPlayer;
    if (!player.isBot || !player.hasOpened) return false;
    if (player.hand.length <= 1) return false;

    for (final card in List<Card>.from(player.hand)) {
      if (player.hand.length <= 1) break;
      for (int mi = 0; mi < state.tableMelds.length; mi++) {
        final m = state.tableMelds[mi];
        try {
          final pos = layoffAuto(card.id, m.id);
          if (pos != null) return true;
        } catch (_) {}
      }
    }
    return false;
  }

  /// Feature 4: Bot tries to recover a joker from table melds
  bool executeBotJokerRecovery() {
    final player = state.currentPlayer;
    if (!player.isBot || !player.hasOpened) return false;
    if (player.hand.length <= 1) return false;

    for (final card in List<Card>.from(player.hand)) {
      if (card.isJoker) continue;
      for (int mi = 0; mi < state.tableMelds.length; mi++) {
        final m = state.tableMelds[mi];
        if (!m.cards.any((c) => c.isJoker)) continue;
        try {
          final recovered = layoffWithJokerSwap(card.id, m.id);
          if (recovered != null) return true;
        } catch (_) {}
      }
    }
    return false;
  }

  /// Step 4: Bot discards best card.
  void executeBotDiscard() {
    final player = state.currentPlayer;
    if (!player.isBot) return;
    if (player.hand.isEmpty) return;

    // Never discard jokers
    final discardable = player.hand.where((c) => !c.isJoker).toList();
    if (discardable.isEmpty) {
      discard(player.hand.last.id);
      return;
    }

    // Score each card: higher score = more likely to discard
    final scored = discardable.map((card) {
      int pts = getCardPoints(card, state.config);
      // Penalty: don't discard cards that could layoff on table melds
      for (final m in state.tableMelds) {
        if (canLayoffAny(card, m, state.config)) {
          pts -= 50;
          break;
        }
      }
      // Penalty: don't discard cards that form potential melds in hand
      final others = player.hand.where((c) => c.id != card.id).toList();
      for (int i = 0; i < others.length - 1; i++) {
        for (int j = i + 1; j < others.length; j++) {
          if (validateMeld([card, others[i], others[j]], state.config) != null) {
            pts -= 30;
            break;
          }
        }
      }
      return (card: card, score: pts);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    discard(scored.first.card.id);
  }

  /// Legacy: full bot turn in one call (kept for compatibility)
  void executeBotTurn() {
    final player = state.currentPlayer;
    if (!player.isBot) throw Exception('Not a bot');
    if (state.phase != LocalGamePhase.playerTurn) return;

    executeBotDraw();

    // Melds
    bool didMeld = true;
    while (didMeld) {
      didMeld = executeBotSingleMeld();
    }

    // Layoffs
    if (player.hasOpened) {
      bool didLayoff = true;
      while (didLayoff) {
        didLayoff = executeBotSingleLayoff();
      }
      // Joker recovery
      bool didRecover = true;
      while (didRecover) {
        didRecover = executeBotJokerRecovery();
      }
    }

    if (player.hand.isEmpty) {
      _endRound(player.id);
      return;
    }

    executeBotDiscard();
  }

  // ─── Bot: Opening Logic ─────────────────────────────────

  /// Try to open. Returns true if opened successfully.
  bool _tryBotOpening() {
    final player = state.currentPlayer;
    if (player.hasOpened) return false;
    final hand = player.hand;

    final foundMelds = <List<int>>[];
    final usedIds = <int>{};
    int totalPts = 0;
    bool hasCleanRun = false;

    // Sort hand by suit + rank for better run detection
    final sortedHand = List<Card>.from(hand)
      ..sort((a, b) {
        if (a.isJoker) return 1;
        if (b.isJoker) return -1;
        final sc = (a.suit?.index ?? 99).compareTo(b.suit?.index ?? 99);
        return sc != 0 ? sc : a.rank!.value.compareTo(b.rank!.value);
      });

    // Group by suit for runs
    final suitGroups = <Suit?, List<Card>>{};
    for (final c in sortedHand.where((c) => !c.isJoker)) {
      suitGroups.putIfAbsent(c.suit, () => []).add(c);
    }
    final jokers = hand.where((c) => c.isJoker).toList();
    int jokersUsed = 0;

    // Find runs (prefer clean runs — no joker)
    for (final entry in suitGroups.entries) {
      final suited = entry.value;
      for (int start = 0; start < suited.length; start++) {
        for (int end = suited.length - 1; end >= start + 1; end--) {
          final segment = suited.sublist(start, end + 1);
          if (segment.any((c) => usedIds.contains(c.id))) continue;

          int gaps = 0;
          for (int i = 1; i < segment.length; i++) {
            gaps += segment[i].rank!.value - segment[i - 1].rank!.value - 1;
          }
          final totalCards = segment.length + gaps;
          if (totalCards >= 3 && gaps <= jokers.length - jokersUsed) {
            final meldCards = [...segment];
            for (int j = 0; j < gaps; j++) {
              meldCards.add(jokers[jokersUsed + j]);
            }
            if (validateMeld(meldCards, state.config) != null) {
              final ids = meldCards.map((c) => c.id).toList();
              foundMelds.add(ids);
              usedIds.addAll(ids);
              totalPts += calculateMeldPoints(meldCards, state.config);
              jokersUsed += gaps;
              if (gaps == 0) hasCleanRun = true;
              break;
            }
          }
        }
      }
    }

    // Find sets
    final rankGroups = <int, List<Card>>{};
    for (final c in hand.where((c) => !c.isJoker && !usedIds.contains(c.id))) {
      rankGroups.putIfAbsent(c.rank!.value, () => []).add(c);
    }
    for (final entry in rankGroups.entries) {
      final avail = entry.value.where((c) => !usedIds.contains(c.id)).toList();
      if (avail.length >= 3) {
        final cards = avail.sublist(0, avail.length.clamp(3, 4));
        if (validateMeld(cards, state.config) != null) {
          foundMelds.add(cards.map((c) => c.id).toList());
          usedIds.addAll(cards.map((c) => c.id));
          totalPts += calculateMeldPoints(cards, state.config);
        }
      }
    }

    // Check: must keep at least 1 card to discard
    if (usedIds.length >= player.hand.length) return false;

    if (totalPts >= state.config.openingThreshold && hasCleanRun) {
      try {
        meldBatch(foundMelds);
        return true;
      } catch (_) {}
    }
    return false;
  }

  // ─── Bot: Find Best Meld ────────────────────────────────

  /// Find the best meld in a hand (longest run first, then sets)
  List<Card>? _findBestMeld(List<Card> hand) {
    if (hand.length <= 1) return null;

    // Try runs by suit (longest first)
    final suitGroups = <Suit?, List<Card>>{};
    for (final c in hand.where((c) => !c.isJoker)) {
      suitGroups.putIfAbsent(c.suit, () => []).add(c);
    }
    final jokers = hand.where((c) => c.isJoker).toList();

    for (final entry in suitGroups.entries) {
      final suited = List<Card>.from(entry.value)
        ..sort((a, b) => a.rank!.value.compareTo(b.rank!.value));

      for (int start = 0; start < suited.length; start++) {
        for (int end = suited.length - 1; end >= start + 1; end--) {
          final segment = suited.sublist(start, end + 1);
          int gaps = 0;
          for (int i = 1; i < segment.length; i++) {
            gaps += segment[i].rank!.value - segment[i - 1].rank!.value - 1;
          }
          final totalCards = segment.length + gaps;
          if (totalCards >= 3 && gaps <= jokers.length) {
            final meldCards = [...segment, ...jokers.sublist(0, gaps)];
            if (validateMeld(meldCards, state.config) != null) {
              return meldCards;
            }
          }
        }
      }
    }

    // Try sets (3 or 4 of same rank)
    final rankGroups = <int, List<Card>>{};
    for (final c in hand.where((c) => !c.isJoker)) {
      rankGroups.putIfAbsent(c.rank!.value, () => []).add(c);
    }
    for (final entry in rankGroups.entries) {
      if (entry.value.length >= 3) {
        final cards = entry.value.sublist(0, entry.value.length.clamp(3, 4));
        if (validateMeld(cards, state.config) != null) return cards;
      }
      if (entry.value.length >= 2 && jokers.isNotEmpty) {
        final cards = [...entry.value.sublist(0, 2), jokers.first];
        if (validateMeld(cards, state.config) != null) return cards;
      }
    }

    return null;
  }

  // ─── Helpers ─────────────────────────────────────────────

  /// Sort cards in a run by rank (handles jokers placed in gaps)
  List<Card> _sortRunCards(List<Card> cards) {
    final jokers = cards.where((c) => c.isJoker).toList();
    final normals = cards.where((c) => !c.isJoker).toList();
    if (normals.isEmpty) return cards;

    final hasAce = normals.any((c) => c.rank!.value == 1);
    final otherValues = normals.where((c) => c.rank!.value != 1).map((c) => c.rank!.value).toList();
    final aceValue = (hasAce && otherValues.isNotEmpty && otherValues.reduce((a, b) => a > b ? a : b) >= 10) ? 14 : 1;

    normals.sort((a, b) {
      final va = a.rank!.value == 1 ? aceValue : a.rank!.value;
      final vb = b.rank!.value == 1 ? aceValue : b.rank!.value;
      return va.compareTo(vb);
    });

    final result = <Card>[];
    int jokerIdx = 0;
    for (int i = 0; i < normals.length; i++) {
      result.add(normals[i]);
      if (i < normals.length - 1) {
        final va = normals[i].rank!.value == 1 ? aceValue : normals[i].rank!.value;
        final vb = normals[i + 1].rank!.value == 1 ? aceValue : normals[i + 1].rank!.value;
        final gap = vb - va - 1;
        for (int g = 0; g < gap && jokerIdx < jokers.length; g++) {
          result.add(jokers[jokerIdx++]);
        }
      }
    }
    while (jokerIdx < jokers.length) {
      result.add(jokers[jokerIdx++]);
    }
    return result;
  }

  void _endRound(String winnerId) {
    // Calculate scores: card points + any accumulated penalties (e.g. 100pts for discard fail)
    for (final player in state.players) {
      if (player.hand.isEmpty) {
        // Winner: no card points, but keep any penalty from this round
        // (winner shouldn't have penalty, but just in case)
      } else {
        player.score += player.hand.fold(0, (sum, c) => sum + getCardPoints(c, state.config));
      }
      player.totalScore += player.score;
    }
    state.winnerId = winnerId;

    // Check game end
    if (state.round >= state.config.maxRounds) {
      state.phase = LocalGamePhase.gameEnd;
      // Winner = lowest total score
      state.players.sort((a, b) => a.totalScore.compareTo(b.totalScore));
      state.winnerId = state.players.first.id;
    } else if (state.config.scoringMode == 'elimination') {
      final alive = state.players.where((p) => p.totalScore < state.config.eliminationThreshold).toList();
      if (alive.length <= 1) {
        state.phase = LocalGamePhase.gameEnd;
        state.winnerId = alive.isNotEmpty ? alive.first.id : null;
      } else {
        state.phase = LocalGamePhase.roundEnd;
      }
    } else {
      state.phase = LocalGamePhase.roundEnd;
    }
  }

  void _advanceTurn() {
    state.currentPlayerIndex = (state.currentPlayerIndex + 1) % state.players.length;
    state.turnStep = LocalTurnStep.draw;
    state.turnCount++;
  }

  void _assertPhase(LocalGamePhase expected) {
    if (state.phase != expected) throw Exception('Wrong phase: ${state.phase}');
  }

  void _assertStep(LocalTurnStep expected) {
    if (state.turnStep != expected) throw Exception('Wrong step: ${state.turnStep}');
  }
}

















