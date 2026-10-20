import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/models.dart';
import 'services/api_client.dart';

/// How long a signed-in session may live on this device (~one month).
const Duration kSessionLifetime = Duration(days: 30);

/// Routes that are never remembered as "the screen the user was on" and are
/// always allowed through the router redirect untouched.
const Set<String> kTransientLocations = {
  '/splash',
  '/onboarding',
  '/role-selection',
  '/auth',
};

/// Everything the application must know *before* the first frame is drawn.
///
/// `main()` awaits [AppBootstrap.load] ahead of `runApp`, so the very first
/// router redirect already sees the persisted session, role, onboarding flag
/// and last location. Without this the providers started out empty and async
/// while the router had already made its decision - which is what used to
/// bounce returning users onto the splash / login screens after the OS
/// recycled the process.
class AppBootstrap {
  AppBootstrap._({
    required this.onboardingDone,
    required this.role,
    required this.user,
    required this.apiToken,
    required this.lastLocation,
    required this.sessionExpiresAt,
  });

  final bool onboardingDone;
  final UserRole? role;
  final User? user;
  final String? apiToken;
  final String? lastLocation;
  final DateTime? sessionExpiresAt;

  static const String onboardingKey = 'swiftdrop_onboarding_done';
  static const String roleKey = 'swiftdrop_user_role';
  static const String sessionKey = 'swiftdrop_active_session';
  static const String sessionExpiryKey = 'swiftdrop_session_expires_at';
  static const String sessionExpectsTokenKey = 'swiftdrop_session_expects_token';
  static const String lastLocationKey = 'swiftdrop_last_location';

  static AppBootstrap? _loaded;
  static AppBootstrap? _fallback;
  static String? _lastRemembered;
  static Future<void> _locationWrites = Future<void>.value();

  /// The snapshot taken at launch. Falls back to an "empty" snapshot so that
  /// entry points which never call [load] (unit tests, tooling) still work.
  static AppBootstrap get current => _loaded ?? (_fallback ??= _empty());

  static bool get isLoaded => _loaded != null;

  /// Clears every cached piece of launch state so a test can seed
  /// [SharedPreferences] and call [load] again.
  @visibleForTesting
  static void resetForTesting() {
    _loaded = null;
    _fallback = null;
    _lastRemembered = null;
    _locationWrites = Future<void>.value();
  }

  static AppBootstrap _empty() => AppBootstrap._(
        onboardingDone: false,
        role: null,
        user: null,
        apiToken: null,
        lastLocation: null,
        sessionExpiresAt: null,
      );

  /// Loads and validates the persisted state. Safe to call more than once.
  static Future<AppBootstrap> load() async {
    final prefs = await SharedPreferences.getInstance();
    final api = ApiClient();
    await api.loadToken();

    User? user;
    var token = api.token;
    var expires = _readExpiry(prefs);

    final sessionJson = prefs.getString(sessionKey);
    if (sessionJson != null) {
      try {
        user = User.fromMap(jsonDecode(sessionJson) as Map<String, dynamic>);
      } catch (_) {
        user = null;
      }
    }

    // The token is authoritative for how long the server will honour us.
    final jwtExpiry = token == null ? null : decodeJwtExpiry(token);
    if (jwtExpiry != null && (expires == null || jwtExpiry.isBefore(expires))) {
      expires = jwtExpiry;
    }

    final now = DateTime.now().toUtc();
    // Sessions created without a token (the Google demo sign-in) are allowed
    // to live without credentials; everything else is not.
    final expectsToken =
        prefs.getBool(sessionExpectsTokenKey) ?? (token != null);
    final expired = user != null && expires != null && !expires.isAfter(now);

    if (user != null && expired) {
      user = null;
      token = null;
      expires = null;
      await _dropCredentials(api, prefs);
    } else if (user != null && expectsToken && token == null) {
      // The session was created with credentials but they are gone (restored
      // from a backup without the matching keystore, keystore wiped, ...).
      user = null;
      expires = null;
      await _dropCredentials(api, prefs);
    } else {
      if (user != null && expires == null) {
        // Session written by an older build: give it a full window and
        // remember it so it cannot roll forward forever.
        expires = now.add(kSessionLifetime);
        await prefs.setInt(sessionExpiryKey, expires.millisecondsSinceEpoch);
      }
      // A token without a matching cached user is unusable - drop it so the
      // app does not run around with credentials it can never act on.
      if (user == null && token != null) {
        token = null;
        await api.clearToken();
      }
    }

    final roleIndex = prefs.getInt(roleKey);
    final role = (roleIndex != null &&
            roleIndex >= 0 &&
            roleIndex < UserRole.values.length)
        ? UserRole.values[roleIndex]
        : null;

    final lastLocation = prefs.getString(lastLocationKey);
    _lastRemembered = lastLocation;

    final bootstrap = AppBootstrap._(
      onboardingDone: prefs.getBool(onboardingKey) ?? false,
      role: role,
      user: user,
      apiToken: token,
      lastLocation: lastLocation,
      sessionExpiresAt: expires,
    );
    _loaded = bootstrap;
    return bootstrap;
  }

