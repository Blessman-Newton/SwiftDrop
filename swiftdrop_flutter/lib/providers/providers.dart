import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/order_service.dart';

// ==================== CART (with persistence) ====================

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]) {
    _load();
  }

  String? _restaurantId;

  String? get restaurantId => _restaurantId;

  bool get isCartEmpty => state.isEmpty;

  /// Returns true if the cart belongs to a different restaurant.
  bool belongsToRestaurant(String restaurantId) {
    return _restaurantId != null && _restaurantId != restaurantId && state.isNotEmpty;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _restaurantId = prefs.getString('swiftdrop_cart_restaurant');
    final json = prefs.getString('swiftdrop_cart');
    if (json != null) {
      try {
        final list = (jsonDecode(json) as List)
            .map((e) => CartItem.fromMap(e as Map<String, dynamic>))
            .toList();
        state = list;
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(state.map((ci) => ci.toMap()).toList());
    await prefs.setString('swiftdrop_cart', json);
    if (_restaurantId != null) {
      await prefs.setString('swiftdrop_cart_restaurant', _restaurantId!);
    } else {
      await prefs.remove('swiftdrop_cart_restaurant');
    }
  }

  /// Adds an item for a specific restaurant. If the cart has items from a
  /// different restaurant, clears the cart first.
  void addItem(FoodItem item, {String? restaurantId}) {
    if (restaurantId != null && _restaurantId != null && _restaurantId != restaurantId) {
      state = [];
    }
    if (restaurantId != null) _restaurantId = restaurantId;

    final index = state.indexWhere((ci) => ci.foodItem.id == item.id);
    if (index >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i],
      ];
    } else {
      state = [...state, CartItem(foodItem: item, quantity: 1)];
    }
    _save();
  }

  void removeItem(String foodItemId) {
    final index = state.indexWhere((ci) => ci.foodItem.id == foodItemId);
    if (index >= 0) {
      if (state[index].quantity > 1) {
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == index)
              state[i].copyWith(quantity: state[i].quantity - 1)
            else
              state[i],
        ];
      } else {
        state = state.where((ci) => ci.foodItem.id != foodItemId).toList();
        if (state.isEmpty) _restaurantId = null;
      }
    }
    _save();
  }

  void clearCart() {
    state = [];
    _restaurantId = null;
    _save();
  }

  int get itemCount => state.fold(0, (sum, ci) => sum + ci.quantity);

  double get subtotal =>
      state.fold(0, (sum, ci) => sum + ci.foodItem.price * ci.quantity);
}

final selectedRestaurantProvider = StateProvider<Restaurant?>((ref) => null);

// ==================== FAVORITES (with persistence) ====================

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('swiftdrop_favorites') ?? [];
    state = favs.toSet();
  }

  void toggle(String restaurantId) async {
    if (state.contains(restaurantId)) {
      state = {...state}..remove(restaurantId);
    } else {
      state = {...state, restaurantId};
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('swiftdrop_favorites', state.toList());
  }

  bool isFavorite(String id) => state.contains(id);
}

// ==================== ORDERS (with state machine + persistence) ====================

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, List<Order>>((ref) {
  return OrdersNotifier();
});

class OrdersNotifier extends StateNotifier<List<Order>> {
  OrdersNotifier() : super([]) {
    _loadFromApi();
  }

  final _orderService = OrderService();

  Future<void> _loadFromApi() async {
    try {
      final apiOrders = await _orderService.listOrders();
      if (apiOrders.isNotEmpty) {
        state = apiOrders.map((o) => Order(
          id: o['id'] ?? '',
          restaurantId: '',
          restaurantName: o['restaurant_name'] ?? '',
          items: (o['items'] as List?)?.map((i) => CartItem(
            foodItem: FoodItem(
              id: '',
              name: i['name'] ?? '',
              description: '',
              price: (i['price'] as num?)?.toDouble() ?? 0,
              imageUrl: '',
              category: FoodCategory.popular,
            ),
            quantity: i['quantity'] ?? 1,
          )).toList() ?? [],
          totalPrice: (o['total'] as num?)?.toDouble() ?? 0,
          status: _mapStatus(o['status']),
          createdAt: o['created_at'] != null ? DateTime.parse(o['created_at']) : DateTime.now(),
          orderType: o['order_type'] ?? 'food',
        )).toList();
        return;
      }
    } catch (_) {}
    _loadFromLocal();
  }

