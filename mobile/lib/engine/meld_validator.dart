import '../models/card.dart';
import '../models/meld.dart';
import '../models/game_config.dart';

/// Check if cards form a valid set
bool isValidSet(List<Card> cards, GameConfig config) {
  if (cards.length < 3 || cards.length > 4) return false;

  final jokers = cards.where((c) => c.isJoker).toList();
  final normals = cards.where((c) => !c.isJoker).toList();

  // Max jokers per meld check (matching server)
  if (jokers.length > config.maxJokersPerMeld) return false;

  // Need at least 1 real card to determine rank
  if (normals.isEmpty) return false;

  final rank = normals.first.rank!;
  if (!normals.every((c) => c.rank == rank)) return false;

  final suits = normals.map((c) => c.suit).toSet();
  if (suits.length != normals.length) return false;

  return true;
}

/// Check if cards form a valid run
bool isValidRun(List<Card> cards, GameConfig config) {
  if (cards.length < 3) return false;

  final jokers = cards.where((c) => c.isJoker).toList();
  final normals = cards.where((c) => !c.isJoker).toList();

  // Max jokers per meld check (matching server)
  if (jokers.length > config.maxJokersPerMeld) return false;

  // Need at least 1 real card to determine suit/rank anchor
  if (normals.isEmpty) return false;

  final suit = normals.first.suit;
  if (!normals.every((c) => c.suit == suit)) return false;

  // Try Ace as low (1) first, then as high (14)
  final hasAce = normals.any((c) => c.rank!.value == 1);

  bool tryConsecutive(int aceValue) {
    final values = normals.map((c) => c.rank!.value == 1 ? aceValue : c.rank!.value).toList()..sort();
    // Check duplicates
    for (int i = 1; i < values.length; i++) {
      if (values[i] == values[i - 1]) return false;
    }
    // Check consecutive with jokers
    int used = 0;
    for (int i = 1; i < values.length; i++) {
      final gap = values[i] - values[i - 1] - 1;
      if (gap < 0) return false;
      used += gap;
      if (used > jokers.length) return false;
    }
    return true;
  }

  if (tryConsecutive(1)) return true;
  if (hasAce && tryConsecutive(14)) return true;
  return false;
}

/// Validate a meld (auto-detect type)
MeldType? validateMeld(List<Card> cards, GameConfig config) {
  if (isValidSet(cards, config)) return MeldType.set;
  if (isValidRun(cards, config)) return MeldType.run;
  return null;
}

/// Get point value of a card (standalone — used for PENALTY scoring at end of round)
/// Joker = 30 points penalty. As = 11 penalty.
int getCardPoints(Card card, GameConfig config) {
  if (card.isJoker) return config.jokerValue; // 30
  final rank = card.rank!.value;
  if (rank == 1) return config.aceHighValue; // 11
  if (rank >= 11) return 10;
  return rank;
}

/// Get the point value of a single rank for meld scoring (not penalty).
/// Ace low (value=1) = 1 point. Ace high (value=14) = 11 points.
int _rankPoints(int rankValue, GameConfig config) {
  if (rankValue == 14) return config.aceHighValue; // Ace high = 11
  if (rankValue == 1) return 1; // Ace low = 1
  if (rankValue >= 11) return 10; // J, Q, K = 10
  return rankValue;
}

