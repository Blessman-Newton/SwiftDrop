enum FoodCategory { popular, combos, burgers, sides, drinks }

/// Mirrors the backend order state machine
/// CREATED → CONFIRMED → PREPARING → READY_FOR_PICKUP → PICKED_UP → EN_ROUTE → DELIVERED
/// (+ CANCELLED before pickup)
enum OrderStatus {
  created,
  confirmed,
  preparing,
  readyForPickup,
  pickedUp,
  enRoute,
  delivered,
  cancelled,
}

/// A single stage on the customer-facing tracking timeline. Several backend
/// statuses can collapse onto one stage (e.g. created + confirmed → "Confirmed").
class OrderTimelineStage {
  final String label;
  final String description;
  const OrderTimelineStage(this.label, this.description);
}

extension OrderStatusX on OrderStatus {
  /// User-facing short label for chips/badges.
  String get label {
    switch (this) {
      case OrderStatus.created:
        return 'Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.readyForPickup:
        return 'Ready for pickup';
      case OrderStatus.pickedUp:
        return 'Picked up';
      case OrderStatus.enRoute:
        return 'On the way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isTerminal =>
      this == OrderStatus.delivered || this == OrderStatus.cancelled;

  bool get isActive => !isTerminal;

  bool get isCancelled => this == OrderStatus.cancelled;

  /// Index of the current stage on [timelineStages] (0-based).
  /// Returns -1 for cancelled orders.
  int get timelineIndex {
    switch (this) {
      case OrderStatus.created:
      case OrderStatus.confirmed:
        return 0;
      case OrderStatus.preparing:
        return 1;
      case OrderStatus.readyForPickup:
        return 2;
      case OrderStatus.pickedUp:
        return 3;
      case OrderStatus.enRoute:
        return 4;
      case OrderStatus.delivered:
        return 5;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  /// The ordered set of stages shown on the tracking timeline.
  static const List<OrderTimelineStage> timelineStages = [
    OrderTimelineStage('Confirmed', 'Order received by the restaurant'),
    OrderTimelineStage('Preparing', 'Your order is being prepared'),
    OrderTimelineStage('Ready', 'Ready and waiting for a rider'),
    OrderTimelineStage('Picked up', 'Rider has collected your order'),
    OrderTimelineStage('On the way', 'Your rider is heading to you'),
    OrderTimelineStage('Delivered', 'Enjoy! Order delivered'),
  ];

  /// Parcel orders skip the restaurant "preparing" stages.
  static const List<OrderTimelineStage> parcelTimelineStages = [
    OrderTimelineStage('Confirmed', 'Booking confirmed'),
    OrderTimelineStage('Preparing', 'Assigning a rider'),
    OrderTimelineStage('Ready', 'Rider heading to pickup'),
    OrderTimelineStage('Picked up', 'Parcel collected'),
    OrderTimelineStage('On the way', 'Rider heading to drop-off'),
    OrderTimelineStage('Delivered', 'Parcel delivered'),
  ];

  /// Backend string value for this status.
  String get apiValue {
    switch (this) {
      case OrderStatus.created:
        return 'CREATED';
      case OrderStatus.confirmed:
        return 'CONFIRMED';
      case OrderStatus.preparing:
        return 'PREPARING';
      case OrderStatus.readyForPickup:
        return 'READY_FOR_PICKUP';
      case OrderStatus.pickedUp:
        return 'PICKED_UP';
      case OrderStatus.enRoute:
        return 'EN_ROUTE';
      case OrderStatus.delivered:
        return 'DELIVERED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static OrderStatus fromApi(String? value) {
    switch (value) {
      case 'CREATED':
        return OrderStatus.created;
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'PREPARING':
        return OrderStatus.preparing;
      case 'READY_FOR_PICKUP':
        return OrderStatus.readyForPickup;
      case 'PICKED_UP':
        return OrderStatus.pickedUp;
      case 'EN_ROUTE':
        return OrderStatus.enRoute;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.created;
    }
  }

  /// Parse from local persistence, tolerating the legacy 4-value index scheme.
  static OrderStatus fromStored(dynamic raw) {
    if (raw is String) {
      for (final s in OrderStatus.values) {
        if (s.name == raw) return s;
      }
      return OrderStatusX.fromApi(raw);
    }
    if (raw is int) {
      // Legacy indices: 0=pending, 1=accepted, 2=outForDelivery, 3=completed
      switch (raw) {
        case 0:
          return OrderStatus.created;
        case 1:
          return OrderStatus.confirmed;
        case 2:
          return OrderStatus.enRoute;
        case 3:
          return OrderStatus.delivered;
        default:
          return OrderStatus.created;
      }
    }
    return OrderStatus.created;
  }
}

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
  final double walletBalance;
  final int loyaltyPoints;
  final String membershipTier;

  const User({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.avatarUrl,
    this.walletBalance = 0.0,
    this.loyaltyPoints = 0,
    this.membershipTier = 'Bronze',
  });

  User copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? avatarUrl,
    double? walletBalance,
    int? loyaltyPoints,
    String? membershipTier,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      walletBalance: walletBalance ?? this.walletBalance,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      membershipTier: membershipTier ?? this.membershipTier,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'avatarUrl': avatarUrl,
        'walletBalance': walletBalance,
        'loyaltyPoints': loyaltyPoints,
        'membershipTier': membershipTier,
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        uid: map['uid'] as String,
        email: map['email'] as String,
        displayName: map['displayName'] as String?,
        phoneNumber: map['phoneNumber'] as String?,
        avatarUrl: map['avatarUrl'] as String?,
        walletBalance: (map['walletBalance'] as num?)?.toDouble() ?? 0.0,
        loyaltyPoints: map['loyaltyPoints'] as int? ?? 0,
        membershipTier: map['membershipTier'] as String? ?? 'Bronze',
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
      deliveryFee: deliveryFee == 0 ? 'Free' : 'GHS ${deliveryFee.toStringAsFixed(2)}',
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
      deliveryFee: deliveryFee == 0 ? 'Free' : 'GHS ${deliveryFee.toStringAsFixed(2)}',
      distance: '',
      imageUrl: (json['image_url'] as String?) ?? '',
      isPopular: (json['tags'] as List?)?.contains('Top Rated') ?? false,
      isTrending: (json['tags'] as List?)?.contains('Trending') ?? false,
      isNew: (json['tags'] as List?)?.contains('New') ?? false,
      menu: menuItems,
    );
  }
}

class CartExtra {
  final String name;
  final double price;
  final int quantity;

  const CartExtra({required this.name, required this.price, required this.quantity});

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'quantity': quantity,
      };

  factory CartExtra.fromMap(Map<String, dynamic> map) => CartExtra(
        name: map['name'] as String,
        price: (map['price'] as num).toDouble(),
        quantity: map['quantity'] as int,
      );
}

class CartItem {
  final FoodItem foodItem;
  final int quantity;
  final List<CartExtra> extras;

