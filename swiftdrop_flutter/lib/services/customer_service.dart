import 'package:dio/dio.dart';
import 'api_client.dart';

class CustomerService {
  final ApiClient _api = ApiClient();

  /// Top up customer wallet
  Future<Map<String, dynamic>?> topUpWallet(double amount) async {
    try {
      final response = await _api.dio.post(
        '/api/v1/customer/wallet/topup',
        data: {'amount': amount, 'payment_method': 'paystack'},
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (_) {
      return null;
    }
  }

  /// Redeem loyalty points to wallet balance
  Future<Map<String, dynamic>?> redeemPoints(int points) async {
    try {
      final response = await _api.dio.post(
        '/api/v1/customer/wallet/redeem-points',
        data: {'points': points},
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (_) {
      return null;
    }
  }

  /// Fetch list of available cosmetics
  Future<List<Map<String, dynamic>>?> getCosmetics() async {
    try {
      final response = await _api.dio.get('/api/v1/customer/cosmetics');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return null;
    } on DioException catch (_) {
      return null;
    }
  }
}
