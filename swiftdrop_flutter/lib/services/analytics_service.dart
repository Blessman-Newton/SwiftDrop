import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  FirebaseAnalytics? _analytics;
  bool _enabled = false;

  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);
      _enabled = true;
      debugPrint('[Analytics] Initialized successfully');
    } catch (e) {
      debugPrint('[Analytics] Failed to initialize: $e');
    }
  }

  Future<void> logRegistration({required String method}) async {
    if (!_enabled) return;
    try {
      await _analytics?.logSignUp(signUpMethod: method);
    } catch (_) {}
  }

  Future<void> logLogin({required String method}) async {
    if (!_enabled) return;
    try {
      await _analytics?.logLogin(loginMethod: method);
    } catch (_) {}
  }

  Future<void> logRestaurantView({required String restaurantId, required String restaurantName}) async {
    if (!_enabled) return;
    try {
      await _analytics?.logViewItem(
        items: [AnalyticsEventItem(itemId: restaurantId, itemName: restaurantName, itemCategory: 'restaurant')],
      );
    } catch (_) {}
  }

  Future<void> logAddToCart({required String itemId, required String itemName, required double price}) async {
    if (!_enabled) return;
    try {
      await _analytics?.logAddToCart(
        items: [AnalyticsEventItem(itemId: itemId, itemName: itemName, price: price)],
      );
    } catch (_) {}
  }

  Future<void> logCheckout({required double total, required String currency}) async {
    if (!_enabled) return;
    try {
      await _analytics?.logBeginCheckout(
        value: total,
        currency: currency,
      );
    } catch (_) {}
  }

  Future<void> logOrderPlaced({required String orderId, required double total, required String currency}) async {
    if (!_enabled) return;
    try {
      await _analytics?.logPurchase(
        transactionId: orderId,
        value: total,
        currency: currency,
      );
    } catch (_) {}
  }

  Future<void> logOrderCompleted({required String orderId}) async {
    if (!_enabled) return;
    try {
      await _analytics?.logEvent(
        name: 'order_completed',
        parameters: {'order_id': orderId},
      );
    } catch (_) {}
  }

  Future<void> logScreenView({required String screenName}) async {
    if (!_enabled) return;
    try {
      await _analytics?.logScreenView(screenName: screenName);
    } catch (_) {}
  }

  Future<void> setUserProperty({required String name, required String value}) async {
    if (!_enabled) return;
    try {
      await _analytics?.setUserProperty(name: name, value: value);
    } catch (_) {}
  }
}
