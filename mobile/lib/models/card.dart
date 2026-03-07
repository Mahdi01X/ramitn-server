// ─── Card Model ──────────────────────────────────────────────

enum Suit { hearts, diamonds, clubs, spades }

enum Rank {
  ace(1), two(2), three(3), four(4), five(5), six(6), seven(7),
  eight(8), nine(9), ten(10), jack(11), queen(12), king(13);

  final int value;
  const Rank(this.value);
}

class Card {
  final int id;
  final Suit? suit;
  final Rank? rank;
  final bool isJoker;
  final int deckIndex;

  const Card({
    required this.id,
    this.suit,
    this.rank,
    this.isJoker = false,
    this.deckIndex = 0,
  });

  String get display {
    if (isJoker) return '🃏';
    final rankStr = {
      Rank.ace: 'A', Rank.two: '2', Rank.three: '3', Rank.four: '4',
      Rank.five: '5', Rank.six: '6', Rank.seven: '7', Rank.eight: '8',
      Rank.nine: '9', Rank.ten: '10', Rank.jack: 'J', Rank.queen: 'Q',
      Rank.king: 'K',
    }[rank] ?? '?';
    final suitStr = {
      Suit.hearts: '♥', Suit.diamonds: '♦', Suit.clubs: '♣', Suit.spades: '♠',
    }[suit] ?? '?';
    return '$rankStr$suitStr';
  }

  bool get isRed => suit == Suit.hearts || suit == Suit.diamonds;

  factory Card.fromJson(Map<String, dynamic> json) {
    // Handle suit — server sends 'hearts', 'joker' etc.
    Suit? suit;
    final suitStr = json['suit']?.toString();
    if (suitStr != null && suitStr != 'joker') {
      suit = Suit.values.where((s) => s.name == suitStr).firstOrNull;
    }

    // Handle rank — server sends string ('A','2','J','JOKER'), local engine sends int
    Rank? rank;
    final rawRank = json['rank'];
    if (rawRank != null) {
      if (rawRank is int) {
        rank = Rank.values.where((r) => r.value == rawRank).firstOrNull;
      } else if (rawRank is String && rawRank != 'JOKER') {
        const rankMap = {
          'A': Rank.ace, '2': Rank.two, '3': Rank.three, '4': Rank.four,
          '5': Rank.five, '6': Rank.six, '7': Rank.seven, '8': Rank.eight,
          '9': Rank.nine, '10': Rank.ten, 'J': Rank.jack, 'Q': Rank.queen, 'K': Rank.king,
        };
        rank = rankMap[rawRank];
      }
    }

    return Card(
      id: json['id'] as int,
      suit: suit,
      rank: rank,
      isJoker: json['isJoker'] as bool? ?? false,
      deckIndex: json['deckIndex'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'suit': suit?.name,
    'rank': rank?.value,
    'isJoker': isJoker,
    'deckIndex': deckIndex,
  };

  @override
  bool operator ==(Object other) => other is Card && other.id == id;

  @override
  int get hashCode => id.hashCode;
}


