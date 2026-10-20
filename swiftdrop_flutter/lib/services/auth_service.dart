import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_bootstrap.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'api_endpoints.dart';
import 'analytics_service.dart';
import 'fcm_service.dart';

class AuthService {
  static const _sessionKey = AppBootstrap.sessionKey;

  final ApiClient _api = ApiClient();
  late final FirebaseAuth _firebaseAuth;
  late final GoogleSignIn _googleSignIn;
  final AnalyticsService _analytics = AnalyticsService();
  final StreamController<void> _sessionExpired =
      StreamController<void>.broadcast();
  bool _closed = false;

  AuthService() {
    _firebaseAuth = FirebaseAuth.instance;
    _googleSignIn = GoogleSignIn();
    _api.onSessionInvalid = _handleInvalidSession;
  }

  /// Creates an auth service for widget tests that only exercise cached
  /// sessions and routing. It deliberately does not touch Firebase plugins.
  AuthService.test() {
    _api.onSessionInvalid = _handleInvalidSession;
  }

  Stream<void> get sessionExpired => _sessionExpired.stream;

  void _handleInvalidSession() {
    if (_closed) return;
    _sessionExpired.add(null);
  }

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
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (name != null && name.isNotEmpty) {
        await credential.user?.updateDisplayName(name.trim());
      }

      final idToken = await credential.user?.getIdToken();
      if (idToken == null)
        throw Exception('Failed to get authentication token');

      final response = await _api.dio.post(
        ApiEndpoints.signUp,
        data: {
          'email': email.trim(),
          'password': password,
          'phone': phone,
          'name': name,
          'role': role,
          'firebase_uid': credential.user?.uid,
          'id_token': idToken,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        final userData = data['user'] as Map<String, dynamic>?;
        if (token != null && userData != null) {
          _analytics.logRegistration(method: 'email');
          return await _acceptSession(token, userData);
        }
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
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
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final idToken = await credential.user?.getIdToken();
      if (idToken == null)
        throw Exception('Failed to get authentication token');

      final response = await _api.dio.post(
        ApiEndpoints.login,
        data: {
          'email': email.trim(),
          'password': password,
          'firebase_uid': credential.user?.uid,
          'id_token': idToken,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        final userData = data['user'] as Map<String, dynamic>?;
        if (token != null && userData != null) {
          _analytics.logLogin(method: 'email');
          return await _acceptSession(token, userData);
        }
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    } on DioException catch (e) {
      final detail = _extractError(e);
      throw Exception(detail);
    }
    return null;
  }

  Future<User?> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _api.dio.post(
        '/api/v1/auth/phone-login',
        data: {
          'phone': phone,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final customToken = data['custom_token'] as String?;
        final token = data['access_token'] as String?;
        final userData = data['user'] as Map<String, dynamic>?;

        if (customToken != null) {
          await _firebaseAuth.signInWithCustomToken(customToken);
        }

        if (token != null && userData != null) {
          _analytics.logLogin(method: 'phone');
          return await _acceptSession(token, userData);
        }
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    } on DioException catch (e) {
      final detail = _extractError(e);
      throw Exception(detail);
    }
    return null;
  }

  Future<User?> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null)
        throw Exception('Failed to get authentication token');

      final response = await _api.dio.post(
        '/api/v1/auth/social-login',
        data: {
          'provider': 'google',
          'id_token': idToken,
          'firebase_uid': userCredential.user?.uid,
          'email': userCredential.user?.email,
          'name': userCredential.user?.displayName,
          'photo_url': userCredential.user?.photoURL,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        final userData = data['user'] as Map<String, dynamic>?;
        if (token != null && userData != null) {
          _analytics.logLogin(method: 'google');
          return await _acceptSession(token, userData);
        }
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    } on DioException catch (e) {
      final detail = _extractError(e);
      throw Exception(detail);
    }
    return null;
  }

  Future<User?> loginWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oAuthProvider = OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null)
        throw Exception('Failed to get authentication token');

      final response = await _api.dio.post(
        '/api/v1/auth/social-login',
        data: {
          'provider': 'apple',
          'id_token': idToken,
          'firebase_uid': userCredential.user?.uid,
          'email': userCredential.user?.email,
          'name': appleCredential.givenName != null
              ? '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'
                  .trim()
              : null,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        final userData = data['user'] as Map<String, dynamic>?;
        if (token != null && userData != null) {
          _analytics.logLogin(method: 'apple');
          return await _acceptSession(token, userData);
        }
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    } on DioException catch (e) {
      final detail = _extractError(e);
      throw Exception(detail);
    }
    return null;
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    }
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
          return await _acceptSession(token, userData);
        }
      }
    } on DioException catch (e) {
      final detail = _extractError(e);
      throw Exception(detail);
    }
    return null;
  }

  Future<User> _acceptSession(
      String token, Map<String, dynamic> userData) async {
    final user = _parseUser(userData);
    await _api.saveToken(token);
    await AppBootstrap.persistSession(user, token);
    await FCMService().registerCurrentToken();
    return user;
  }

  Future<User?> getCurrentUser() async {
    await _api.loadToken();

    if (_api.isAuthenticated) {
      try {
        final response = await _api.dio.get(ApiEndpoints.me);
        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          final user = _parseUser(data);
          final p = await prefs;
          await p.setString(_sessionKey, jsonEncode(user.toMap()));
          return user;
        }
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) {
          await signOut();
          return null;
        }
        return getCachedUser();
      }
    }

    return getCachedUser();
  }

  Future<User?> getCachedUser() => AppBootstrap.readValidSession();

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
    } catch (_) {}
    await _api.clearToken();
    await AppBootstrap.clearSession();
  }

  Future<void> dispose() async {
    _closed = true;
    await _sessionExpired.close();
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

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Invalid verification ID.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  String _extractError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      return data['detail'] as String? ?? 'Something went wrong';
    }
    return 'Network error. Please try again.';
  }
}
