import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../providers/merchant_providers.dart';
import '../../providers/rider_providers.dart';

class RiderOrdersScreen extends ConsumerStatefulWidget {
  const RiderOrdersScreen({super.key});

  @override
  ConsumerState<RiderOrdersScreen> createState() => _RiderOrdersScreenState();
}

class _RiderOrdersScreenState extends ConsumerState<RiderOrdersScreen> {
  final Map<String, int> _orderTimers = {};
  final Map<String, Timer?> _timerInstances = {};
  int _previousOrderCount = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(riderAvailableOrdersProvider));
  }

  @override
  void dispose() {
    for (var timer in _timerInstances.values) {
      timer?.cancel();
    }
    super.dispose();
  }

  void _playNotificationSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  void _startOrderTimer(String orderId) {
    _orderTimers[orderId] = 30;
    _timerInstances[orderId]?.cancel();
    _timerInstances[orderId] = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_orderTimers[orderId] != null && _orderTimers[orderId]! > 0) {
        setState(() {
          _orderTimers[orderId] = _orderTimers[orderId]! - 1;
        });
      } else {
        timer.cancel();
        _timerInstances.remove(orderId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final availableOrdersAsync = ref.watch(riderAvailableOrdersProvider);
    final isOnline = ref.watch(riderOnlineProvider);

    availableOrdersAsync.whenData((orders) {
      if (orders.isNotEmpty && orders.length > _previousOrderCount) {
        HapticFeedback.heavyImpact();
        _playNotificationSound();
        for (var order in orders) {
          if (!_orderTimers.containsKey(order['id'])) {
            _startOrderTimer(order['id']);
          }
        }
      }
      _previousOrderCount = orders.length;
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF4),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
            const SizedBox(height: 16),
            if (!isOnline) _buildOfflineBanner(),
            Expanded(
              child: availableOrdersAsync.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return _buildEmptyState();
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(riderAvailableOrdersProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return _buildOrderCard(order);
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load orders',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(riderAvailableOrdersProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Available Orders',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              ref.invalidate(riderAvailableOrdersProvider);
              ref.read(riderToastsProvider.notifier).add(
                'Refreshing orders...',
                ToastType.info,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.refresh,
                color: Color(0xFF059669),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Color(0xFFB45309), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You are offline. Go online to receive orders.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No Available Orders',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'You\'re all caught up! New delivery requests will appear here as soon as they\'re assigned to you.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(riderAvailableOrdersProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Orders'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['id'] as String? ?? '';
    final orderNo = 'SD-${orderId.substring(0, 4).toUpperCase()}';
    final restaurant = order['restaurant_name'] as String? ?? 'Restaurant';
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;
    final deliveryFee = (order['delivery_fee'] as num?)?.toDouble() ?? 0.0;
    final pickupAddress = order['pickup_address'] as String? ?? '';
    final deliveryAddress = order['delivery_address'] as String? ?? '';
    final timeLeft = _orderTimers[orderId] ?? 30;
    final isUrgent = timeLeft <= 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUrgent ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #$orderNo',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                      Text(
                        restaurant,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'GHS ${total.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUrgent ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUrgent ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 12,
                            color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF059669),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${timeLeft}s',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAddressRow(
                  icon: Icons.store,
                  label: 'Pickup',
                  address: pickupAddress,
                  color: const Color(0xFF059669),
                ),
                const SizedBox(height: 12),
                _buildAddressRow(
                  icon: Icons.location_on,
                  label: 'Delivery',
                  address: deliveryAddress,
                  color: const Color(0xFFDC2626),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Delivery Fee',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                      Text(
                        'GHS ${deliveryFee.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Accept Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectOrder(orderId, orderNo),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Reject',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _acceptOrder(orderId, orderNo),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Accept Order',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow({
    required IconData icon,
    required String label,
    required String address,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _acceptOrder(String orderId, String orderNo) async {
    final service = ref.read(riderServiceProvider);

    _timerInstances[orderId]?.cancel();
    _timerInstances.remove(orderId);
    _orderTimers.remove(orderId);

    ref.read(riderToastsProvider.notifier).add(
      'Accepting order #$orderNo...',
      ToastType.info,
    );

    final success = await service.acceptOrder(orderId);

    if (success) {
      ref.read(riderToastsProvider.notifier).add(
        'Order Accepted! You have successfully accepted this delivery. Navigate to Active Deliveries to begin the trip.',
        ToastType.success,
      );

      ref.invalidate(riderAvailableOrdersProvider);
      ref.invalidate(riderActiveDeliveryProvider);

      await Future.delayed(const Duration(milliseconds: 500));
      context.go('/rider/active-delivery');
    } else {
      ref.read(riderToastsProvider.notifier).add(
        'Unable to Accept Order. Something went wrong while accepting this order. Please try again.',
        ToastType.error,
      );
    }
  }

  Future<void> _rejectOrder(String orderId, String orderNo) async {
    final service = ref.read(riderServiceProvider);

    _timerInstances[orderId]?.cancel();
    _timerInstances.remove(orderId);
    _orderTimers.remove(orderId);

    ref.read(riderToastsProvider.notifier).add(
      'Order #$orderNo rejected.',
      ToastType.info,
    );

    await service.rejectOrder(orderId);
    ref.invalidate(riderAvailableOrdersProvider);
  }
}
