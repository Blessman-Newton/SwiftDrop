enum FoodCategory { popular, combos, burgers, sides, drinks }

enum OrderStatus { pending, accepted, outForDelivery, completed }

enum UserRole { customer, rider, guest }

enum RiderScreen { login, dashboard, activeDelivery, navigation, earnings }

enum DeliveryState { enRoute, arrived, collected }

enum ToastType { success, error, info }

class User {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? avatarUrl;

  const User({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.avatarUrl,
  });

  User copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? avatarUrl,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'avatarUrl': avatarUrl,
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        uid: map['uid'] as String,
        email: map['email'] as String,
        displayName: map['displayName'] as String?,
        phoneNumber: map['phoneNumber'] as String?,
        avatarUrl: map['avatarUrl'] as String?,
      );
}

class FoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final FoodCategory category;

  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'category': category.index,
      };

  factory FoodItem.fromMap(Map<String, dynamic> map) => FoodItem(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String,
        price: (map['price'] as num).toDouble(),
        imageUrl: map['imageUrl'] as String,
        category: FoodCategory.values[map['category'] as int],
      );
}

class Restaurant {
  final String id;
  final String name;
  final double rating;
  final List<String> tags;
  final String deliveryTime;
  final String deliveryFee;
  final String distance;
  final String imageUrl;
  final bool isPopular;
  final bool isNew;
  final bool isTrending;
  final List<FoodItem> menu;
  final int priceLevel;

  const Restaurant({
    required this.id,
    required this.name,
    required this.rating,
    required this.tags,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.distance,
    required this.imageUrl,
    this.isPopular = false,
    this.isNew = false,
    this.isTrending = false,
    required this.menu,
    this.priceLevel = 2,
  });

  double get distanceMiles {
    final match = RegExp(r'([\d.]+)').firstMatch(distance);
    return match != null ? double.parse(match.group(1)!) : 99.0;
  }
}

class CartItem {
  final FoodItem foodItem;
  final int quantity;

  const CartItem({required this.foodItem, this.quantity = 1});

  CartItem copyWith({FoodItem? foodItem, int? quantity}) {
    return CartItem(
      foodItem: foodItem ?? this.foodItem,
      quantity: quantity ?? this.quantity,
    );
  }

  double get totalPrice => foodItem.price * quantity;

  Map<String, dynamic> toMap() => {
        'foodItem': foodItem.toMap(),
        'quantity': quantity,
      };

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
        foodItem: FoodItem.fromMap(map['foodItem'] as Map<String, dynamic>),
        quantity: map['quantity'] as int,
      );
}

class Order {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final List<CartItem> items;
  final double totalPrice;
  final OrderStatus status;
  final DateTime createdAt;
  final int? trackingStep;
  final String? courierId;

  const Order({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.trackingStep,
    this.courierId,
  });

  Order copyWith({
    String? id,
    String? restaurantId,
    String? restaurantName,
    List<CartItem>? items,
    double? totalPrice,
    OrderStatus? status,
    DateTime? createdAt,
    int? trackingStep,
    String? courierId,
  }) {
    return Order(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      trackingStep: trackingStep ?? this.trackingStep,
      courierId: courierId ?? this.courierId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'items': items.map((ci) => ci.toMap()).toList(),
        'totalPrice': totalPrice,
        'status': status.index,
        'createdAt': createdAt.toIso8601String(),
        'trackingStep': trackingStep,
        'courierId': courierId,
      };

  factory Order.fromMap(Map<String, dynamic> map) => Order(
        id: map['id'] as String,
        restaurantId: map['restaurantId'] as String,
        restaurantName: map['restaurantName'] as String,
        items: (map['items'] as List)
            .map((e) => CartItem.fromMap(e as Map<String, dynamic>))
            .toList(),
        totalPrice: (map['totalPrice'] as num).toDouble(),
        status: OrderStatus.values[map['status'] as int],
        createdAt: DateTime.parse(map['createdAt'] as String),
        trackingStep: map['trackingStep'] as int?,
        courierId: map['courierId'] as String?,
      );
}

// --- Rider Models ---

class ActivityItem {
  final String id;
  final String merchant;
  final String distance;
  final String timeAgo;
  final double amount;
  final String type;
  ActivityItem({
    required this.id,
    required this.merchant,
    required this.distance,
    required this.timeAgo,
    required this.amount,
    required this.type,
  });
}

class Transaction {
  final String id;
  final String title;
  final String timestamp;
  final double amount;
  final bool isBonus;
  Transaction({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.amount,
    required this.isBonus,
  });
}

class DeliveryInfo {
  final String orderNo;
  final List<String> items;
  final String pickupName;
  final String pickupAddress;
  final String dropoffAddress;
  final String dropoffDetails;
  final double total;
  final String estimatedTime;
  DeliveryInfo({
    required this.orderNo,
    required this.items,
    required this.pickupName,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.dropoffDetails,
    required this.total,
    required this.estimatedTime,
  });
}

class ToastMessage {
  final String id;
  final String message;
  final ToastType type;
  ToastMessage({required this.id, required this.message, required this.type});
}
