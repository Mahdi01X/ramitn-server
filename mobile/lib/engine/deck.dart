import 'dart:math';
import '../models/card.dart';
import '../models/game_config.dart';

/// Create a full deck: 2×52 + numJokers
List<Card> createDeck({int numJokers = 4}) {
  final cards = <Card>[];
  int id = 0;

  for (int deckIndex = 0; deckIndex < 2; deckIndex++) {
    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        cards.add(Card(id: id++, suit: suit, rank: rank, deckIndex: deckIndex));
      }
    }
  }

  for (int j = 0; j < numJokers; j++) {
    cards.add(Card(id: id++, isJoker: true, deckIndex: j % 2));
  }

  return cards;
}

/// Fisher-Yates shuffle
List<Card> shuffleDeck(List<Card> cards, {int? seed}) {
  final rng = seed != null ? Random(seed) : Random();
  final arr = List<Card>.from(cards);
  for (int i = arr.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final temp = arr[i];
    arr[i] = arr[j];
    arr[j] = temp;
  }
  return arr;
}

/// Deal cards. Returns (hands, remainingDeck)
(List<List<Card>>, List<Card>) deal(List<Card> deck, int numPlayers, int cardsPerPlayer) {
  final hands = List.generate(numPlayers, (_) => <Card>[]);
  int idx = 0;

  for (int c = 0; c < cardsPerPlayer; c++) {
    for (int p = 0; p < numPlayers; p++) {
      if (idx < deck.length) {
        hands[p].add(deck[idx++]);
      }
    }
  }

  return (hands, deck.sublist(idx));
}


