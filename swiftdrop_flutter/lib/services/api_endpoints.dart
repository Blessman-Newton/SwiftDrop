class ApiEndpoints {
  static const String baseUrl = 'http://192.168.137.156:8000';

  // Auth
  static const String sendOtp = '/api/v1/auth/send-otp';
  static const String verifyOtp = '/api/v1/auth/verify-otp';
  static const String me = '/api/v1/auth/me';

  // Restaurants
  static const String restaurants = '/api/v1/restaurants';
  static String restaurantById(String id) => '/api/v1/restaurants/$id';
  static String restaurantMenu(String id) => '/api/v1/restaurants/$id/menu';
  static const String promos = '/api/v1/restaurants/promos/list';
  static const String validatePromo = '/api/v1/restaurants/promos/validate';

  // Orders
  static const String orders = '/api/v1/orders';
  static String orderById(String id) => '/api/v1/orders/$id';
  static String cancelOrder(String id) => '/api/v1/orders/$id/cancel';

  // Payments
  static const String initializePayment = '/api/v1/payments/initialize';
  static String verifyPayment(String ref) => '/api/v1/payments/$ref/verify';
  static const String paymentWebhook = '/api/v1/payments/webhook';

  // Riders
  static const String riderOnline = '/api/v1/riders/online';
  static const String riderOffline = '/api/v1/riders/offline';
  static const String riderAvailableOrders = '/api/v1/riders/available-orders';

  // Dispatch
  static String acceptOrder(String id) => '/api/v1/dispatch/$id/accept';
  static String rejectOrder(String id) => '/api/v1/dispatch/$id/reject';

  // Customer
  static const String customerProfile = '/api/v1/customer/profile';
  static const String customerAddresses = '/api/v1/customer/addresses';
  static String customerAddressById(String id) => '/api/v1/customer/addresses/$id';
  static const String customerOrderHistory = '/api/v1/customer/orders/history';

  // Notifications
  static const String notifications = '/api/v1/notifications';
  static String notificationRead(String id) => '/api/v1/notifications/$id/read';
  static const String notificationsReadAll = '/api/v1/notifications/read-all';

  // Reviews
  static const String reviews = '/api/v1/reviews';
  static String riderReviews(String riderId) => '/api/v1/reviews/rider/$riderId';

  // Rider Profile
  static const String riderDashboard = '/api/v1/rider-profile/dashboard';
  static const String riderOnlineStatus = '/api/v1/rider-profile/online';
  static const String riderOfflineStatus = '/api/v1/rider-profile/offline';
  static const String riderActiveDelivery = '/api/v1/rider-profile/active-delivery';
  static const String riderDeliveryStatus = '/api/v1/rider-profile/active-delivery/status';
  static const String riderEarnings = '/api/v1/rider-profile/earnings';
  static const String riderTransactions = '/api/v1/rider-profile/transactions';
  static const String riderStats = '/api/v1/rider-profile/stats';
}
