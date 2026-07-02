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

  factory FoodItem.fromApiResponse(Map<String, dynamic> json) => FoodItem(
        id: json['id'] as String,
        name: json['name'] as String,
        description: (json['description'] as String?) ?? '',
        price: (json['price'] as num).toDouble(),
        imageUrl: (json['image_url'] as String?) ?? '',
        category: _parseFoodCategory(json['category'] as String?),
      );

  static FoodCategory _parseFoodCategory(String? cat) {
    switch (cat) {
      case 'popular': return FoodCategory.popular;
      case 'combos': return FoodCategory.combos;
      case 'burgers': return FoodCategory.burgers;
      case 'sides': return FoodCategory.sides;
      case 'drinks': return FoodCategory.drinks;
      default: return FoodCategory.popular;
    }
  }
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

  factory Restaurant.fromApiResponse(Map<String, dynamic> json) {
    final deliveryFee = (json['delivery_fee'] as num?) ?? 0;
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      deliveryTime: (json['delivery_time'] as String?) ?? '',
      deliveryFee: deliveryFee == 0 ? 'Free' : '\$${deliveryFee.toStringAsFixed(2)}',
      distance: '',
      imageUrl: (json['image_url'] as String?) ?? '',
      isPopular: (json['tags'] as List?)?.contains('Top Rated') ?? false,
      isTrending: (json['tags'] as List?)?.contains('Trending') ?? false,
      isNew: (json['tags'] as List?)?.contains('New') ?? false,
      menu: [],
    );
  }

  factory Restaurant.fromDetailResponse(Map<String, dynamic> json) {
    final deliveryFee = (json['delivery_fee'] as num?) ?? 0;
    final menuItems = (json['menu_items'] as List?)
            ?.map((item) => FoodItem.fromApiResponse(item))
            .toList() ??
        [];
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      deliveryTime: (json['delivery_time'] as String?) ?? '',
      deliveryFee: deliveryFee == 0 ? 'Free' : '\$${deliveryFee.toStringAsFixed(2)}',
      distance: '',
      imageUrl: (json['image_url'] as String?) ?? '',
      isPopular: (json['tags'] as List?)?.contains('Top Rated') ?? false,
      isTrending: (json['tags'] as List?)?.contains('Trending') ?? false,
      isNew: (json['tags'] as List?)?.contains('New') ?? false,
      menu: menuItems,
    );
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
  final String orderType;
  final String? parcelPickupLocation;
  final String? parcelDeliveryLocation;

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
    this.orderType = 'food',
    this.parcelPickupLocation,
    this.parcelDeliveryLocation,
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
    String? orderType,
    String? parcelPickupLocation,
    String? parcelDeliveryLocation,
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
      orderType: orderType ?? this.orderType,
      parcelPickupLocation: parcelPickupLocation ?? this.parcelPickupLocation,
      parcelDeliveryLocation: parcelDeliveryLocation ?? this.parcelDeliveryLocation,
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
        'orderType': orderType,
        'parcelPickupLocation': parcelPickupLocation,
        'parcelDeliveryLocation': parcelDeliveryLocation,
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
        orderType: map['orderType'] as String? ?? 'food',
        parcelPickupLocation: map['parcelPickupLocation'] as String?,
        parcelDeliveryLocation: map['parcelDeliveryLocation'] as String?,
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

// ==================== PARCEL BOOKING ====================

class ParcelBooking {
  final String pickupLocation;
  final String deliveryLocation;
  final String packageType;
  final double weight;
  final double? lengthCm;
  final double? widthCm;
  final double? heightCm;
  final String? riderNotes;
  final String deliveryService;
  final bool insuranceIncluded;
  final String? promoCode;

  const ParcelBooking({
    this.pickupLocation = '',
    this.deliveryLocation = '',
    this.packageType = 'box',
    this.weight = 5,
    this.lengthCm,
    this.widthCm,
    this.heightCm,
    this.riderNotes,
    this.deliveryService = 'swift',
    this.insuranceIncluded = false,
    this.promoCode,
  });

  double get deliveryFee {
    switch (deliveryService) {
      case 'economy':
        return 4.50;
      case 'standard':
        return 7.00;
      case 'swift':
      default:
        return 12.50;
    }
  }

  double get serviceFee => 1.50;
  double get insuranceFee => insuranceIncluded ? 1.00 : 0.0;
  double get discount => _promoDiscount;
  double get total => deliveryFee + serviceFee + insuranceFee - discount;

  double get _promoDiscount {
    if (promoCode == null) return 0;
    switch (promoCode!.toUpperCase()) {
      case 'SWIFT15':
        return total * 0.15;
      case 'WELCOME10':
        return total * 0.10;
      case 'FREE5':
        return 5.0;
      default:
        return 0;
    }
  }

  String get deliveryEta {
    switch (deliveryService) {
      case 'economy':
        return '4-6 hrs';
      case 'standard':
        return '2 hrs';
      case 'swift':
      default:
        return '30-45 min';
    }
  }

  String get serviceDisplayName {
    switch (deliveryService) {
      case 'economy':
        return 'Economy';
      case 'standard':
        return 'Standard';
      case 'swift':
      default:
        return 'SwiftDrop Express';
    }
  }

  String get packageTypeLabel {
    switch (packageType) {
      case 'document':
        return 'Document';
      case 'electronics':
        return 'Electronics';
      case 'fragile':
        return 'Fragile';
      case 'box':
      default:
        return 'Box';
    }
  }

  String get packageSizeLabel {
    if (weight <= 2) return 'Small (<2kg)';
    if (weight <= 10) return 'Medium (<10kg)';
    return 'Large (${weight.round()}kg)';
  }

  ParcelBooking copyWith({
    String? pickupLocation,
    String? deliveryLocation,
    String? packageType,
    double? weight,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    String? riderNotes,
    String? deliveryService,
    bool? insuranceIncluded,
    String? promoCode,
  }) {
    return ParcelBooking(
      pickupLocation: pickupLocation ?? this.pickupLocation,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      packageType: packageType ?? this.packageType,
      weight: weight ?? this.weight,
      lengthCm: lengthCm ?? this.lengthCm,
      widthCm: widthCm ?? this.widthCm,
      heightCm: heightCm ?? this.heightCm,
      riderNotes: riderNotes ?? this.riderNotes,
      deliveryService: deliveryService ?? this.deliveryService,
      insuranceIncluded: insuranceIncluded ?? this.insuranceIncluded,
      promoCode: promoCode ?? this.promoCode,
    );
  }
}
