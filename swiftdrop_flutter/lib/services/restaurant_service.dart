import 'package:dio/dio.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class RestaurantService {
  final ApiClient _client = ApiClient();

  Future<List<Restaurant>> getRestaurants({String? search, String? tag}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (tag != null && tag.isNotEmpty) queryParams['tag'] = tag;

      final response = await _client.dio.get(
        ApiEndpoints.restaurants,
        queryParameters: queryParams,
      );

      final data = response.data as List;
      return data.map((r) => Restaurant.fromApiResponse(r)).toList();
    } on DioException {
      return [];
    }
  }

  Future<Restaurant?> getRestaurant(String restaurantId) async {
    try {
      final response = await _client.dio.get(
        '${ApiEndpoints.restaurants}/$restaurantId',
      );
      return Restaurant.fromDetailResponse(response.data);
    } on DioException {
      return null;
    }
  }

  Future<List<FoodItem>> getMenuItems(String restaurantId, {String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;

      final response = await _client.dio.get(
        '${ApiEndpoints.restaurants}/$restaurantId/menu',
        queryParameters: queryParams,
      );

      final data = response.data as List;
      return data.map((item) => FoodItem.fromApiResponse(item)).toList();
    } on DioException {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPromoCodes() async {
    try {
      final response = await _client.dio.get(
        '${ApiEndpoints.restaurants}/promos/list',
      );
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException {
      return [];
    }
  }

  Future<Map<String, dynamic>> validatePromoCode(String code, double orderTotal) async {
    try {
      final response = await _client.dio.post(
        '${ApiEndpoints.restaurants}/promos/validate',
        data: {'code': code, 'order_total': orderTotal},
      );
      return response.data;
    } on DioException catch (e) {
      return {'valid': false, 'message': e.message ?? 'Network error'};
    }
  }
}
