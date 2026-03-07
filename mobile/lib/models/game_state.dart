import 'card.dart';
import 'meld.dart';
import 'game_config.dart';

// ─── Player (sanitized view from server) ─────────────────────

class PlayerInfo {
  final String id;
  final String name;
  final int handCount;
  final List<Meld> melds;
  final int totalScore;
  final bool hasOpened;
  final int openingScore;
  final bool isBot;
  final bool isConnected;

  const PlayerInfo({
    required this.id,
    required this.name,
    required this.handCount,
    required this.melds,
    required this.totalScore,
    required this.hasOpened,
    this.openingScore = 0,
    required this.isBot,
    required this.isConnected,
  });

  factory PlayerInfo.fromJson(Map<String, dynamic> json) {
    return PlayerInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      handCount: json['handCount'] as int? ?? 0,
      melds: (json['melds'] as List?)?.map((m) => Meld.fromJson(m)).toList() ?? [],
      totalScore: json['totalScore'] as int? ?? 0,
      hasOpened: json['hasOpened'] as bool? ?? false,
      openingScore: json['openingScore'] as int? ?? 0,
      isBot: json['isBot'] as bool? ?? false,
      isConnected: json['isConnected'] as bool? ?? true,
    );
  }
}

// ─── Game State (sanitized, as received from server) ─────────

class GameState {
  final String id;
  final String phase; // waiting, dealing, player_turn, round_end, game_end
  final String turnStep; // draw, play
  final int currentPlayerIndex;
  final List<PlayerInfo> players;
  final List<Card> myHand;
  final int drawPileCount;
  final List<Card> discardPile;
  final List<Meld> tableMelds;
  final int round;
  final int turnCount;
  final GameConfig config;

  const GameState({
    required this.id,
    required this.phase,
    required this.turnStep,
    required this.currentPlayerIndex,
    required this.players,
    required this.myHand,
    required this.drawPileCount,
    required this.discardPile,
    required this.tableMelds,
    required this.round,
    required this.turnCount,
    required this.config,
  });

  bool get isMyTurn => false; // Set by provider using current user ID

  PlayerInfo? get currentPlayer =>
      currentPlayerIndex < players.length ? players[currentPlayerIndex] : null;

  Card? get topDiscard => discardPile.isNotEmpty ? discardPile.last : null;

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      id: json['id'] as String,
      phase: json['phase'] as String,
      turnStep: json['turnStep'] as String,
      currentPlayerIndex: json['currentPlayerIndex'] as int,
      players: (json['players'] as List).map((p) => PlayerInfo.fromJson(p)).toList(),
      myHand: (json['myHand'] as List).map((c) => Card.fromJson(c)).toList(),
      drawPileCount: json['drawPileCount'] as int,
      discardPile: (json['discardPile'] as List).map((c) => Card.fromJson(c)).toList(),
      tableMelds: (json['tableMelds'] as List).map((m) => Meld.fromJson(m)).toList(),
      round: json['round'] as int,
      turnCount: json['turnCount'] as int,
      config: GameConfig.fromJson(json['config'] as Map<String, dynamic>),
    );
  }
}

