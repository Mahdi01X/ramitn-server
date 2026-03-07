import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// ─── Auth State ──────────────────────────────────────────────

class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final String? userId;
  final String? displayName;
  final bool isGuest;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.userId,
    this.displayName,
    this.isGuest = false,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    String? userId,
    String? displayName,
    bool? isGuest,
    String? error,
  }) => AuthState(
    isLoading: isLoading ?? this.isLoading,
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    userId: userId ?? this.userId,
    displayName: displayName ?? this.displayName,
    isGuest: isGuest ?? this.isGuest,
    error: error,
  );
}

// ─── Auth Notifier ───────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthState());

  Future<void> init() async {
    await _service.init();
    if (_service.isLoggedIn) {
      state = AuthState(
        isLoggedIn: true,
        userId: _service.userId,
        displayName: _service.displayName,
        isGuest: _service.isGuest,
      );
    }
  }

  Future<void> register(String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.register(email, password, displayName);
      state = AuthState(
        isLoggedIn: true,
        userId: _service.userId,
        displayName: _service.displayName,
        isGuest: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.login(email, password);
      state = AuthState(
        isLoggedIn: true,
        userId: _service.userId,
        displayName: _service.displayName,
        isGuest: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> guestLogin({String? displayName}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.guestLogin(displayName: displayName);
      state = AuthState(
        isLoggedIn: true,
        userId: _service.userId,
        displayName: _service.displayName,
        isGuest: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AuthState();
  }

  String? get token => _service.token;
}

// ─── Providers ───────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthNotifier(service);
});

