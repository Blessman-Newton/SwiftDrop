import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/rider_service.dart';

final riderServiceProvider = Provider<RiderService>((ref) => RiderService());

// Dashboard data from API
final riderDashboardProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final service = ref.read(riderServiceProvider);
  return service.getDashboard();
});

// Earnings data from API
final riderEarningsProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final service = ref.read(riderServiceProvider);
  return service.getEarnings();
});

// Transactions from API
final riderTransactionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(riderServiceProvider);
  return service.getTransactions();
});

// Stats from API
final riderStatsProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final service = ref.read(riderServiceProvider);
  return service.getStats();
});

// Active delivery from API
final riderActiveDeliveryProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final service = ref.read(riderServiceProvider);
  return service.getActiveDelivery();
});

// Available orders for dispatch
final riderAvailableOrdersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(riderServiceProvider);
  return service.getAvailableOrders();
});
