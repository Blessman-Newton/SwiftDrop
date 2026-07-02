import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class AuthService {
  static const _sessionKey = 'swiftdrop_active_session';

  final ApiClient _api = ApiClient();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Send OTP via API
  Future<bool> sendOtp(String phone) async {
    final response = await _api.dio.post(
      ApiEndpoints.sendOtp,
      data: {'phone': phone},
    );
    return response.statusCode == 200;
  }

  // Verify OTP via API
  Future<User?> verifyOtpApi(String phone, String code,
      {String? name, String role = 'customer'}) async {
    final response = await _api.dio.post(
      ApiEndpoints.verifyOtp,
      data: {
        'phone': phone,
        'code': code,
        'name': name,
        'role': role,
      },
    );
    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;
      if (token != null && userData != null) {
        await _api.saveToken(token);
        final user = User(
          uid: userData['id'] as String,
          email: userData['email'] as String? ?? '',
          displayName: userData['name'] as String?,
          phoneNumber: userData['phone'] as String?,
          avatarUrl: userData['avatar_url'] as String?,
        );
        // Persist locally too
        final p = await prefs;
        await p.setString(_sessionKey, jsonEncode(user.toMap()));
        return user;
      }
    }
    return null;
  }

  // Get current user (check API token first, then local session)
  Future<User?> getCurrentUser() async {
    await _api.loadToken();

    if (_api.isAuthenticated) {
      try {
        final response = await _api.dio.get(ApiEndpoints.me);
        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          return User(
            uid: data['id'] as String,
            email: data['email'] as String? ?? '',
            displayName: data['name'] as String?,
            phoneNumber: data['phone'] as String?,
            avatarUrl: data['avatar_url'] as String?,
          );
        }
      } on DioException catch (_) {
        // Token expired, fall through to local
      }
    }

    // Fallback: local session (only for token persistence, not auth)
    final p = await prefs;
    final sessionJson = p.getString(_sessionKey);
    if (sessionJson == null) return null;
    return User.fromMap(jsonDecode(sessionJson) as Map<String, dynamic>);
  }

  Future<void> signOut() async {
    await _api.clearToken();
    final p = await prefs;
    await p.remove(_sessionKey);
  }
}
