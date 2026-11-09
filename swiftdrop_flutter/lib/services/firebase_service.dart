
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class FirebaseService {
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      _initialized = true;
      debugPrint('[FirebaseService] Firebase initialized successfully');
      return true;
    } catch (error, stackTrace) {
      debugPrint('[FirebaseService] Firebase initialization failed: $error');
      debugPrint('$stackTrace');
      return false;
    }
  }
}
