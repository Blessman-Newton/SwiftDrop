import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class MerchantService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> getMerchantInfo() async {
    try {
      final response = await _api.dio.get('/api/v1/merchants/info');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> createRestaurant({
    required String name,
    String? description,
    required String address,
    double? latitude,
    double? longitude,
    String? logoUrl,
    String? phone,
    String? email,
    Map<String, dynamic>? openingHours,
    String? restaurantType,
    String? deliveryTime,
    double? deliveryFee,
    double? minimumOrder,
  }) async {
    try {
      final response = await _api.dio.post(
        '/api/v1/merchants/restaurant',
        data: {
          'name': name,
          'description': description,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'logo_url': logoUrl,
          'phone': phone,
          'email': email,
          'opening_hours': openingHours,
          'restaurant_type': restaurantType,
          'delivery_time': deliveryTime,
          'delivery_fee': deliveryFee,
          'minimum_order': minimumOrder,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> getRestaurant() async {
    try {
      final response = await _api.dio.get('/api/v1/merchants/restaurant');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> updateRestaurant({
    String? name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    String? logoUrl,
    String? phone,
    String? email,
    Map<String, dynamic>? openingHours,
    String? restaurantType,
    String? deliveryTime,
    double? deliveryFee,
    double? minimumOrder,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (address != null) data['address'] = address;
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;
      if (logoUrl != null) data['logo_url'] = logoUrl;
      if (phone != null) data['phone'] = phone;
      if (email != null) data['email'] = email;
      if (openingHours != null) data['opening_hours'] = openingHours;
      if (restaurantType != null) data['restaurant_type'] = restaurantType;
      if (deliveryTime != null) data['delivery_time'] = deliveryTime;
      if (deliveryFee != null) data['delivery_fee'] = deliveryFee;
      if (minimumOrder != null) data['minimum_order'] = minimumOrder;

      final response = await _api.dio.patch(
        '/api/v1/merchants/restaurant',
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<List<Map<String, dynamic>>> getMenuItems() async {
    try {
      final response = await _api.dio.get('/api/v1/merchants/menu');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> createMenuItem({
    required String name,
    String? description,
    required double price,
    String? categoryId,
    String? imageUrl,
    bool isAvailable = true,
    bool isVegetarian = false,
    bool isSpicy = false,
    List<String> tags = const [],
  }) async {
    try {
      final response = await _api.dio.post(
        '/api/v1/merchants/menu',
        data: {
          'name': name,
          'description': description,
          'price': price,
          'category_id': categoryId,
          'image_url': imageUrl,
          'is_available': isAvailable,
          'is_vegetarian': isVegetarian,
          'is_spicy': isSpicy,
          'tags': tags,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> updateMenuItem(
    String itemId, {
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? imageUrl,
    bool? isAvailable,
    bool? isVegetarian,
    bool? isSpicy,
    List<String>? tags,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price;
      if (categoryId != null) data['category_id'] = categoryId;
      if (imageUrl != null) data['image_url'] = imageUrl;
      if (isAvailable != null) data['is_available'] = isAvailable;
      if (isVegetarian != null) data['is_vegetarian'] = isVegetarian;
      if (isSpicy != null) data['is_spicy'] = isSpicy;
      if (tags != null) data['tags'] = tags;

      final response = await _api.dio.patch(
        '/api/v1/merchants/menu/$itemId',
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> deleteMenuItem(String itemId) async {
    try {
      await _api.dio.delete('/api/v1/merchants/menu/$itemId');
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> toggleStock(String itemId) async {
    try {
      final response = await _api.dio.patch(
        '/api/v1/merchants/menu/$itemId/toggle-stock',
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<List<Map<String, dynamic>>> getOrders({String? status}) async {
    try {
      final response = await _api.dio.get(
        '/api/v1/merchants/orders',
        queryParameters: status != null ? {'status': status} : null,
      );
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    String status,
  ) async {
    try {
      final response = await _api.dio.patch(
        '/api/v1/merchants/orders/$orderId/status',
        data: {'status': status},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _api.dio.get('/api/v1/merchants/dashboard');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      return data['detail'] as String? ?? 'Something went wrong';
    }
    return 'Network error. Please try again.';
  }
}
