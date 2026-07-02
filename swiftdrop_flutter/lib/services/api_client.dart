import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_endpoints.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  String? _token;

  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _token = null;
          }
          return handler.next(error);
        },
      ),
    );
  }

  factory ApiClient() {
    _instance ??= ApiClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  void setToken(String? token) {
    _token = token;
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('swiftdrop_api_token');
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('swiftdrop_api_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('swiftdrop_api_token');
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null;
}
