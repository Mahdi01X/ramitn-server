import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.serverUrl));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  String? _userId;
  String? _displayName;
  bool _isGuest = false;

  String? get token => _token;
  String? get userId => _userId;
  String? get displayName => _displayName;
  bool get isGuest => _isGuest;
  bool get isLoggedIn => _token != null;

  Future<void> init() async {
    _token = await _storage.read(key: 'token');
    _userId = await _storage.read(key: 'userId');
    _displayName = await _storage.read(key: 'displayName');
    _isGuest = (await _storage.read(key: 'isGuest')) == 'true';
  }

  Future<void> register(String email, String password, String displayName) async {
    final res = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
    await _saveAuth(res.data);
  }

  Future<void> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    await _saveAuth(res.data);
  }

  Future<void> guestLogin({String? displayName}) async {
    final res = await _dio.post('/auth/guest', data: {
      'displayName': displayName,
    });
    await _saveAuth(res.data);
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _displayName = null;
    _isGuest = false;
    await _storage.deleteAll();
  }

  Future<void> _saveAuth(Map<String, dynamic> data) async {
    _token = data['token'] as String;
    _userId = data['user']['id'] as String;
    _displayName = data['user']['displayName'] as String;
    _isGuest = data['user']['isGuest'] as bool;

    await _storage.write(key: 'token', value: _token);
    await _storage.write(key: 'userId', value: _userId);
    await _storage.write(key: 'displayName', value: _displayName);
    await _storage.write(key: 'isGuest', value: _isGuest.toString());
  }
}

