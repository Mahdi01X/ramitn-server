import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket_service.dart';
import 'game_provider.dart';

// ─── Room State ──────────────────────────────────────────────

class RoomState {
  final String? roomCode;
  final String? roomId;
  final int numPlayers;
  final List<RoomPlayerInfo> players;
  final List<ChatMessage> messages;
  final bool isInRoom;
  final bool gameStarted;
  final String? error;

  const RoomState({
    this.roomCode,
    this.roomId,
    this.numPlayers = 2,
    this.players = const [],
    this.messages = const [],
    this.isInRoom = false,
    this.gameStarted = false,
    this.error,
  });

  RoomState copyWith({
    String? roomCode,
    String? roomId,
    int? numPlayers,
    List<RoomPlayerInfo>? players,
    List<ChatMessage>? messages,
    bool? isInRoom,
    bool? gameStarted,
    String? error,
  }) => RoomState(
    roomCode: roomCode ?? this.roomCode,
    roomId: roomId ?? this.roomId,
    numPlayers: numPlayers ?? this.numPlayers,
    players: players ?? this.players,
    messages: messages ?? this.messages,
    isInRoom: isInRoom ?? this.isInRoom,
    gameStarted: gameStarted ?? this.gameStarted,
    error: error,
  );
}

class RoomPlayerInfo {
  final String id;
  final String name;
  final bool ready;

  const RoomPlayerInfo({required this.id, required this.name, this.ready = false});
}

class ChatMessage {
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;

  const ChatMessage({
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
  });
}

// ─── Room Notifier ───────────────────────────────────────────

class RoomNotifier extends StateNotifier<RoomState> {
  final SocketService _socket;
  final List<StreamSubscription> _subs = [];

  RoomNotifier(this._socket) : super(const RoomState()) {
    _listen();
  }

  void _listen() {
    _subs.add(_socket.on('room_created').listen((data) {
      final List<RoomPlayerInfo> players = (data['players'] as List?)
          ?.map<RoomPlayerInfo>((p) => RoomPlayerInfo(id: p['id'], name: p['name'], ready: p['ready'] ?? false))
          .toList() ?? <RoomPlayerInfo>[];
      state = state.copyWith(
        roomCode: data['roomCode'],
        roomId: data['roomId'],
        numPlayers: data['numPlayers'] ?? 2,
        players: players,
        isInRoom: true,
        error: null,
      );
    }));

    _subs.add(_socket.on('room_joined').listen((data) {
      final List<RoomPlayerInfo> players = (data['players'] as List)
          .map<RoomPlayerInfo>((p) => RoomPlayerInfo(id: p['id'], name: p['name'], ready: p['ready'] ?? false))
          .toList();
      state = state.copyWith(
        roomCode: data['roomCode'],
        numPlayers: data['numPlayers'] ?? players.length,
        players: players,
        isInRoom: true,
        error: null,
      );
    }));

    _subs.add(_socket.on('player_joined').listen((data) {
      // Server sends full players list — use it if available
      if (data['players'] != null) {
        final List<RoomPlayerInfo> players = (data['players'] as List)
            .map<RoomPlayerInfo>((p) => RoomPlayerInfo(id: p['id'], name: p['name'], ready: p['ready'] ?? false))
            .toList();
        state = state.copyWith(players: players);
      } else {
        // Fallback: add single player if not already present
        final exists = state.players.any((p) => p.id == data['playerId']);
        if (!exists) {
          state = state.copyWith(players: [
            ...state.players,
            RoomPlayerInfo(id: data['playerId'], name: data['playerName']),
          ]);
        }
      }
    }));

    _subs.add(_socket.on('player_left').listen((data) {
      if (data['players'] != null) {
        final List<RoomPlayerInfo> players = (data['players'] as List)
            .map<RoomPlayerInfo>((p) => RoomPlayerInfo(id: p['id'], name: p['name'], ready: p['ready'] ?? false))
            .toList();
        state = state.copyWith(players: players);
      } else {
        final updated = state.players.where((p) => p.id != data['playerId']).toList();
        state = state.copyWith(players: updated);
      }
    }));

    _subs.add(_socket.on('player_ready').listen((data) {
      if (data['players'] != null) {
        final List<RoomPlayerInfo> players = (data['players'] as List)
            .map<RoomPlayerInfo>((p) => RoomPlayerInfo(id: p['id'], name: p['name'], ready: p['ready'] ?? false))
            .toList();
        state = state.copyWith(players: players);
      } else {
        final updated = state.players.map((p) {
          if (p.id == data['playerId']) return RoomPlayerInfo(id: p.id, name: p.name, ready: data['ready'] ?? true);
          return p;
        }).toList();
        state = state.copyWith(players: updated);
      }
    }));

    _subs.add(_socket.on('game_started').listen((_) {
      state = state.copyWith(gameStarted: true);
    }));

    _subs.add(_socket.on('chat_broadcast').listen((data) {
      final msg = ChatMessage(
        senderId: data['senderId'],
        senderName: data['senderName'],
        message: data['message'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
      );
      state = state.copyWith(messages: [...state.messages, msg]);
    }));

    _subs.add(_socket.on('game_error').listen((data) {
      state = state.copyWith(error: data['message']);
    }));
  }

  void reset() {
    state = const RoomState();
  }

  /// Generate a room code locally (no server needed).
  /// The organizer sees it immediately and can share it.
  String createLocalRoom(String creatorId, String creatorName) {
    final code = _generateCode();
    state = RoomState(
      roomCode: code,
      roomId: 'local_$code',
      players: [RoomPlayerInfo(id: creatorId, name: creatorName, ready: false)],
      isInRoom: true,
    );
    return code;
  }

  /// Join a local room by code (simulated — for when server is not available).
  void joinLocalRoom(String code, String playerId, String playerName) {
    state = state.copyWith(
      roomCode: code,
      isInRoom: true,
      players: [
        ...state.players,
        RoomPlayerInfo(id: playerId, name: playerName, ready: false),
      ],
    );
  }

  /// Toggle ready for a specific player (local mode).
  void setLocalReady(String playerId) {
    final updated = state.players.map((p) {
      if (p.id == playerId) return RoomPlayerInfo(id: p.id, name: p.name, ready: !p.ready);
      return p;
    }).toList();
    state = state.copyWith(players: updated);
  }

  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return String.fromCharCodes(
      Iterable.generate(5, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
    );
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }
}

// ─── Provider ────────────────────────────────────────────────

final roomProvider = StateNotifierProvider<RoomNotifier, RoomState>((ref) {
  final socket = ref.watch(socketServiceProvider);
  return RoomNotifier(socket);
});






