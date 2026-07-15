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

  Future<User?> signUp({
    required String email,
    required String password,
    required String phone,
    String? name,
    String role = 'customer',
  }) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.signUp,
        data: {
          'email': email,
          'password': password,
          'phone': phone,
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
          final user = _parseUser(userData);
          final p = await prefs;
          await p.setString(_sessionKey, jsonEncode(user.toMap()));
          return user;
        }
      }
    } on DioException catch (e) {
      final detail = _extractError(e);
      throw Exception(detail);
    }
    return null;
  }

  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        final userData = data['user'] as Map<String, dynamic>?;
        if (token != null && userData != null) {
          await _api.saveToken(token);
          final user = _parseUser(userData);
          final p = await prefs;
          await p.setString(_sessionKey, jsonEncode(user.toMap()));
          return user;
        }
      }
    } on DioException catch (e) {
      final detail = _extractError(e);
      throw Exception(detail);
    }
    return null;
  }

  Future<bool> sendOtp(String phone) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.sendOtp,
        data: {'phone': phone},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      final detail = _extractError(e);
      throw Exception(detail);
    }
  }

  Future<User?> verifyOtpApi(String phone, String code) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.verifyOtp,
        data: {
          'phone': phone,
          'code': code,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        final userData = data['user'] as Map<String, dynamic>?;
        if (token != null && userData != null) {
          await _api.saveToken(token);
          final user = _parseUser(userData);
          final p = await prefs;
          await p.setString(_sessionKey, jsonEncode(user.toMap()));
          return user;
        }
      }
    } on DioException catch (e) {
      final detail = _extractError(e);
      throw Exception(detail);
    }
    return null;
  }

  Future<User?> getCurrentUser() async {
    await _api.loadToken();

    if (_api.isAuthenticated) {
      try {
        final response = await _api.dio.get(ApiEndpoints.me);
        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          return _parseUser(data);
        }
      } on DioException catch (_) {
      }
    }

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

  User _parseUser(Map<String, dynamic> data) {
    return User(
      uid: data['id'] as String,
      email: data['email'] as String? ?? '',
      displayName: data['name'] as String?,
      phoneNumber: data['phone'] as String?,
      avatarUrl: data['avatar_url'] as String?,
      walletBalance: (data['wallet_balance'] as num?)?.toDouble() ?? 0.0,
      loyaltyPoints: data['loyalty_points'] as int? ?? 0,
      membershipTier: data['membership_tier'] as String? ?? 'Bronze',
    );
  }

  String _extractError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      return data['detail'] as String? ?? 'Something went wrong';
    }
    return 'Network error. Please try again.';
  }
}
