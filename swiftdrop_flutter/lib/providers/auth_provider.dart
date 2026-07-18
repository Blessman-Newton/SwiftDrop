import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final currentUserProvider =
    StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

final userRoleProvider =
    StateNotifierProvider<UserRoleNotifier, UserRole?>((ref) {
  return UserRoleNotifier();
});

class AuthNotifier extends StateNotifier<User?> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(null) {
    _init();
  }

  Future<void> _init() async {
    final user = await _authService.getCurrentUser();
    state = user;
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
      state = user;
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
      state = user;
    }
    return user;
  }

  Future<User?> loginWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    final dummyUser = User(
      uid: 'google_user_123',
      email: 'swiftdrop.user@gmail.com',
      displayName: 'Swift Customer',
      phoneNumber: '+233200000000',
      walletBalance: 150.0,
      loyaltyPoints: 120,
      membershipTier: 'Gold',
    );
    state = dummyUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('swiftdrop_active_session', jsonEncode(dummyUser.toMap()));
    return dummyUser;
  }

  Future<bool> sendOtp(String phone) async {
    await _authService.sendOtp(phone);
    return true;
  }

  Future<bool> verifyOtp(String phone, String code) async {
    final user = await _authService.verifyOtpApi(phone, code);
    if (user != null) {
      state = user;
      return true;
    }
    return false;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = null;
  }
}

class UserRoleNotifier extends StateNotifier<UserRole?> {
  static const _roleKey = 'swiftdrop_user_role';

  UserRoleNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final roleIndex = prefs.getInt(_roleKey);
    if (roleIndex != null && roleIndex < UserRole.values.length) {
      state = UserRole.values[roleIndex];
    }
  }

  Future<void> setRole(UserRole role) async {
    state = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_roleKey, role.index);
  }

  Future<void> clearRole() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
  }
}
