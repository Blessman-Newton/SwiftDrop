import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/order_service.dart';
import '../services/customer_service.dart';
import 'auth_provider.dart';

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
    addCustomItem(item, const [], 1, restaurantId: restaurantId);
  }

  void addCustomItem(FoodItem item, List<CartExtra> extras, int quantity, {String? restaurantId}) {
    if (restaurantId != null && _restaurantId != null && _restaurantId != restaurantId) {
      state = [];
    }
    if (restaurantId != null) _restaurantId = restaurantId;

    final index = state.indexWhere((ci) {
      if (ci.foodItem.id != item.id) return false;
      if (ci.extras.length != extras.length) return false;
      for (final ext in extras) {
        final match = ci.extras.firstWhere(
          (ce) => ce.name == ext.name && ce.price == ext.price,
          orElse: () => const CartExtra(name: '', price: 0, quantity: -1),
        );
        if (match.quantity != ext.quantity) return false;
      }
      return true;
    });

    if (index >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            state[i].copyWith(quantity: state[i].quantity + quantity)
          else
            state[i],
      ];
    } else {
      state = [...state, CartItem(foodItem: item, quantity: quantity, extras: extras)];
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

  void increaseQuantity(CartItem target) {
    final index = state.indexOf(target);
    if (index >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i],
      ];
      _save();
    }
  }

  void decreaseQuantity(CartItem target) {
    final index = state.indexOf(target);
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
        state = [
          for (int i = 0; i < state.length; i++)
            if (i != index) state[i],
        ];
        if (state.isEmpty) _restaurantId = null;
      }
      _save();
    }
  }

  void clearCart() {
    state = [];
    _restaurantId = null;
    _save();
  }

  int get itemCount => state.fold(0, (sum, ci) => sum + ci.quantity);

  double get subtotal =>
      state.fold(0, (sum, ci) => sum + ci.totalPrice);
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
  OrdersNotifier() : super([_demoOrder]) {
    // TEMP DEMO: seeded active order to showcase tracking. Revert after.
    // _loadFromApi();
    // _startPolling();
  }

  // TEMP DEMO order — remove.
  static final Order _demoOrder = Order(
    id: 'ord_demo_track',
    restaurantId: 'demo',
    restaurantName: "Amina's Locals",
    items: [
      CartItem(
        foodItem: const FoodItem(
          id: 'demo_jollof',
          name: 'Jollof Rice',
          description: 'hot meal',
          price: 80,
          imageUrl: '',
          category: FoodCategory.popular,
        ),
        quantity: 1,
      ),
    ],
    totalPrice: 86.40,
    status: OrderStatus.enRoute,
    createdAt: DateTime.now(),
    trackingStep: 4,
    riderName: 'Kwame Mensah',
    riderPhone: '+233200000000',
    riderVehicleType: 'Motorbike',
    orderType: 'food',
    pickupAddress: "Amina's Locals, Sunyani",
    pickupLat: 7.3399,
    pickupLng: -2.3269,
    deliveryAddress: 'Home: 123 Oak Street, Sunyani',
    deliveryLat: 7.3350,
    deliveryLng: -2.3300,
  );

  final _orderService = OrderService();
  Timer? _pollTimer;

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _loadFromApi();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

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
          riderId: o['rider_id'] as String?,
          riderName: o['rider_name'] as String?,
          riderPhone: o['rider_phone'] as String?,
          riderAvatar: o['rider_avatar'] as String?,
          riderVehicleType: o['rider_vehicle_type'] as String?,
          pickupAddress: o['pickup_address'] as String?,
          pickupLat: (o['pickup_lat'] as num?)?.toDouble(),
          pickupLng: (o['pickup_lng'] as num?)?.toDouble(),
          deliveryAddress: o['delivery_address'] as String?,
          deliveryLat: (o['delivery_lat'] as num?)?.toDouble(),
          deliveryLng: (o['delivery_lng'] as num?)?.toDouble(),
          deliveryPin: o['delivery_pin'] as String?,
          trackingUrl: o['tracking_url'] as String?,
        )).toList();
        return;
      }
    } catch (_) {}
    _loadFromLocal();
  }

  OrderStatus _mapStatus(String? apiStatus) => OrderStatusX.fromApi(apiStatus);

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
      status: OrderStatus.created,
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
        (o) => o.status.isActive,
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
      (o) => o.status.isActive,
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
          o.status == OrderStatus.readyForPickup ||
          o.status == OrderStatus.pickedUp ||
          o.status == OrderStatus.enRoute,
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

  void updatePickup(String pickup, {double? lat, double? lng}) {
    state = state.copyWith(pickupLocation: pickup, pickupLat: lat, pickupLng: lng);
  }

  void updateDelivery(String delivery, {double? lat, double? lng}) {
    state = state.copyWith(deliveryLocation: delivery, deliveryLat: lat, deliveryLng: lng);
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
  final Ref _ref;
  final _customerService = CustomerService();

  UserProfileNotifier(this._ref) : super(const UserProfile()) {
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

  void updateFromUser(User user) {
    state = state.copyWith(
      walletBalance: user.walletBalance,
      points: user.loyaltyPoints,
      membershipTier: user.membershipTier,
    );
    _save();
  }

  Future<bool> topUp(double amount) async {
    final result = await _customerService.topUpWallet(amount);
    if (result != null) {
      state = state.copyWith(
        walletBalance: (result['wallet_balance'] as num).toDouble(),
        points: result['loyalty_points'] as int,
        membershipTier: result['membership_tier'] as String,
      );
      _save();
      // Also update currentUserProvider
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser != null) {
        _ref.read(currentUserProvider.notifier).state = currentUser.copyWith(
          walletBalance: state.walletBalance,
          loyaltyPoints: state.points,
          membershipTier: state.membershipTier,
        );
      }
      return true;
    }
    return false;
  }

  void deduct(double amount) {
    state = state.copyWith(walletBalance: state.walletBalance - amount);
    _save();
  }

  void addPoints(int pts) {
    state = state.copyWith(points: state.points + pts);
    _save();
  }

  Future<bool> redeemPoints(int pts) async {
    final result = await _customerService.redeemPoints(pts);
    if (result != null) {
      state = state.copyWith(
        walletBalance: (result['wallet_balance'] as num).toDouble(),
        points: result['loyalty_points'] as int,
      );
      _save();
      // Also update currentUserProvider
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser != null) {
        _ref.read(currentUserProvider.notifier).state = currentUser.copyWith(
          walletBalance: state.walletBalance,
          loyaltyPoints: state.points,
        );
      }
      return true;
    }
    return false;
  }

  void setMembership(String tier) {
    state = state.copyWith(membershipTier: tier);
    _save();
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  final user = ref.watch(currentUserProvider);
  final notifier = UserProfileNotifier(ref);
  if (user != null) {
    // Run after build cycle to avoid Riverpod modify-during-build exception
    Future.microtask(() => notifier.updateFromUser(user));
  }
  return notifier;
});
