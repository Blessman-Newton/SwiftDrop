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
