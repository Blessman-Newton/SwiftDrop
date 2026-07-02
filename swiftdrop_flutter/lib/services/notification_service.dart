import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class NotificationService {
  final ApiClient _api = ApiClient();

  /// Fetch notifications from API
  Future<Map<String, dynamic>> listNotifications() async {
    try {
      final response = await _api.dio.get(ApiEndpoints.notifications);
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return {'notifications': [], 'unread_count': 0};
    } on DioException catch (_) {
      return {'notifications': [], 'unread_count': 0};
    }
  }

  /// Mark a notification as read
  Future<bool> markRead(String notificationId) async {
    try {
      final response = await _api.dio.post(ApiEndpoints.notificationRead(notificationId));
      return response.statusCode == 200;
    } on DioException catch (_) {
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllRead() async {
    try {
      final response = await _api.dio.post(ApiEndpoints.notificationsReadAll);
      return response.statusCode == 200;
    } on DioException catch (_) {
      return false;
    }
  }
}
