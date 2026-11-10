import 'package:dio/dio.dart';

String userFriendlyError(Object error, {String action = 'complete this request'}) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final detail = _responseDetail(error.response?.data).toLowerCase();

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'We could not connect right now. Please check your internet connection and try again.';
    }
    if (status == 401) {
      return 'Your session has expired. Please sign in again.';
    }
    if (status == 403) {
      return 'You do not have permission to do that.';
    }
    if (status == 404) {
      return 'We could not find what you were looking for.';
    }
    if (status == 409 || detail.contains('already exists') || detail.contains('already registered')) {
      return 'That information is already in use. Please check it and try again.';
    }
    if (status == 422) {
      return 'Please check the information you entered and try again.';
    }
    if (status != null && status >= 500) {
      return 'Something went wrong on our side. Please try again in a moment.';
    }
    if (detail.contains('invalid') && detail.contains('password')) {
      return 'The email or password is incorrect.';
    }
    if (detail.contains('email')) {
      return 'Please enter a valid email address.';
    }
  }
  return 'We could not $action. Please try again.';
}

String _responseDetail(dynamic data) {
  if (data is Map) {
    final detail = data['detail'] ?? data['message'] ?? data['error'];
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] is String) return first['msg'] as String;
    }
  }
  return '';
}
