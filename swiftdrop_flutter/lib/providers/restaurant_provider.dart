import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/restaurant_service.dart';

final restaurantServiceProvider = Provider<RestaurantService>((ref) {
  return RestaurantService();
});

final restaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  final service = ref.watch(restaurantServiceProvider);
  return service.getRestaurants();
});

final restaurantDetailProvider =
    FutureProvider.family<Restaurant?, String>((ref, restaurantId) async {
  final service = ref.watch(restaurantServiceProvider);
  return service.getRestaurant(restaurantId);
});

final menuProvider =
    FutureProvider.family<List<FoodItem>, String>((ref, restaurantId) async {
  final service = ref.watch(restaurantServiceProvider);
  return service.getMenuItems(restaurantId);
});

final promosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(restaurantServiceProvider);
  return service.getPromoCodes();
});

final recommendedFoodProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final restaurants = await ref.watch(restaurantsProvider.future);
  final service = ref.watch(restaurantServiceProvider);
  final menus = await service.getRecommendedMenus();

  final List<Map<String, dynamic>> foodWithRestaurant = [];
  for (final r in restaurants) {
    final items = menus[r.id] ?? const <FoodItem>[];
    for (final item in items) {
      foodWithRestaurant.add({
        'foodItem': item,
        'restaurant': r,
      });
    }
  }
  return foodWithRestaurant;
});