  const CartItem({
    required this.foodItem,
    this.quantity = 1,
    this.extras = const [],
  });

  CartItem copyWith({FoodItem? foodItem, int? quantity, List<CartExtra>? extras}) {
    return CartItem(
      foodItem: foodItem ?? this.foodItem,
      quantity: quantity ?? this.quantity,
      extras: extras ?? this.extras,
    );
  }

  double get totalPrice =>
      (foodItem.price + extras.fold(0.0, (sum, e) => sum + e.totalPrice)) * quantity;

  Map<String, dynamic> toMap() => {
        'foodItem': foodItem.toMap(),
        'quantity': quantity,
        'extras': extras.map((e) => e.toMap()).toList(),
      };

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
        foodItem: FoodItem.fromMap(map['foodItem'] as Map<String, dynamic>),
        quantity: map['quantity'] as int,
        extras: (map['extras'] as List?)
                ?.map((e) => CartExtra.fromMap(e as Map<String, dynamic>))
                .toList() ??
            const [],
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
  final String? riderId;
  final String? riderName;
  final String? riderPhone;
  final String? riderAvatar;
  final String? riderVehicleType;
  final String orderType;
  final String? pickupAddress;
  final double? pickupLat;
  final double? pickupLng;
  final String? deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? parcelPickupLocation;
  final String? parcelDeliveryLocation;
  final String? deliveryPin;
  final String? trackingUrl;

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
    this.riderId,
    this.riderName,
    this.riderPhone,
    this.riderAvatar,
    this.riderVehicleType,
    this.orderType = 'food',
    this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    this.parcelPickupLocation,
    this.parcelDeliveryLocation,
    this.deliveryPin,
    this.trackingUrl,
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
    String? riderId,
    String? riderName,
    String? riderPhone,
    String? riderAvatar,
    String? riderVehicleType,
    String? orderType,
    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,
    String? deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
    String? parcelPickupLocation,
    String? parcelDeliveryLocation,
    String? deliveryPin,
    String? trackingUrl,
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
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      riderAvatar: riderAvatar ?? this.riderAvatar,
      riderVehicleType: riderVehicleType ?? this.riderVehicleType,
      orderType: orderType ?? this.orderType,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
      parcelPickupLocation: parcelPickupLocation ?? this.parcelPickupLocation,
      parcelDeliveryLocation: parcelDeliveryLocation ?? this.parcelDeliveryLocation,
      deliveryPin: deliveryPin ?? this.deliveryPin,
      trackingUrl: trackingUrl ?? this.trackingUrl,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'items': items.map((ci) => ci.toMap()).toList(),
        'totalPrice': totalPrice,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'trackingStep': trackingStep,
        'courierId': courierId,
        'riderId': riderId,
        'riderName': riderName,
        'riderPhone': riderPhone,
        'riderAvatar': riderAvatar,
        'riderVehicleType': riderVehicleType,
        'orderType': orderType,
        'pickupAddress': pickupAddress,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'deliveryAddress': deliveryAddress,
        'deliveryLat': deliveryLat,
        'deliveryLng': deliveryLng,
        'parcelPickupLocation': parcelPickupLocation,
        'parcelDeliveryLocation': parcelDeliveryLocation,
        'deliveryPin': deliveryPin,
        'trackingUrl': trackingUrl,
      };

