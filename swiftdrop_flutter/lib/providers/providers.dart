import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../data/restaurants.dart';

// ==================== CART (with persistence) ====================

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
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
  }

  void addItem(FoodItem item) {
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
      }
    }
    _save();
  }

  void clearCart() {
    state = [];
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
    _load();
  }

  static final _initialOrders = [
    Order(
      id: 'ord_001',
      restaurantId: 'rest_burger_loft',
      restaurantName: 'The Burger Loft',
      items: [
        const CartItem(
          foodItem: FoodItem(
            id: 'burger_truffle',
            name: 'The Signature Truffle Burger',
            description: '',
            price: 14.99,
            imageUrl: '',
            category: FoodCategory.popular,
          ),
          quantity: 2,
        ),
      ],
      totalPrice: 29.98,
      status: OrderStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Order(
      id: 'ord_002',
      restaurantId: 'rest_pizza_rustica',
      restaurantName: 'Pizza Rustica',
      items: [
        const CartItem(
          foodItem: FoodItem(
            id: 'pizza_margherita',
            name: 'Neapolitan Margherita DOP',
            description: '',
            price: 15.99,
            imageUrl: '',
            category: FoodCategory.popular,
          ),
          quantity: 1,
        ),
      ],
      totalPrice: 15.99,
      status: OrderStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('swiftdrop_orders');
    if (json != null) {
      try {
        final list = (jsonDecode(json) as List)
            .map((e) => Order.fromMap(e as Map<String, dynamic>))
            .toList();
        state = list;
      } catch (_) {
        state = _initialOrders;
      }
    } else {
      state = _initialOrders;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(state.map((o) => o.toMap()).toList());
    await prefs.setString('swiftdrop_orders', json);
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

final onboardingDoneProvider = StateProvider<bool>((ref) => false);
