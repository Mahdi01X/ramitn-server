import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants.dart';

typedef EventCallback = void Function(dynamic data);

class SocketService {
  io.Socket? _socket;
  final _eventControllers = <String, StreamController<dynamic>>{};
  bool _isConnected = false;
  String? _playerId;
  String? _playerName;

  bool get isConnected => _isConnected;
  String? get playerId => _playerId;

  /// Connect to the WebSocket server (no JWT needed — just pseudo)
  void connect(String playerName, {String? playerId}) {
    disconnect(); // Clean any previous connection

    _playerName = playerName;
    _playerId = playerId ?? 'p_${DateTime.now().millisecondsSinceEpoch}';

    final url = '${AppConstants.serverUrl}${AppConstants.wsNamespace}';
    print('🔌 Connecting to $url as $_playerName...');

    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionAttempts(10)
          .setExtraHeaders({
            'ngrok-skip-browser-warning': 'true', // bypass ngrok free warning page
          })
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      print('🔌 Socket connected! Registering...');
      // Register with the server (no JWT — just send pseudo)
      _socket!.emit('register', {
        'name': _playerName,
        'playerId': _playerId,
      });
    });

    _socket!.on('registered', (data) {
      _playerId = data['playerId'];
      _playerName = data['playerName'];
      print('✅ Registered as $_playerName ($_playerId)');
      _getController('registered').add(data);
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      print('🔌 Socket disconnected');
    });

    _socket!.onConnectError((error) {
      print('🔌 Connection error: $error');
      _getController('connect_error').add(error);
    });

    _socket!.onError((error) {
      print('🔌 Socket error: $error');
    });

    // Listen for all game events
    for (final event in _serverEvents) {
      _socket!.on(event, (data) {
        _getController(event).add(data);
      });
    }
  }

  /// Connect with a token (legacy — for NestJS server with JWT)
  void connectWithToken(String token) {
    disconnect();

    _socket = io.io(
      '${AppConstants.serverUrl}${AppConstants.wsNamespace}',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      print('🔌 Socket connected (JWT)');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
    });

    for (final event in _serverEvents) {
      _socket!.on(event, (data) {
        _getController(event).add(data);
      });
    }
  }

  /// Disconnect
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  /// Send an event
  void emit(String event, [dynamic data]) {
    if (_socket == null) {
      print('⚠️ Socket not connected, cannot emit $event');
      return;
    }
    _socket!.emit(event, data);
  }

  /// Listen to a specific event
  Stream<dynamic> on(String event) {
    return _getController(event).stream;
  }

  StreamController<dynamic> _getController(String event) {
    return _eventControllers.putIfAbsent(
      event,
      () => StreamController<dynamic>.broadcast(),
    );
  }

  static const _serverEvents = [
    'room_created',
    'room_joined',
    'player_joined',
    'player_left',
    'player_ready',
    'game_started',
    'game_state_update',
    'game_error',
    'chat_broadcast',
    'round_end',
    'game_end',
    'meld_staged',
    'staging_cancelled',
    'matchmaking_waiting',
    'connect_error',
  ];
}