  factory Order.fromMap(Map<String, dynamic> map) => Order(
        id: map['id'] as String,
        restaurantId: map['restaurantId'] as String? ?? '',
        restaurantName: map['restaurantName'] as String? ?? '',
        items: (map['items'] as List?)
            ?.map((e) => CartItem.fromMap(e as Map<String, dynamic>))
            .toList() ?? [],
        totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0,
        status: OrderStatusX.fromStored(map['status']),
        createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
        trackingStep: map['trackingStep'] as int?,
        courierId: map['courierId'] as String?,
        riderId: map['riderId'] as String?,
        riderName: map['riderName'] as String?,
        riderPhone: map['riderPhone'] as String?,
        riderAvatar: map['riderAvatar'] as String?,
        riderVehicleType: map['riderVehicleType'] as String?,
        orderType: map['orderType'] as String? ?? 'food',
        pickupAddress: map['pickupAddress'] as String?,
        pickupLat: (map['pickupLat'] as num?)?.toDouble(),
        pickupLng: (map['pickupLng'] as num?)?.toDouble(),
        deliveryAddress: map['deliveryAddress'] as String?,
        deliveryLat: (map['deliveryLat'] as num?)?.toDouble(),
        deliveryLng: (map['deliveryLng'] as num?)?.toDouble(),
        parcelPickupLocation: map['parcelPickupLocation'] as String?,
        parcelDeliveryLocation: map['parcelDeliveryLocation'] as String?,
        deliveryPin: map['deliveryPin'] as String?,
        trackingUrl: map['trackingUrl'] as String?,
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
  final double? pickupLat;
  final double? pickupLng;
  final String deliveryLocation;
  final double? deliveryLat;
  final double? deliveryLng;
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
    this.pickupLat,
    this.pickupLng,
    this.deliveryLocation = '',
    this.deliveryLat,
    this.deliveryLng,
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
    double? pickupLat,
    double? pickupLng,
    String? deliveryLocation,
    double? deliveryLat,
    double? deliveryLng,
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
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
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