  OrderStatus _mapStatus(String? apiStatus) {
    switch (apiStatus) {
      case 'CREATED': return OrderStatus.pending;
      case 'CONFIRMED':
      case 'PREPARING':
      case 'READY_FOR_PICKUP': return OrderStatus.accepted;
      case 'PICKED_UP':
      case 'EN_ROUTE': return OrderStatus.outForDelivery;
      case 'DELIVERED': return OrderStatus.completed;
      case 'CANCELLED': return OrderStatus.completed;
      default: return OrderStatus.pending;
    }
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('swiftdrop_orders');
    if (json != null) {
      try {
        final list = (jsonDecode(json) as List)
            .map((e) => Order.fromMap(e as Map<String, dynamic>))
            .toList();
        state = list;
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(state.map((o) => o.toMap()).toList());
    await prefs.setString('swiftdrop_orders', json);
  }

  Future<void> refreshOrders() async {
    await _loadFromApi();
  }

  void placeOrder(String restaurantId, String restaurantName,
      List<CartItem> items, double totalPrice) {
    final order = Order(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      items: List.from(items),
      totalPrice: totalPrice,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      trackingStep: 0,
    );
    state = [order, ...state];
    _save();
  }

  void addOrder(Order order) {
    state = [order, ...state];
    _save();
  }

  void reorder(List<CartItem> items, String restaurantId,
      String restaurantName) {
    final total =
        items.fold(0.0, (sum, ci) => sum + ci.foodItem.price * ci.quantity);
    placeOrder(restaurantId, restaurantName, items, total);
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    state = [
      for (final order in state)
        if (order.id == orderId)
          order.copyWith(status: newStatus)
        else
          order,
    ];
    _save();
  }

  void updateTrackingStep(String orderId, int step) {
    state = [
      for (final order in state)
        if (order.id == orderId)
          order.copyWith(trackingStep: step)
        else
          order,
    ];
    _save();
  }

  void assignCourier(String orderId, String courierId) {
    state = [
      for (final order in state)
        if (order.id == orderId)
          order.copyWith(courierId: courierId)
        else
          order,
    ];
    _save();
  }

  Order? getActiveOrder() {
    try {
      return state.firstWhere(
        (o) => o.status != OrderStatus.completed,
      );
    } catch (_) {
      return null;
    }
  }
}

// ==================== ACTIVE ORDER (for map tracking + rider link) ====================

final activeOrderProvider = Provider<Order?>((ref) {
  final orders = ref.watch(ordersProvider);
  try {
    return orders.firstWhere(
      (o) => o.status != OrderStatus.completed,
    );
  } catch (_) {
    return null;
  }
});

// ==================== RIDER ASSIGNED DELIVERY ====================

final riderAssignedOrderProvider = Provider<Order?>((ref) {
  final orders = ref.watch(ordersProvider);
  try {
    return orders.firstWhere(
      (o) =>
          o.status == OrderStatus.outForDelivery ||
          o.status == OrderStatus.accepted,
    );
  } catch (_) {
    return null;
  }
});

// ==================== FILTER STATE ====================

enum SortOption { rating, distance, deliveryTime, priceLow }

final sortOptionProvider = StateProvider<SortOption>((ref) => SortOption.rating);
final selectedCuisinesProvider = StateProvider<Set<String>>((ref) => {});
final maxPriceLevelProvider = StateProvider<int>((ref) => 3);

// ==================== MISC ====================

final promoCodeProvider = StateProvider<String?>((ref) => null);

final onboardingDoneProvider =
    StateNotifierProvider<OnboardingDoneNotifier, bool>((ref) {
  return OnboardingDoneNotifier();
});

class OnboardingDoneNotifier extends StateNotifier<bool> {
  OnboardingDoneNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('swiftdrop_onboarding_done') ?? false;
  }

  Future<void> complete() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('swiftdrop_onboarding_done', true);
  }
}

// ==================== PARCEL BOOKING ====================

final parcelBookingProvider =
    StateNotifierProvider<ParcelBookingNotifier, ParcelBooking>((ref) {
  return ParcelBookingNotifier();
});

class ParcelBookingNotifier extends StateNotifier<ParcelBooking> {
  ParcelBookingNotifier() : super(const ParcelBooking());

  void updatePickup(String pickup) {
    state = state.copyWith(pickupLocation: pickup);
  }

  void updateDelivery(String delivery) {
    state = state.copyWith(deliveryLocation: delivery);
  }

  void updatePackage(String type, double weight, {double? l, double? w, double? h, String? notes}) {
    state = state.copyWith(
      packageType: type,
      weight: weight,
      lengthCm: l,
      widthCm: w,
      heightCm: h,
      riderNotes: notes,
    );
  }

  void updateService(String service, {bool? insurance}) {
    state = state.copyWith(
      deliveryService: service,
      insuranceIncluded: insurance ?? state.insuranceIncluded,
    );
  }

  void toggleInsurance() {
    state = state.copyWith(insuranceIncluded: !state.insuranceIncluded);
  }

  void applyPromo(String code) {
    state = state.copyWith(promoCode: code);
  }

  void reset() {
    state = const ParcelBooking();
  }
}

// ==================== USER PROFILE (with persistence) ====================

class UserProfile {
  final double walletBalance;
  final int points;
  final String membershipTier;

  const UserProfile({
    this.walletBalance = 142.50,
    this.points = 2450,
    this.membershipTier = 'Gold',
  });

  UserProfile copyWith({double? walletBalance, int? points, String? membershipTier}) {
    return UserProfile(
      walletBalance: walletBalance ?? this.walletBalance,
      points: points ?? this.points,
      membershipTier: membershipTier ?? this.membershipTier,
    );
  }

  Map<String, dynamic> toMap() => {
        'walletBalance': walletBalance,
        'points': points,
        'membershipTier': membershipTier,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        walletBalance: (map['walletBalance'] as num?)?.toDouble() ?? 142.50,
        points: map['points'] as int? ?? 2450,
        membershipTier: map['membershipTier'] as String? ?? 'Gold',
      );
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(const UserProfile()) {
    _load();
  }

  static const _key = 'swiftdrop_user_profile';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      try {
        state = UserProfile.fromMap(jsonDecode(json) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toMap()));
  }

  void topUp(double amount) {
    state = state.copyWith(walletBalance: state.walletBalance + amount);
    _save();
  }

  void deduct(double amount) {
    state = state.copyWith(walletBalance: state.walletBalance - amount);
    _save();
  }

  void addPoints(int pts) {
    state = state.copyWith(points: state.points + pts);
    _save();
  }

  void redeemPoints(int pts) {
    state = state.copyWith(points: state.points - pts);
    _save();
  }

  void setMembership(String tier) {
    state = state.copyWith(membershipTier: tier);
    _save();
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});