  /// Where the router should start so a warm/cold restart lands the user
  /// back where they were instead of on the splash screen.
  String get initialLocation {
    if (!onboardingDone) return '/splash';
    final location = lastLocation;
    if (location == null || location.isEmpty || location == '/splash') {
      return '/splash';
    }
    return location;
  }

  /// Remembers the screen the user is on so it can be restored after the
  /// process is recycled. Writes are serialised and de-duplicated.
  static void rememberLocation(String location) {
    if (location.isEmpty) return;
    if (kTransientLocations.contains(location)) return;
    if (location == _lastRemembered) return;
    _lastRemembered = location;
    _locationWrites = _locationWrites.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(lastLocationKey, location);
    });
  }

  /// Persists a freshly issued session together with its expiry.
  static Future<void> persistSession(User user, String? token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(sessionKey, jsonEncode(user.toMap()));
    await prefs.setInt(
      sessionExpiryKey,
      _expiryFor(token).millisecondsSinceEpoch,
    );
    await prefs.setBool(sessionExpectsTokenKey, token != null);
  }

  /// Removes the session, its expiry and the remembered location. Leaves the
  /// onboarding/role choices alone - those are preferences, not credentials.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(sessionKey);
    await prefs.remove(sessionExpiryKey);
    await prefs.remove(sessionExpectsTokenKey);
    await prefs.remove(lastLocationKey);
    _lastRemembered = null;
  }

  static Future<void> _dropCredentials(
    ApiClient api,
    SharedPreferences prefs,
  ) async {
    await api.clearToken();
    await prefs.remove(sessionKey);
    await prefs.remove(sessionExpiryKey);
    await prefs.remove(sessionExpectsTokenKey);
  }

  /// Returns the cached user only while its session is still valid.
  static Future<User?> readValidSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(sessionKey);
    if (sessionJson == null) return null;
    try {
      final user =
          User.fromMap(jsonDecode(sessionJson) as Map<String, dynamic>);
      final expiry = _readExpiry(prefs);
      if (expiry != null && !expiry.isAfter(DateTime.now().toUtc())) {
        return null;
      }
      return user;
    } catch (_) {
      return null;
    }
  }

  static DateTime? _readExpiry(SharedPreferences prefs) {
    final ms = prefs.getInt(sessionExpiryKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  static DateTime _expiryFor(String? token) {
    final now = DateTime.now().toUtc();
    final latest = now.add(kSessionLifetime);
    final jwt = token == null ? null : decodeJwtExpiry(token);
    if (jwt == null || !jwt.isAfter(now)) return latest;
    return jwt.isBefore(latest) ? jwt : latest;
  }

  /// Decodes the `exp` claim of a JWT without verifying the signature - the
  /// server remains the authority, this only lets the client avoid keeping a
  /// dead session around offline.
  static DateTime? decodeJwtExpiry(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic>) return null;
      final exp = payload['exp'];
      if (exp is! num) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000,
          isUtc: true);
    } catch (_) {
      return null;
    }
  }
}
