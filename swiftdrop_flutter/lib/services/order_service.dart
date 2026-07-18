import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class OrderService {
  final ApiClient _api = ApiClient();

  /// Create an order via API
  Future<Map<String, dynamic>?> createOrder({
    required String orderType,
    String? restaurantName,
    required String pickupAddress,
    double? pickupLat,
    double? pickupLng,
    required String deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
    required double subtotal,
    required double deliveryFee,
    required double tax,
    double discount = 0,
    required double total,
    String? promoCode,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.orders,
        data: {
          'order_type': orderType,
          'restaurant_name': restaurantName,
          'pickup_address': pickupAddress,
          'pickup_lat': pickupLat,
          'pickup_lng': pickupLng,
          'delivery_address': deliveryAddress,
          'delivery_lat': deliveryLat,
          'delivery_lng': deliveryLng,
          'subtotal': subtotal,
          'delivery_fee': deliveryFee,
          'tax': tax,
          'discount': discount,
          'total': total,
          'promo_code': promoCode,
          'items': items ?? [],
        },
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (_) {
      return null;
    }
  }

  /// List my orders
  Future<List<Map<String, dynamic>>> listOrders() async {
    try {
      final response = await _api.dio.get(ApiEndpoints.orders);
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
      return [];
    } on DioException catch (_) {
      return [];
    }
  }

  /// Get order detail
  Future<Map<String, dynamic>?> getOrder(String orderId) async {
    try {
      final response = await _api.dio.get(ApiEndpoints.orderById(orderId));
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (_) {
      return null;
    }
  }

  /// Cancel order
  Future<Map<String, dynamic>?> cancelOrder(String orderId) async {
    try {
      final response = await _api.dio.patch(ApiEndpoints.cancelOrder(orderId));
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (_) {
      return null;
    }
  }

  /// Initialize payment
  Future<Map<String, dynamic>?> initializePayment({
    required String orderId,
    required String email,
    required double amount,
    String currency = 'GHS',
  }) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.initializePayment,
        data: {
          'order_id': orderId,
          'email': email,
          'amount': amount,
          'currency': currency,
        },
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (_) {
      return null;
    }
  }

  /// Verify payment
  Future<Map<String, dynamic>?> verifyPayment(String reference) async {
    try {
      final response = await _api.dio.get(ApiEndpoints.verifyPayment(reference));
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (_) {
      return null;
    }
  }

  /// Trigger mock payment callback for Pay For Me
  Future<bool> triggerMockPaymentCallback(String orderId) async {
    try {
      final response = await _api.dio.post('/api/v1/payments/mock-callback/$orderId');
      return response.statusCode == 200;
    } on DioException catch (_) {
      return false;
    }
  }
}
