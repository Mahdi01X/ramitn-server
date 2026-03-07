class GameConfig {
  final int numPlayers;
  final int numJokers;
  final int cardsPerPlayer;
  final int openingThreshold;
  /// Opening must include at least one clean run (no jokers)
  final bool openingRequiresCleanRun;
  final int jokerValue;
  final int aceHighValue;
  final int maxRounds;
  final String scoringMode;
  final int eliminationThreshold;
  final bool jokerLocked;
  final int maxJokersPerMeld;
  final int turnTimeoutSeconds;

  const GameConfig({
    this.numPlayers = 4,
    this.numJokers = 4,
    this.cardsPerPlayer = 14,
    this.openingThreshold = 71,
    this.openingRequiresCleanRun = true,
    this.jokerValue = 30,
    this.aceHighValue = 11,
    this.maxRounds = 5,
    this.scoringMode = 'cumulative',
    this.eliminationThreshold = 100,
    this.jokerLocked = false,
    this.maxJokersPerMeld = 99,
    this.turnTimeoutSeconds = 30,
  });

  factory GameConfig.fromJson(Map<String, dynamic> json) {
    return GameConfig(
      numPlayers: json['numPlayers'] ?? 4,
      numJokers: json['numJokers'] ?? 4,
      cardsPerPlayer: json['cardsPerPlayer'] ?? 14,
      openingThreshold: json['openingThreshold'] ?? 71,
      openingRequiresCleanRun: json['openingRequiresCleanRun'] ?? true,
      jokerValue: json['jokerValue'] ?? 30,
      aceHighValue: json['aceHighValue'] ?? 11,
      maxRounds: json['maxRounds'] ?? 5,
      scoringMode: json['scoringMode'] ?? 'cumulative',
      eliminationThreshold: json['eliminationThreshold'] ?? 100,
      jokerLocked: json['jokerLocked'] ?? false,
      maxJokersPerMeld: json['maxJokersPerMeld'] ?? 1,
      turnTimeoutSeconds: json['turnTimeoutSeconds'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() => {
    'numPlayers': numPlayers,
    'numJokers': numJokers,
    'cardsPerPlayer': cardsPerPlayer,
    'openingThreshold': openingThreshold,
    'openingRequiresCleanRun': openingRequiresCleanRun,
    'jokerValue': jokerValue,
    'aceHighValue': aceHighValue,
    'maxRounds': maxRounds,
    'scoringMode': scoringMode,
    'eliminationThreshold': eliminationThreshold,
    'jokerLocked': jokerLocked,
    'maxJokersPerMeld': maxJokersPerMeld,
    'turnTimeoutSeconds': turnTimeoutSeconds,
  };

  GameConfig copyWith({
    int? numPlayers,
    int? numJokers,
    int? openingThreshold,
    bool? openingRequiresCleanRun,
    int? maxRounds,
    String? scoringMode,
    bool? jokerLocked,
    int? maxJokersPerMeld,
  }) {
    return GameConfig(
      numPlayers: numPlayers ?? this.numPlayers,
      numJokers: numJokers ?? this.numJokers,
      cardsPerPlayer: cardsPerPlayer,
      openingThreshold: openingThreshold ?? this.openingThreshold,
      openingRequiresCleanRun: openingRequiresCleanRun ?? this.openingRequiresCleanRun,
      jokerValue: jokerValue,
      aceHighValue: aceHighValue,
      maxRounds: maxRounds ?? this.maxRounds,
      scoringMode: scoringMode ?? this.scoringMode,
      eliminationThreshold: eliminationThreshold,
      jokerLocked: jokerLocked ?? this.jokerLocked,
      maxJokersPerMeld: maxJokersPerMeld ?? this.maxJokersPerMeld,
      turnTimeoutSeconds: turnTimeoutSeconds,
    );
  }
}


