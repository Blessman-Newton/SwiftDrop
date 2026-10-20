import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message received: ${message.messageId}');
  debugPrint('[FCM] Data: ${message.data}');
}

class FCMService {
  static final FCMService _instance = FCMService._();
  factory FCMService() => _instance;
  FCMService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiClient _api = ApiClient();

  String? _fcmToken;
  Function(RemoteMessage)? onMessageOpenedApp;
  Function(RemoteMessage)? onForegroundMessage;

  String? get token => _fcmToken;

  Future<void> initialize() async {
    if (kIsWeb) return;

    await _requestPermissions();
    await _setupToken();
    _setupMessageHandlers();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _messaging;
      await androidImplementation.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } else if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }
  }

  Future<void> _setupToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('[FCM] Token obtained: ${_fcmToken?.substring(0, 20)}...');
      await _registerTokenWithBackend();

      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed');
        _fcmToken = newToken;
        _registerTokenWithBackend();
      });
    } catch (e) {
      debugPrint('[FCM] Failed to get token: $e');
    }
  }

  Future<void> _registerTokenWithBackend() async {
    if (_fcmToken == null) return;
    await _api.loadToken();
    if (!_api.isAuthenticated) return;

    try {
      await _api.dio.post(
        ApiEndpoints.registerNotificationToken,
        data: {'fcm_token': _fcmToken},
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('swiftdrop_fcm_token', _fcmToken!);
    } catch (e) {
      debugPrint('[FCM] Failed to register token with backend: $e');
    }
  }

  Future<void> registerCurrentToken() => _registerTokenWithBackend();

  void _setupMessageHandlers() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message: ${message.messageId}');
      if (message.data['order_id'] != null) {
        debugPrint('[FCM] Order notification: ${message.data['order_id']}');
      }
      onForegroundMessage?.call(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Message opened app: ${message.messageId}');
      onMessageOpenedApp?.call(message);
    });
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('[FCM] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[FCM] Failed to subscribe to topic $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('[FCM] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('[FCM] Failed to unsubscribe from topic $topic: $e');
    }
  }

  Map<String, dynamic>? parseNotificationData(Map<String, dynamic> data) {
    try {
      if (data['order_id'] != null) {
        return {
          'type': data['type'] ?? 'order',
          'order_id': data['order_id'],
          'status': data['status'],
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('swiftdrop_fcm_token');
      _fcmToken = null;
    } catch (e) {
      debugPrint('[FCM] Failed to delete token: $e');
    }
  }
}
