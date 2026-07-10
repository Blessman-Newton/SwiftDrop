import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/merchant_providers.dart';
import '../../providers/rider_providers.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';

class RiderDashboardScreen extends ConsumerStatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  ConsumerState<RiderDashboardScreen> createState() =>
      _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends ConsumerState<RiderDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _toggleController;
  Timer? _ordersRefreshTimer;

  @override
  void initState() {
    super.initState();
    _toggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Auto-refresh available orders every 30 seconds
    _ordersRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        ref.invalidate(riderAvailableOrdersProvider);
      },
    );
  }

  @override
  void dispose() {
    _toggleController.dispose();
    _ordersRefreshTimer?.cancel();
    super.dispose();
  }

  void _toggleOnline() async {
    final current = ref.read(riderOnlineProvider);
    final next = !current;
    final service = ref.read(riderServiceProvider);
    bool success;
    if (next) {
      success = await service.goOnline();
    } else {
      success = await service.goOffline();
    }
    if (mounted && success) {
      ref.read(riderOnlineProvider.notifier).state = next;
      if (next) {
        _toggleController.forward();
        ref.read(riderToastsProvider.notifier).add('You are now online', ToastType.success);
      } else {
        _toggleController.reverse();
        ref.read(riderToastsProvider.notifier).add('You are now offline', ToastType.info);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(riderOnlineProvider);
    final dashboardAsync = ref.watch(riderDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(riderDashboardProvider);
            ref.invalidate(riderTransactionsProvider);
            ref.invalidate(riderAvailableOrdersProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(context),
                const SizedBox(height: 20),
                _buildWelcomeSection(),
                const SizedBox(height: 20),
                _buildOnlineToggle(),
                if (isOnline) ...[
                  const SizedBox(height: 20),
                  _buildPendingOrderBanner(context),
                  const SizedBox(height: 20),
                ],
                const SizedBox(height: 20),
                dashboardAsync.when(
                  data: (data) => _buildEarningsCard(data),
                  loading: () => _buildEarningsCard(null),
                  error: (_, __) => _buildEarningsCard(null),
                ),
                const SizedBox(height: 20),
                dashboardAsync.when(
                  data: (data) => _buildGoalProgressCard(data),
                  loading: () => _buildGoalProgressCard(null),
                  error: (_, __) => _buildGoalProgressCard(null),
                ),
                const SizedBox(height: 20),
                _buildRecentActivityCard(context),
                const SizedBox(height: 20),
                _buildNearbyHotzonesCard(),
                const SizedBox(height: 20),
                _buildTipsSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFDFDFEFF),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Menu',
            child: GestureDetector(
              onTap: () {
                ref
                    .read(riderToastsProvider.notifier)
                    .add('Coming soon in v1.5!', ToastType.info);
              },
              child: const Icon(
                Icons.menu,
                size: 20,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'SwiftDrop',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF059669),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final user = ref.watch(currentUserProvider);
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    final name = user?.displayName ?? 'Rider';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, $name',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Ready for some high-demand shifts?',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineToggle() {
    final isOnline = ref.watch(riderOnlineProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Semantics(
        label: isOnline ? 'Go offline' : 'Go online',
        child: GestureDetector(
          onTap: _toggleOnline,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: double.infinity,
          height: 56,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isOnline
                ? const Color(0xFF059669)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 0.5,
            ),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment:
                    isOnline ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: (MediaQuery.of(context).size.width - 48) * 0.48,
                  height: 48,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(0, 0, 0, 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      isOnline ? Icons.check_circle : Icons.power_settings_new,
                      size: 20,
                      color: isOnline
                          ? const Color(0xFF059669)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isOnline ? 0.0 : 1.0,
                          child: Text(
                            'GO ONLINE',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isOnline ? 1.0 : 0.0,
                          child: Text(
                            'GO OFFLINE',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingOrderBanner(BuildContext context) {
    final availableOrdersAsync = ref.watch(riderAvailableOrdersProvider);
    
    return availableOrdersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final order = orders.first;
        final orderId = order['id'] as String? ?? '';
        final orderNo = 'SD-${orderId.substring(0, 4).toUpperCase()}';
        final total = (order['total'] as num?)?.toDouble() ?? 0.0;
        final deliveryFee = (order['delivery_fee'] as num?)?.toDouble() ?? 0.0;
        final restaurant = order['restaurant_name'] as String? ?? 'Restaurant';
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Semantics(
            label: 'New order offer available, Order $orderNo from $restaurant, pay $deliveryFee dollars. Tap to accept.',
            child: GestureDetector(
              onTap: () => _acceptOrder(context, orderId, orderNo),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color.fromRGBO(5, 150, 105, 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    _BouncingTruckIcon(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEW ORDER OFFER AVAILABLE',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF065F46),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Order #$orderNo - $restaurant - Pay: GHS ${deliveryFee.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to accept',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF059669),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _acceptOrder(BuildContext context, String orderId, String orderNo) async {
    final service = ref.read(riderServiceProvider);
    
    // Show loading toast
    ref.read(riderToastsProvider.notifier).add('Accepting order #$orderNo...', ToastType.info);
    
    final success = await service.acceptOrder(orderId);
    
    if (success) {
      ref.read(riderToastsProvider.notifier).add('Order #$orderNo accepted! Navigate to pickup location.', ToastType.success);
      
      // Refresh available orders and active delivery
      ref.invalidate(riderAvailableOrdersProvider);
      ref.invalidate(riderActiveDeliveryProvider);
      
      // Small delay to allow backend to update
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Navigate to active delivery screen
      context.go('/rider/active-delivery');
    } else {
      ref.read(riderToastsProvider.notifier).add('Failed to accept order. Please try again.', ToastType.error);
    }
  }

  Widget _buildEarningsCard(Map<String, dynamic>? data) {
    final todayEarnings = (data?['today_earnings'] as num?)?.toDouble() ?? 0.0;
    final todayTrips = data?['today_trips'] as int? ?? 0;
    final todayDistance = (data?['today_distance'] as num?)?.toDouble() ?? 0.0;
    final todayActiveTime = data?['today_active_time'] as int? ?? 0;
    final activeHours = todayActiveTime ~/ 60;
    final activeMins = todayActiveTime % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF1F5F9),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.03),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "TODAY'S EARNINGS",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(5, 150, 105, 0.1),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.trending_up,
                        size: 12,
                        color: Color(0xFF059669),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+12%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'GHS ${todayEarnings.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 1,
              color: const Color(0xFFF8FAFC),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatColumn('TRIPS', '$todayTrips'),
                _buildStatColumn('DISTANCE', '${todayDistance.toStringAsFixed(1)} km'),
                _buildStatColumn('ACTIVE', '${activeHours}h ${activeMins}m'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgressCard(Map<String, dynamic>? data) {
    final dailyGoal = (data?['daily_goal'] as num?)?.toDouble() ?? 200.0;
    final goalProgress = (data?['goal_progress'] as num?)?.toDouble() ?? 0.0;
    final todayEarnings = (data?['today_earnings'] as num?)?.toDouble() ?? 0.0;
    final remaining = dailyGoal - todayEarnings;
    final remainingStr = remaining > 0 ? remaining.toStringAsFixed(2) : '0.00';
    final progressFraction = (goalProgress / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF047857),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(4, 120, 87, 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 16,
                  color: Color(0xFFD1FAE5),
                ),
                const SizedBox(width: 8),
                Text(
                  'DAILY GOAL PROGRESS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD1FAE5),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'GHS ${dailyGoal.toStringAsFixed(2)} Goal',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goalProgress.toStringAsFixed(0)}% Reached',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD1FAE5),
                  ),
                ),
                Text(
                  'GHS $remainingStr left',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD1FAE5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(2, 44, 34, 0.4),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: FractionallySizedBox(
                widthFactor: progressFraction,
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              goalProgress >= 100
                  ? 'Congratulations! You hit your daily bonus!'
                  : 'Complete more orders to hit your daily bonus!',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color.fromRGBO(209, 250, 229, 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(BuildContext context) {
    final transactionsAsync = ref.watch(riderTransactionsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF1F5F9),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.03),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/rider/earnings'),
                    child: Text(
                      'View All',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              height: 1,
              color: const Color(0xFFF8FAFC),
            ),
            transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No recent activity',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: transactions.take(3).map((tx) {
                    final isLast = tx == transactions.take(3).last;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  tx['is_bonus'] == true
                                      ? Icons.star
                                      : Icons.local_shipping_rounded,
                                  color: const Color(0xFF059669),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx['title'] ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tx['created_at'] ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'GHS ${((tx['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isLast)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              width: double.infinity,
                              height: 1,
                              color: const Color(0xFFF8FAFC),
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Failed to load activity',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyHotzonesCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF1F5F9),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.03),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby Hotzones',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    '1.5x Boost',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE11D48),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: (MediaQuery.of(context).size.height * 0.24).clamp(120.0, 176.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color(0xFFE2E8F0),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GridPainter(),
                      ),
                    ),
                    Positioned(
                      left: 50,
                      top: 30,
                      child: _PulsingCircle(
                        color: const Color.fromRGBO(239, 68, 68, 0.2),
                        size: 80,
                      ),
                    ),
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: _PulsingCircle(
                        color: const Color.fromRGBO(239, 68, 68, 0.2),
                        size: 60,
                      ),
                    ),
                    const Positioned(
                      left: 62,
                      top: 58,
                      child: Text(
                        'Downtown',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                    const Positioned(
                      right: 28,
                      bottom: 44,
                      child: Text(
                        'East Wharf',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _RiderDot(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color.fromRGBO(20, 184, 166, 0.15),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    size: 18,
                    color: Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pro-Tip',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lunch demand is peaking early in Downtown. Position yourself near the waterfront by 11:30 AM for the best order flow.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color.fromRGBO(245, 158, 11, 0.15),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shield,
                    size: 18,
                    color: Color(0xFFB45309),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Safety',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rain is expected in 45 minutes. Consider wrapping up current deliveries or accepting shorter-distance orders.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BouncingTruckIcon extends StatefulWidget {
  @override
  State<_BouncingTruckIcon> createState() => _BouncingTruckIconState();
}

class _BouncingTruckIconState extends State<_BouncingTruckIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -3 * (_controller.value * 2 - 1).abs()),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromRGBO(148, 163, 184, 0.3)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double j = 0; j < size.height; j += 30) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PulsingCircle extends StatefulWidget {
  final Color color;
  final double size;

  const _PulsingCircle({required this.color, required this.size});

  @override
  State<_PulsingCircle> createState() => _PulsingCircleState();
}

class _PulsingCircleState extends State<_PulsingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size * (0.8 + _controller.value * 0.2),
          height: widget.size * (0.8 + _controller.value * 0.2),
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _RiderDot extends StatefulWidget {
  const _RiderDot();

  @override
  State<_RiderDot> createState() => _RiderDotState();
}

class _RiderDotState extends State<_RiderDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 0.8 + _controller.value * 0.4;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(5, 150, 105, 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
