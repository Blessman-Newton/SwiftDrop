import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../providers/merchant_providers.dart';
import '../../providers/providers.dart';
import '../../providers/rider_providers.dart';

import '../../models/models.dart';

class RiderActiveDeliveryScreen extends ConsumerStatefulWidget {
  const RiderActiveDeliveryScreen({super.key});

  @override
  ConsumerState<RiderActiveDeliveryScreen> createState() =>
      _RiderActiveDeliveryScreenState();
}

class _RiderActiveDeliveryScreenState
    extends ConsumerState<RiderActiveDeliveryScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _pingController;
  late Animation<double> _pingAnimation;
  late AnimationController _phoneBounceController;
  late Animation<double> _phoneBounceAnimation;

  bool _isCalling = false;
  bool _isSupporting = false;
  Timer? _callTimer;
  Timer? _supportTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _pingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pingController, curve: Curves.easeOut),
    );

    _phoneBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _phoneBounceAnimation = Tween<double>(begin: 0.0, end: -12.0).animate(
      CurvedAnimation(parent: _phoneBounceController, curve: Curves.easeInOut),
    );

    // Refresh active delivery data from API
    Future.microtask(() => ref.invalidate(riderActiveDeliveryProvider));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pingController.dispose();
    _phoneBounceController.dispose();
    _callTimer?.cancel();
    _supportTimer?.cancel();
    super.dispose();
  }

  void _startCall() {
    setState(() => _isCalling = true);
    ref.read(riderToastsProvider.notifier).add('Connecting line to customer...', ToastType.info);
    _callTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isCalling = false);
        ref.read(riderToastsProvider.notifier).add('Call ended.', ToastType.info);
      }
    });
  }

  void _startSupport() {
    setState(() => _isSupporting = true);
    ref.read(riderToastsProvider.notifier).add('Opening support chat thread...', ToastType.info);
    _supportTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isSupporting = false);
        ref.read(riderToastsProvider.notifier).add('Support session ended.', ToastType.info);
      }
    });
  }

  void _advanceDeliveryState() async {
    final service = ref.read(riderServiceProvider);
    final current = ref.read(deliveryStateProvider);
    switch (current) {
      case DeliveryState.enRoute:
        final success = await service.updateDeliveryStatus('arrived');
        if (mounted && success) {
          ref.read(deliveryStateProvider.notifier).state = DeliveryState.arrived;
          ref.read(riderToastsProvider.notifier).add('Status updated: Arrived at pickup. Please verify order items.', ToastType.success);
        }
        break;
      case DeliveryState.arrived:
        final success = await service.updateDeliveryStatus('picked_up');
        if (mounted && success) {
          ref.read(deliveryStateProvider.notifier).state = DeliveryState.collected;
          ref.read(riderToastsProvider.notifier).add('Items collected! Route configured for dropoff.', ToastType.success);
        }
        break;
      case DeliveryState.collected:
        final success = await service.updateDeliveryStatus('delivered');
        if (mounted && success) {
          ref.read(riderToastsProvider.notifier).add('Delivery completed! GPS Navigation Guide finished.', ToastType.success);
          ref.invalidate(riderActiveDeliveryProvider);
          ref.invalidate(riderDashboardProvider);
          context.go('/rider/dashboard');
        }
        break;
    }
  }

  DeliveryInfo _getDeliveryInfo() {
    final linkedOrder = ref.watch(riderAssignedOrderProvider);
    if (linkedOrder != null) {
      return DeliveryInfo(
        orderNo: linkedOrder.id.replaceFirst('ord_', '#SD-'),
        items: linkedOrder.items.map((ci) => ci.foodItem.name).toList(),
        pickupName: linkedOrder.restaurantName,
        pickupAddress: '455 West Grand Ave',
        dropoffAddress: '123 Oak St',
        dropoffDetails: 'Unit 4B (Gate code: 1234)',
        total: linkedOrder.totalPrice,
        estimatedTime: '8 mins',
      );
    }
    final deliveryAsync = ref.read(riderActiveDeliveryProvider);
    return deliveryAsync.when(
      data: (data) {
        if (data == null) {
          return DeliveryInfo(
            orderNo: 'No active delivery',
            items: [],
            pickupName: '',
            pickupAddress: '',
            dropoffAddress: '',
            dropoffDetails: '',
            total: 0,
            estimatedTime: '',
          );
        }
        final items = (data['items'] as List?)
                ?.map((i) => i['name']?.toString() ?? '')
                .toList() ??
            [];
        return DeliveryInfo(
          orderNo: data['order_no'] ?? '',
          items: items,
          pickupName: data['restaurant_name'] ?? '',
          pickupAddress: data['pickup_address'] ?? '',
          dropoffAddress: data['delivery_address'] ?? '',
          dropoffDetails: data['delivery_notes'] ?? '',
          total: (data['total'] as num?)?.toDouble() ?? 0,
          estimatedTime: '8 mins',
        );
      },
      loading: () => DeliveryInfo(
        orderNo: 'Loading...',
        items: [],
        pickupName: '',
        pickupAddress: '',
        dropoffAddress: '',
        dropoffDetails: '',
        total: 0,
        estimatedTime: '',
      ),
      error: (_, __) => DeliveryInfo(
        orderNo: 'Error',
        items: [],
        pickupName: '',
        pickupAddress: '',
        dropoffAddress: '',
        dropoffDetails: '',
        total: 0,
        estimatedTime: '',
      ),
    );
  }

  void _resetDeliveryState() {
    ref.read(deliveryStateProvider.notifier).state = DeliveryState.enRoute;
    ref.read(riderToastsProvider.notifier).add('Reset delivery task to initial state', ToastType.info);
  }

  String _ctaLabel(DeliveryState state) {
    switch (state) {
      case DeliveryState.enRoute:
        return 'Arrived at Pickup';
      case DeliveryState.arrived:
        return 'Confirm Collection (${_getDeliveryInfo().items.length} Items)';
      case DeliveryState.collected:
        return 'Start Navigation to Dropoff';
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryStateProvider);
    final deliveryAsync = ref.watch(riderActiveDeliveryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF4),
      body: SafeArea(
        child: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(),
              deliveryAsync.when(
                data: (data) {
                  if (data == null) {
                    return _buildNoActiveDelivery();
                  }
                  return Expanded(
                    child: Column(
                      children: [
                        _buildMapSection(deliveryState),
                        _buildDeliverySheet(deliveryState),
                      ],
                    ),
                  );
                },
                loading: () => const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => _buildNoActiveDelivery(),
              ),
            ],
          ),
          if (_isCalling) _buildCallingOverlay(),
          if (_isSupporting) _buildSupportOverlay(),
          _buildBottomNav(),
        ],
        ),
      ),
    );
  }

  Widget _buildNoActiveDelivery() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Delivery',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accept an order from the dashboard to start delivering',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/rider/dashboard'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/rider/dashboard'),
              child: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF334155)),
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
              onTap: () {
                ref.invalidate(riderActiveDeliveryProvider);
                ref.read(riderToastsProvider.notifier).add('Refreshing delivery data...', ToastType.info);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.refresh,
                    size: 18,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection(DeliveryState deliveryState) {
    final isCollected = deliveryState == DeliveryState.collected;

    return SizedBox(
      height: 256,
      width: double.infinity,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFE2E8F0),
          ),
          CustomPaint(
            size: const Size(double.infinity, 256),
            painter: _MapGridPainter(),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x1A0F172A),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Floating ETA card - bottom left
          Positioned(
            left: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xF2FFFFFF),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x1A000000),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.navigation, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isCollected ? 'To Dropoff' : 'To Pickup',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCollected ? '6 mins' : '8 mins',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Recenter button - bottom right
          Positioned(
            right: 16,
            bottom: 16,
            child: GestureDetector(
              onTap: () => ref.read(riderToastsProvider.notifier).add('Re-centering map onto your current position...', ToastType.info),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xF2FFFFFF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x1A000000),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.navigation, size: 18, color: Color(0xFF059669)),
                ),
              ),
            ),
          ),
          // Pulsing marker - top 38% left 45%
          Positioned(
            top: 97,
            left: 169,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _pingAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(16, 185, 129, 0.3 * (1.0 - _pingAnimation.value)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color.fromRGBO(16, 185, 129, 0.6 * (1.0 - _pingAnimation.value)),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x40000000),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
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

  Widget _buildDeliverySheet(DeliveryState deliveryState) {
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 30,
                offset: Offset(0, -10),
              ),
            ],
            border: const Border(
              top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grip handle
                Center(
                  child: Container(
                    width: 48,
                    height: 6,
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ),
                // Task header
                _buildTaskHeader(deliveryState),
                const SizedBox(height: 20),
                // Pickup card
                _buildPickupCard(deliveryState),
                const SizedBox(height: 14),
                // Dropoff card
                _buildDropoffCard(deliveryState),
                const SizedBox(height: 24),
                // Contact buttons
                _buildContactButtons(),
                const SizedBox(height: 24),
                // Primary CTA
                _buildPrimaryCTA(deliveryState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskHeader(DeliveryState deliveryState) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Task',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'Order #${_getDeliveryInfo().orderNo}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _resetDeliveryState,
                    child: Text(
                      'Reset Order state',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: const Color(0xFFD1FAE5)),
          ),
          child: Text(
            '${_getDeliveryInfo().items.length} Items',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF047857),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickupCard(DeliveryState deliveryState) {
    final isActive = deliveryState == DeliveryState.enRoute;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0x0D10B981)
            : const Color(0xF2F8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? const Color(0x4D10B981)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_shipping, size: 20, color: Color(0xFF059669)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _getDeliveryInfo().pickupName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getDeliveryInfo().pickupAddress,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Ready in 2m',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                    ),
                    if (deliveryState != DeliveryState.enRoute) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Items Collected',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/rider/navigation'),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x0D000000),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.navigation, size: 16, color: Color(0xFF059669)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropoffCard(DeliveryState deliveryState) {
    final isActive = deliveryState == DeliveryState.collected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0x0D10B981)
            : const Color(0xF2F8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? const Color(0x4D10B981)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on, size: 20, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dropoff',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _getDeliveryInfo().dropoffAddress,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getDeliveryInfo().dropoffDetails,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _startCall,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x0AE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Icon(
                        Icons.phone,
                        size: 16,
                        color: const Color(0xFF059669),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Call Customer',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _startSupport,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x0AE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.help_outline, size: 16, color: Color(0xFFF43F5E)),
                  const SizedBox(width: 8),
                  Text(
                    'Support Chat',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryCTA(DeliveryState deliveryState) {
    return GestureDetector(
      onTap: _advanceDeliveryState,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF059669),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0x26059669),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _ctaLabel(deliveryState),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallingOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xE60F172A),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _phoneBounceAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _phoneBounceAnimation.value),
                  child: const Icon(Icons.phone, size: 48, color: Color(0xFF10B981)),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Simulating Secure Phone Call...',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Calling: customer via masked line',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                _callTimer?.cancel();
                setState(() => _isCalling = false);
                ref.read(riderToastsProvider.notifier).add('Call ended.', ToastType.info);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D48),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'End Call',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xE60F172A),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Icon(Icons.message, size: 48, color: const Color(0xFFF43F5E));
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Connecting SwiftDrop Dispatch...',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Live agent secure session',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                _supportTimer?.cancel();
                setState(() => _isSupporting = false);
                ref.read(riderToastsProvider.notifier).add('Support session ended.', ToastType.info);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'Close Thread',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 64 + MediaQuery.of(context).padding.bottom,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: const Color(0xF2FFFFFF),
          border: const Border(
            top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildNavItem(Icons.dashboard_rounded, 'Dashboard', false, () => context.go('/rider/dashboard')),
            _buildNavItem(Icons.local_shipping, 'Orders', true, () {}),
            _buildNavItem(Icons.account_balance_wallet_rounded, 'Earnings', false, () => context.go('/rider/earnings')),
            _buildNavItem(Icons.person, 'Profile', false, () {
              ref.read(riderToastsProvider.notifier).add('Alex is a Level 4 Platinum Courier with 98% Rating', ToastType.success);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? const Color(0xFF059669) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isActive ? const Color(0xFF059669) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final roadPaint = Paint()
      ..color = const Color(0x1FFFFFFF)
      ..strokeWidth = 2;

    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.3), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.7), roadPaint);
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.25, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.6, 0), Offset(size.width * 0.6, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
