import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AuthService {
  static const _usersKey = 'swiftdrop_users';
  static const _sessionKey = 'swiftdrop_active_session';
  static const _demoEmail = 'hello@swiftdrop.com';
  static const _demoPassword = 'password';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<User?> getCurrentUser() async {
    final p = await prefs;
    final sessionJson = p.getString(_sessionKey);
    if (sessionJson == null) return null;
    return User.fromMap(jsonDecode(sessionJson) as Map<String, dynamic>);
  }

  Future<User?> signIn(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    final p = await prefs;
    final usersJson = p.getString(_usersKey);
    final users = usersJson != null
        ? (jsonDecode(usersJson) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    final match = users.where(
      (u) => u['email'] == email && u['password'] == password,
    );

    if (match.isNotEmpty) {
      final user = User.fromMap(match.first);
      await p.setString(_sessionKey, jsonEncode(user.toMap()));
      return user;
    }

    if (email == _demoEmail && password == _demoPassword) {
      const user = User(
        uid: 'user_demo',
        email: _demoEmail,
        displayName: 'Swift User',
        phoneNumber: '+1 (555) 123-4567',
        avatarUrl: null,
      );
      await p.setString(_sessionKey, jsonEncode(user.toMap()));
      return user;
    }

    return null;
  }

  Future<User?> signUp(String name, String email, String phone, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    final p = await prefs;
    final usersJson = p.getString(_usersKey);
    final users = usersJson != null
        ? (jsonDecode(usersJson) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    if (users.any((u) => u['email'] == email)) return null;

    final user = User(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: name,
      phoneNumber: phone,
    );

    final userData = {...user.toMap(), 'password': password};
    users.add(userData);
    await p.setString(_usersKey, jsonEncode(users));
    await p.setString(_sessionKey, jsonEncode(user.toMap()));
    return user;
  }

  Future<void> signOut() async {
    final p = await prefs;
    await p.remove(_sessionKey);
  }

  Future<bool> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  Future<bool> verifyOtp(String code) async {
    await Future.delayed(const Duration(seconds: 1));
    return code.length == 4;
  }
}
