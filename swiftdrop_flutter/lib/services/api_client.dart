import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_endpoints.dart';
import 'secure_session_store.dart';

class ApiClient {
  static ApiClient? _instance;
  static const String _legacyTokenKey = 'swiftdrop_api_token';

  late final Dio _dio;
  String? _token;
  bool _tokenLoaded = false;
  bool _validatingSession = false;
  final SecureSessionStore _store = SecureSessionStore();

  /// Invoked once the server has confirmed that the stored credentials are
  /// no longer accepted (as opposed to a one-off 401 from an unrelated call).
  void Function()? onSessionInvalid;

  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!_tokenLoaded) {
            await loadToken();
          }
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // A 401 from a credential endpoint is simply a failed attempt -
          // only an authenticated endpoint rejecting us means the session
          // itself is dead.
          if (error.response?.statusCode == 401 &&
              !_isCredentialRequest(error.requestOptions.path)) {
            unawaited(_validateSession());
          }
          return handler.next(error);
        },
      ),
    );
  }

  factory ApiClient() {
    _instance ??= ApiClient._();
    return _instance!;
  }

  /// Drops the singleton so a test can start from an empty token state.
  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
  }

  Dio get dio => _dio;

  void setToken(String? token) {
    _token = token;
    _tokenLoaded = true;
  }

  /// Loads the persisted token once. Subsequent calls are no-ops so the
  /// token can never be re-read over newer in-memory state.
  Future<void> loadToken() async {
    if (_tokenLoaded) return;
    var token = await _store.read();
    if (token == null) {
      // Migrate tokens written by older builds into secure storage.
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(_legacyTokenKey);
      if (legacy != null) {
        token = legacy;
        if (await _store.write(legacy)) {
          await prefs.remove(_legacyTokenKey);
        }
      }
    }
    _token = token;
    _tokenLoaded = true;
  }

  Future<void> saveToken(String token) async {
    _token = token;
    _tokenLoaded = true;
    await _store.write(token);
  }

  Future<void> clearToken() async {
    _token = null;
    _tokenLoaded = true;
    await _store.delete();
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  bool _isCredentialRequest(String path) =>
      path.contains('/auth/login') ||
      path.contains('/auth/signup') ||
      path.contains('/auth/verify-otp') ||
      path.contains('/auth/send-otp');

  /// Re-checks the token with the server before deciding that a session is
  /// over, so a single bad response never silently logs the user out.
  Future<void> _validateSession() async {
    if (_validatingSession || _token == null) return;
    _validatingSession = true;
    try {
      await _dio.get(ApiEndpoints.me);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        await clearToken();
        onSessionInvalid?.call();
      }
    } catch (_) {
      // Network/unknown failure - keep the session and let the caller retry.
    } finally {
      _validatingSession = false;
    }
  }
}
