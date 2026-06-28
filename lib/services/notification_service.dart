import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';

class NotificationEvent {
  final String title;
  final String body;
  final DateTime timestamp;

  const NotificationEvent({
    required this.title,
    required this.body,
    required this.timestamp,
  });
}

class OrderNotificationService {
  final List<NotificationEvent> _events = [];
  final Set<String> _notifiedOrders = {};

  List<NotificationEvent> get events => List.unmodifiable(_events);

  void checkForStatusChanges(List<Order> orders) {
    for (final order in orders) {
      if (_notifiedOrders.contains(order.id)) continue;

      if (order.status == OrderStatus.outForDelivery) {
        _notifiedOrders.add(order.id);
        final event = NotificationEvent(
          title: 'Out for Delivery!',
          body:
              'Your order from ${order.restaurantName} is on its way!',
          timestamp: DateTime.now(),
        );
        _events.add(event);
      } else if (order.status == OrderStatus.completed) {
        _notifiedOrders.add(order.id);
        final event = NotificationEvent(
          title: 'Order Delivered!',
          body:
              'Your order from ${order.restaurantName} has been delivered. Enjoy!',
          timestamp: DateTime.now(),
        );
        _events.add(event);
      }
    }
  }
}

final notificationServiceProvider =
    Provider<OrderNotificationService>((ref) {
  return OrderNotificationService();
});

final notificationEventsProvider =
    StateProvider<List<NotificationEvent>>((ref) => []);

final orderStatusWatcherProvider = Provider<void>((ref) {
  final service = ref.watch(notificationServiceProvider);
  final orders = ref.watch(ordersProvider);

  service.checkForStatusChanges(orders);

  if (service.events.isNotEmpty) {
    ref.read(notificationEventsProvider.notifier).state =
        service.events.toList();
  }
});
