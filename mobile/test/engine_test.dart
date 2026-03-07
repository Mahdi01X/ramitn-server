import 'package:flutter_test/flutter_test.dart';
import 'package:rami_tunisien/engine/deck.dart';
import 'package:rami_tunisien/engine/meld_validator.dart';
import 'package:rami_tunisien/engine/game_engine.dart';
import 'package:rami_tunisien/models/card.dart';
import 'package:rami_tunisien/models/meld.dart';
import 'package:rami_tunisien/models/game_config.dart';

void main() {
  group('Deck', () {
    test('createDeck creates 108 cards by default (2x52 + 4 jokers)', () {
      final deck = createDeck();
      expect(deck.length, 108);
    });

    test('createDeck creates 106 cards with 2 jokers', () {
      final deck = createDeck(numJokers: 2);
      expect(deck.length, 106);
    });

    test('createDeck has unique ids', () {
      final deck = createDeck();
      final ids = deck.map((c) => c.id).toSet();
      expect(ids.length, 108);
    });

    test('createDeck has correct joker count', () {
      final deck = createDeck(numJokers: 4);
      final jokers = deck.where((c) => c.isJoker).toList();
      expect(jokers.length, 4);
      expect(deck.length, 108);
    });

    test('shuffle changes order', () {
      final deck = createDeck();
      final shuffled = shuffleDeck(deck, seed: 42);
      final sameOrder = List.generate(deck.length, (i) => deck[i].id == shuffled[i].id)
          .every((x) => x);
      expect(sameOrder, false);
    });

    test('deal distributes correctly', () {
      final deck = shuffleDeck(createDeck(numJokers: 2), seed: 42);
      final (hands, remaining) = deal(deck, 4, 14);
      expect(hands.length, 4);
      for (final hand in hands) {
        expect(hand.length, 14);
      }
      expect(remaining.length, 106 - 56); // 106 cards - 4*14 dealt
    });
  });

  group('Meld Validator', () {
    const config = GameConfig();

    Card c(Rank rank, Suit suit, [int id = 0]) =>
        Card(id: id, rank: rank, suit: suit);

    Card joker([int id = 99]) =>
        Card(id: id, isJoker: true);

    test('valid 3-card set', () {
      final cards = [
        c(Rank.seven, Suit.hearts, 1),
        c(Rank.seven, Suit.spades, 2),
        c(Rank.seven, Suit.diamonds, 3),
      ];
      expect(isValidSet(cards, config), true);
    });

    test('invalid set different ranks', () {
      final cards = [
        c(Rank.seven, Suit.hearts, 1),
        c(Rank.eight, Suit.spades, 2),
        c(Rank.seven, Suit.diamonds, 3),
      ];
      expect(isValidSet(cards, config), false);
    });

    test('valid 3-card run', () {
      final cards = [
        c(Rank.five, Suit.hearts, 1),
        c(Rank.six, Suit.hearts, 2),
        c(Rank.seven, Suit.hearts, 3),
      ];
      expect(isValidRun(cards, config), true);
    });

    test('invalid run different suits', () {
      final cards = [
        c(Rank.five, Suit.hearts, 1),
        c(Rank.six, Suit.spades, 2),
        c(Rank.seven, Suit.hearts, 3),
      ];
      expect(isValidRun(cards, config), false);
    });

    test('valid run with joker', () {
      final cards = [
        c(Rank.five, Suit.hearts, 1),
        joker(99),
        c(Rank.seven, Suit.hearts, 3),
      ];
      expect(isValidRun(cards, config), true);
    });

    test('validateMeld detects set', () {
      final cards = [
        c(Rank.ten, Suit.hearts, 1),
        c(Rank.ten, Suit.spades, 2),
        c(Rank.ten, Suit.diamonds, 3),
      ];
      expect(validateMeld(cards, config), MeldType.set);
    });

    test('validateMeld detects run', () {
      final cards = [
        c(Rank.eight, Suit.clubs, 1),
        c(Rank.nine, Suit.clubs, 2),
        c(Rank.ten, Suit.clubs, 3),
      ];
      expect(validateMeld(cards, config), MeldType.run);
    });

    test('getCardPoints face card returns 10', () {
      expect(getCardPoints(c(Rank.king, Suit.hearts), config), 10);
    });

    test('getCardPoints joker returns jokerValue', () {
      expect(getCardPoints(joker(), config), 30);
    });
  });

  group('Opening Rules (71 pts + clean run)', () {
    const config = GameConfig(); // defaults: 71 threshold, cleanRun required

    Card c(Rank rank, Suit suit, [int id = 0]) =>
        Card(id: id, rank: rank, suit: suit);

    Card joker([int id = 99]) =>
        Card(id: id, isJoker: true);

    test('clean run detected (no jokers)', () {
      final meld = Meld(
        id: 'test',
        type: MeldType.run,
        cards: [
          c(Rank.jack, Suit.hearts, 1),
          c(Rank.queen, Suit.hearts, 2),
          c(Rank.king, Suit.hearts, 3),
        ],
      );
      expect(isCleanRun(meld), true);
    });

    test('run with joker is NOT a clean run', () {
      final meld = Meld(
        id: 'test',
        type: MeldType.run,
        cards: [
          c(Rank.jack, Suit.hearts, 1),
          joker(99),
          c(Rank.king, Suit.hearts, 3),
        ],
      );
      expect(isCleanRun(meld), false);
    });

    test('set is NOT a clean run', () {
      final meld = Meld(
        id: 'test',
        type: MeldType.set,
        cards: [
          c(Rank.king, Suit.hearts, 1),
          c(Rank.king, Suit.spades, 2),
          c(Rank.king, Suit.diamonds, 3),
        ],
      );
      expect(isCleanRun(meld), false);
    });

    test('validateOpening rejects insufficient points', () {
      final meld = Meld(
        id: 'test',
        type: MeldType.run,
        cards: [
          c(Rank.two, Suit.hearts, 1),
          c(Rank.three, Suit.hearts, 2),
          c(Rank.four, Suit.hearts, 3),
        ],
      );
      // 2+3+4 = 9 points < 71
      final result = validateOpening([meld], config);
      expect(result.valid, false);
      expect(result.points, 9);
    });

    test('validateOpening rejects set-only opening (no clean run)', () {
      // K♥ K♠ K♦ K♣ = 40 points
      // + K♦2 K♣2 K♠2 = 30 points = 70 < 71... need more
      // Let's use: Q♥ Q♠ Q♦ Q♣ (40) + K♥ K♠ K♦ K♣ (40) = 80 pts
      // But these are sets, not runs → should fail clean run check
      final set1 = Meld(
        id: 'set1',
        type: MeldType.set,
        cards: [
          c(Rank.queen, Suit.hearts, 10),
          c(Rank.queen, Suit.spades, 11),
          c(Rank.queen, Suit.diamonds, 12),
          c(Rank.queen, Suit.clubs, 13),
        ],
      );
      final set2 = Meld(
        id: 'set2',
        type: MeldType.set,
        cards: [
          c(Rank.king, Suit.hearts, 20),
          c(Rank.king, Suit.spades, 21),
          c(Rank.king, Suit.diamonds, 22),
          c(Rank.king, Suit.clubs, 23),
        ],
      );
      // 80 pts, but no clean run
      final result = validateOpening([set1, set2], config);
      expect(result.valid, false);
      expect(result.reason, contains('suite sans joker'));
    });

    test('validateOpening accepts clean run with enough points', () {
      // 10♥ J♥ Q♥ K♥ = 10+10+10+10 = 40
      // + 10♠ J♠ Q♠ K♠ = 40
      // Total = 80 >= 71, and first meld is a clean run
      final run1 = Meld(
        id: 'run1',
        type: MeldType.run,
        cards: [
          c(Rank.ten, Suit.hearts, 30),
          c(Rank.jack, Suit.hearts, 31),
          c(Rank.queen, Suit.hearts, 32),
          c(Rank.king, Suit.hearts, 33),
        ],
      );
      final run2 = Meld(
        id: 'run2',
        type: MeldType.run,
        cards: [
          c(Rank.ten, Suit.spades, 40),
          c(Rank.jack, Suit.spades, 41),
          c(Rank.queen, Suit.spades, 42),
          c(Rank.king, Suit.spades, 43),
        ],
      );
      final result = validateOpening([run1, run2], config);
      expect(result.valid, true);
      expect(result.points, 80);
    });

    test('validateOpening accepts mix of clean run + set if threshold met', () {
      // Clean run: 10♥ J♥ Q♥ K♥ = 40
      // Set: A♥ A♠ A♦ = 33 (ace=11 x3)
      // Total = 73 >= 71
      final run = Meld(
        id: 'run',
        type: MeldType.run,
        cards: [
          c(Rank.ten, Suit.hearts, 50),
          c(Rank.jack, Suit.hearts, 51),
          c(Rank.queen, Suit.hearts, 52),
          c(Rank.king, Suit.hearts, 53),
        ],
      );
      final set1 = Meld(
        id: 'set',
        type: MeldType.set,
        cards: [
          c(Rank.ace, Suit.hearts, 60),
          c(Rank.ace, Suit.spades, 61),
          c(Rank.ace, Suit.diamonds, 62),
        ],
      );
      final result = validateOpening([run, set1], config);
      expect(result.valid, true);
      expect(result.points, 73);
    });
  });

  group('Offline Game Engine', () {
    test('starts a game: P1 gets 15 cards, P2 gets 14', () {
      final engine = OfflineGameEngine(
        playerInfos: [
          (id: 'p1', name: 'Alice', isBot: false),
          (id: 'p2', name: 'Bob', isBot: false),
        ],
      );
      engine.startRound(seed: 42);

      expect(engine.state.phase, LocalGamePhase.playerTurn);
      expect(engine.state.players[0].hand.length, 15); // First player gets 15
      expect(engine.state.players[1].hand.length, 14);
      expect(engine.state.turnStep, LocalTurnStep.play); // Starts at play (must discard)
      expect(engine.state.discardPile.length, 0); // No initial discard
      expect(engine.state.round, 1);
    });

    test('first player discards (has 15 cards), then P2 draws', () {
      final engine = OfflineGameEngine(
        playerInfos: [
          (id: 'p1', name: 'Alice', isBot: false),
          (id: 'p2', name: 'Bob', isBot: false),
        ],
      );
      engine.startRound(seed: 42);

      // P1 starts with 15 cards at play step — must discard
      expect(engine.state.turnStep, LocalTurnStep.play);
      final cardToDiscard = engine.state.players[0].hand.first;
      engine.discard(cardToDiscard.id);

      // Turn advances to P2
      expect(engine.state.currentPlayerIndex, 1);
      expect(engine.state.turnStep, LocalTurnStep.draw);
      expect(engine.state.players[0].hand.length, 14);
      expect(engine.state.discardPile.length, 1);

      // P2 draws from deck
      engine.drawFromDeck();
      expect(engine.state.players[1].hand.length, 15);
      expect(engine.state.turnStep, LocalTurnStep.play);
    });

    test('full turn cycle', () {
      final engine = OfflineGameEngine(
        playerInfos: [
          (id: 'p1', name: 'Alice', isBot: false),
          (id: 'p2', name: 'Bob', isBot: false),
        ],
      );
      engine.startRound(seed: 42);

      // P1 turn: already at play step with 15 cards, just discard
      engine.discard(engine.state.players[0].hand.first.id);

      // P2 turn: draw then discard
      engine.drawFromDeck();
      engine.discard(engine.state.players[1].hand.first.id);

      // Back to P1: draw then discard
      engine.drawFromDeck();
      engine.discard(engine.state.players[0].hand.first.id);

      expect(engine.state.currentPlayerIndex, 1);
      expect(engine.state.turnCount, 3);
    });

    test('P2 can draw from discard after P1 discards', () {
      final engine = OfflineGameEngine(
        playerInfos: [
          (id: 'p1', name: 'Alice', isBot: false),
          (id: 'p2', name: 'Bob', isBot: false),
        ],
      );
      engine.startRound(seed: 42);

      // P1 discards
      final discardedCard = engine.state.players[0].hand.last;
      engine.discard(discardedCard.id);

      // P2 draws from discard
      engine.drawFromDiscard();
      expect(engine.state.players[1].hand.length, 15);
      expect(engine.state.players[1].hand.any((c) => c.id == discardedCard.id), true);
      expect(engine.state.discardPile.length, 0);
    });
  });
}






