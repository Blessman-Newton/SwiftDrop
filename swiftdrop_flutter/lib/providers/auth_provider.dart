import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_bootstrap.dart';
import '../models/models.dart';
import '../services/auth_service.dart';

class RouterRefresh extends ChangeNotifier {
  void bump() => notifyListeners();
}

final routerRefreshProvider = Provider<RouterRefresh>((ref) {
  final refresh = RouterRefresh();
  ref.onDispose(refresh.dispose);
  return refresh;
});

final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService();
  ref.onDispose(service.dispose);
  return service;
});

final currentUserProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(routerRefreshProvider),
  );
});

final userRoleProvider =
    StateNotifierProvider<UserRoleNotifier, UserRole?>((ref) {
  return UserRoleNotifier(ref.watch(routerRefreshProvider));
});

class AuthNotifier extends StateNotifier<User?> {
  final AuthService _authService;
  final RouterRefresh _routerRefresh;
  StreamSubscription<void>? _sessionSub;

  AuthNotifier(this._authService, this._routerRefresh)
      : super(AppBootstrap.current.user) {
    _sessionSub = _authService.sessionExpired.listen((_) => _expireSession());
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    super.dispose();
  }

  void _set(User? user) {
    state = user;
    _routerRefresh.bump();
  }

  void _expireSession() {
    if (!mounted) return;
    state = null;
    _routerRefresh.bump();
  }

  Future<void> refreshFromApi() async {
    final user = await _authService.getCurrentUser();
    if (!mounted) return;
    if (user == null && state == null) return;
    _set(user);
  }

  Future<User?> signUp({
    required String email,
    required String password,
    required String phone,
    String? name,
    String role = 'customer',
  }) async {
    final user = await _authService.signUp(
      email: email,
      password: password,
      phone: phone,
      name: name,
      role: role,
    );
    if (user != null) {
      _set(user);
    }
    return user;
  }

  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final user = await _authService.loginWithEmail(
      email: email,
      password: password,
    );
    if (user != null) {
      _set(user);
    }
    return user;
  }

  Future<User?> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    final user = await _authService.loginWithPhone(
      phone: phone,
      password: password,
    );
    if (user != null) {
      _set(user);
    }
    return user;
  }

  Future<User?> loginWithGoogle() async {
    final user = await _authService.loginWithGoogle();
    if (user != null) {
      _set(user);
    }
    return user;
  }

  Future<User?> loginWithApple() async {
    final user = await _authService.loginWithApple();
    if (user != null) {
      _set(user);
    }
    return user;
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    return await _authService.sendPasswordResetEmail(email);
  }

  Future<bool> sendOtp(String phone) async {
    await _authService.sendOtp(phone);
    return true;
  }

  Future<bool> verifyOtp(String phone, String code) async {
    final user = await _authService.verifyOtpApi(phone, code);
    if (user != null) {
      _set(user);
      return true;
    }
    return false;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    state = null;
    _routerRefresh.bump();
  }
}

class UserRoleNotifier extends StateNotifier<UserRole?> {
  final RouterRefresh _routerRefresh;

  UserRoleNotifier(this._routerRefresh) : super(AppBootstrap.current.role);

  Future<void> setRole(UserRole role) async {
    state = role;
    _routerRefresh.bump();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppBootstrap.roleKey, role.index);
  }

  Future<void> clearRole() async {
    state = null;
    _routerRefresh.bump();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppBootstrap.roleKey);
  }
}
