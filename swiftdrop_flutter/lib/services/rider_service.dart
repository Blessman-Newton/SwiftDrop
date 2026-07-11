import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class RiderService {
  final ApiClient _api = ApiClient();

  /// Go online
  Future<bool> goOnline({String? vehicleType, String? licenseNumber}) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.riderOnlineStatus,
        data: {
          'vehicle_type': vehicleType,
          'license_number': licenseNumber,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (_) {
      return false;
    }
  }

  /// Go offline
  Future<bool> goOffline() async {
    try {
      final response = await _api.dio.post(ApiEndpoints.riderOfflineStatus);
      return response.statusCode == 200;
    } on DioException catch (_) {
      return false;
    }
  }

  /// Get rider dashboard data
  Future<Map<String, dynamic>?> getDashboard() async {
    try {
      final response = await _api.dio.get(ApiEndpoints.riderDashboard);
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (_) {
      return null;
    }
  }

  /// Get rider earnings data
  Future<Map<String, dynamic>?> getEarnings() async {
    try {
      final response = await _api.dio.get(ApiEndpoints.riderEarnings);
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (_) {
      return null;
    }
  }

  /// Get rider transactions
  Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final response = await _api.dio.get(ApiEndpoints.riderTransactions);
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

  /// Get rider stats
  Future<Map<String, dynamic>?> getStats() async {
    try {
      final response = await _api.dio.get(ApiEndpoints.riderStats);
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (_) {
      return null;
    }
  }

  /// Get active delivery
  Future<Map<String, dynamic>?> getActiveDelivery() async {
    try {
      final response = await _api.dio.get(ApiEndpoints.riderActiveDelivery);
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (_) {
      return null;
    }
  }

  /// Update active delivery status
  Future<bool> updateDeliveryStatus(String status, {double? latitude, double? longitude}) async {
    try {
      final response = await _api.dio.put(
        ApiEndpoints.riderDeliveryStatus,
        data: {
          'status': status,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (_) {
      return false;
    }
  }

  /// Update rider GPS location
  Future<bool> updateLocation(double latitude, double longitude) async {
    try {
      final response = await _api.dio.post(
        '/api/v1/rider-profile/location',
        data: {'latitude': latitude, 'longitude': longitude},
      );
      return response.statusCode == 200;
    } on DioException catch (_) {
      return false;
    }
  }

  /// Get available orders for dispatch
  Future<List<Map<String, dynamic>>> getAvailableOrders() async {
    try {
      final response = await _api.dio.get(ApiEndpoints.riderAvailableOrders);
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

  /// Accept an order
  Future<bool> acceptOrder(String orderId) async {
    try {
      final response = await _api.dio.post(ApiEndpoints.acceptOrder(orderId));
      return response.statusCode == 200;
    } on DioException catch (_) {
      return false;
    }
  }

  /// Reject an order
  Future<bool> rejectOrder(String orderId, {String? reason}) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.rejectOrder(orderId),
        queryParameters: {'reason': reason},
      );
      return response.statusCode == 200;
    } on DioException catch (_) {
      return false;
    }
  }

  /// Update order status (for rider flow)
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await _api.dio.patch(
        '/api/v1/orders/$orderId/status',
        data: {'status': status},
      );
      return response.statusCode == 200;
    } on DioException catch (_) {
      return false;
    }
  }
}
