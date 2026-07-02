import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class PaymentService {
  final ApiClient _api = ApiClient();

  /// Initialize Paystack transaction
  Future<Map<String, dynamic>?> initialize({
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

  /// Verify payment by reference
  Future<Map<String, dynamic>?> verify(String reference) async {
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
}