/// Calculate meld points for opening — Joker takes the value of
/// the card it replaces (e.g. 10♠ 9♠ Joker → Joker = 8♠ = 8 pts).
/// Ace = 1 if low (A-2-3), 11 if high (Q-K-A).
int calculateMeldPoints(List<Card> cards, GameConfig config) {
  final type = validateMeld(cards, config);
  if (type == null) {
    // Fallback: sum using penalty values
    return cards.fold(0, (sum, c) => sum + getCardPoints(c, config));
  }

  final jokers = cards.where((c) => c.isJoker).toList();
  final normals = cards.where((c) => !c.isJoker).toList();

  if (type == MeldType.set) {
    // Set: all same rank. Joker replaces that same rank.
    // Joker takes the value of the rank it replaces, not 30.
    final realCards = cards.where((c) => !c.isJoker).toList();
    final rankValue = realCards.isNotEmpty ? getCardPoints(realCards.first, config) : config.jokerValue;
    return cards.length * rankValue;
  }

  // Run: consecutive in same suit. Jokers fill gaps.
  // Determine ace interpretation (low=1 or high=14)
  final hasAce = normals.any((c) => c.rank!.value == 1);

  // To decide ace value: check which interpretation makes a valid run
  int aceValue = 1; // default low
  if (hasAce) {
    // Try as high (14) — check if other cards are in high range (10+)
    final otherValues = normals.where((c) => c.rank!.value != 1).map((c) => c.rank!.value).toList();
    if (otherValues.isNotEmpty) {
      final maxOther = otherValues.reduce((a, b) => a > b ? a : b);
      // If highest non-ace card is >= 10 (J/Q/K), ace is high
      if (maxOther >= 10) aceValue = 14;
    }
  }

  final normalValues = normals
      .map((c) => c.rank!.value == 1 ? aceValue : c.rank!.value)
      .toList()..sort();

  // Build complete sequence filling in joker positions
  final fullSequence = <int>[];
  int jokerIdx = 0;
  if (normalValues.isEmpty) {
    return cards.fold(0, (sum, c) => sum + getCardPoints(c, config));
  }

  int current = normalValues.first;
  int normalPtr = 0;
  while (fullSequence.length < cards.length) {
    if (normalPtr < normalValues.length && normalValues[normalPtr] == current) {
      fullSequence.add(current);
      normalPtr++;
    } else if (jokerIdx < jokers.length) {
      fullSequence.add(current); // Joker takes this value
      jokerIdx++;
    } else {
      break; // Safety
    }
    current++;
  }

  // Sum all values using _rankPoints
  return fullSequence.fold(0, (sum, v) => sum + _rankPoints(v, config));
}

/// Check if a card can be laid off onto an existing meld
bool canLayoff(Card card, Meld meld, String position, GameConfig config) {
  final newCards = position == 'start'
      ? [card, ...meld.cards]
      : [...meld.cards, card];

  if (meld.type == MeldType.set) return isValidSet(newCards, config);
  if (meld.type == MeldType.run) return isValidRun(newCards, config);
  return false;
}

/// Check if a card can be laid off at either end, or swap a joker
bool canLayoffAny(Card card, Meld meld, GameConfig config) {
  if (canLayoff(card, meld, 'start', config)) return true;
  if (canLayoff(card, meld, 'end', config)) return true;

  // Can it replace a joker in this meld?
  final jokers = meld.cards.where((c) => c.isJoker).toList();
  if (jokers.isNotEmpty && !card.isJoker) {
    for (final joker in jokers) {
      final idx = meld.cards.indexOf(joker);
      final testCards = List<Card>.from(meld.cards);
      testCards[idx] = card;
      if (validateMeld(testCards, config) != null) return true;
    }
  }
  return false;
}

/// A "clean run" is a Run (suite) that contains zero jokers.
bool isCleanRun(Meld meld) {
  return meld.type == MeldType.run && meld.cards.every((c) => !c.isJoker);
}

/// Check if the opening melds meet the opening requirements:
/// - Total points >= openingThreshold
/// - At least one clean run if openingRequiresCleanRun
({bool valid, int points, String? reason}) validateOpening(
  List<Meld> melds,
  GameConfig config,
) {
  final points = melds.fold<int>(
    0, (sum, m) => sum + calculateMeldPoints(m.cards, config),
  );

  if (config.openingThreshold > 0 && points < config.openingThreshold) {
    return (
      valid: false,
      points: points,
      reason: 'Il faut ${config.openingThreshold} points pour ouvrir (vous avez $points)',
    );
  }

  if (config.openingRequiresCleanRun && !melds.any((m) => isCleanRun(m))) {
    return (
      valid: false,
      points: points,
      reason: 'L\'ouverture nécessite au moins une suite sans joker',
    );
  }

  return (valid: true, points: points, reason: null);
}






