import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../services/order_service.dart';
import '../services/tomtom_service.dart';
import '../theme/app_theme.dart';

class MapTrackingScreen extends ConsumerStatefulWidget {
  const MapTrackingScreen({super.key});

  @override
  ConsumerState<MapTrackingScreen> createState() => _MapTrackingScreenState();
}

class _MapTrackingScreenState extends ConsumerState<MapTrackingScreen>
    with SingleTickerProviderStateMixin {
  bool _isOfflineCached = false;
  bool _isSyncing = false;
  int _activeStep = 0;
  int _zoomLevel = 14;
  Timer? _orderPollTimer;
  Timer? _riderLocationTimer;
  Timer? _mapTimer;
  AnimationController? _pulseController;

  // Chat state
  bool _isChatOpen = false;
  final TextEditingController _chatInputController = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [
    {
      'id': 'msg_init',
      'text':
          'Hi there! I am your SwiftDrop courier today. Let me know if you have any special drop-off instructions!',
      'sender': 'driver',
      'timestamp': 'Just now',
    }
  ];
  bool _isDriverTyping = false;

  // Call state
  bool _isCalling = false;
  String? _callState;
  int _callDuration = 0;
  Timer? _callTimer;

  // Notification state
  bool _notificationGranted = false;
  Map<String, dynamic>? _inAppNotification;

  // Feedback state
  bool _showFeedbackModal = false;
  int _restaurantRating = 0;
  int _deliveryRating = 0;
  List<String> _selectedTags = [];
  bool _isFeedbackSubmitted = false;

  Future<void> _saveFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final feedback = {
      'restaurantRating': _restaurantRating,
      'deliveryRating': _deliveryRating,
      'tags': _selectedTags,
      'timestamp': DateTime.now().toIso8601String(),
    };
    final existing = prefs.getStringList('swiftdrop_feedback') ?? [];
    existing.add(jsonEncode(feedback));
    await prefs.setStringList('swiftdrop_feedback', existing);
  }

  // Step tooltip state
  bool _showStepTooltip = false;
  int _tooltipStep = 0;

  // 3D view state
  bool _is3DView = false;

  // Real map state
  final MapController _mapController = MapController();
  final TomTomService _tomtom = TomTomService();
  bool _mapReady = false;
  LatLng _mapCenter = TomTomService.defaultCenter;
  List<LatLng> _routePoints = [];
  LatLng? _driverPosition;
  LatLng? _destinationPosition;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _startMapAnimation();
    _loadOrderRoute();
    _startOrderPolling();
  }

  void _loadOrderRoute() {
    final orders = ref.read(ordersProvider);
    final activeOrder = orders.where((o) => o.status.isActive).toList();
    if (activeOrder.isNotEmpty) {
      final order = activeOrder.first;
      final pickup = TomTomService.parseLatLng(order.pickupLat, order.pickupLng);
      final delivery = TomTomService.parseLatLng(order.deliveryLat, order.deliveryLng);
      setState(() {
        _destinationPosition = delivery;
        _mapCenter = pickup;
        _driverPosition = pickup;
      });
      _calculateRoute(pickup, delivery);
    }
  }

  Future<void> _calculateRoute(LatLng origin, LatLng destination) async {
    final route = await _tomtom.calculateRoute(origin, destination);
    if (route != null && mounted) {
      setState(() {
        _routePoints = route.points;
      });
      if (_mapReady && route.points.isNotEmpty) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(route.points),
            padding: const EdgeInsets.all(60),
          ),
        );
      }
    }
  }

  int _statusToStep(String? apiStatus) {
    switch (apiStatus) {
      case 'CREATED': return 0;
      case 'CONFIRMED':
      case 'PREPARING': return 1;
      case 'READY_FOR_PICKUP':
      case 'PICKED_UP': return 2;
      case 'EN_ROUTE': return 2;
      case 'DELIVERED': return 3;
      default: return 0;
    }
  }

  void _startOrderPolling() {
    _orderPollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      try {
        final orderService = OrderService();
        final orders = await orderService.listOrders();
        if (orders.isNotEmpty && mounted) {
          final active = orders.firstWhere(
            (o) => o['status'] != 'DELIVERED' && o['status'] != 'CANCELLED',
            orElse: () => {},
          );
          if (active.isNotEmpty) {
            final newStep = _statusToStep(active['status']);
            if (newStep != _activeStep) {
              setState(() => _activeStep = newStep);
            }
            // Start rider location polling when order is picked up
            if ((active['status'] == 'PICKED_UP' || active['status'] == 'EN_ROUTE') &&
                _riderLocationTimer == null) {
              _startRiderLocationPolling();
            }
          }
        }
      } catch (_) {}
    });
  }

  void _startRiderLocationPolling() {
    _riderLocationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      try {
        final orderService = OrderService();
        final orders = await orderService.listOrders();
        if (orders.isNotEmpty) {
          final active = orders.firstWhere(
            (o) => o['status'] != 'DELIVERED' && o['status'] != 'CANCELLED',
            orElse: () => {},
          );
          if (active.isNotEmpty) {
            final riderLat = active['rider_lat'] as num?;
            final riderLng = active['rider_lng'] as num?;
            if (riderLat != null && riderLng != null && mounted) {
              final newPos = LatLng(riderLat.toDouble(), riderLng.toDouble());
              setState(() {
                _driverPosition = newPos;
              });
            }
          }
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _orderPollTimer?.cancel();
    _riderLocationTimer?.cancel();
    _mapTimer?.cancel();
    _callTimer?.cancel();
    _pulseController?.dispose();
    _chatInputController.dispose();
    super.dispose();
  }

  void _startMapAnimation() {
    _mapTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) setState(() {});
    });
  }

  void _showInAppNotification(String title, String body) {
    setState(() => _inAppNotification = {'title': title, 'body': body, 'visible': true});
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _inAppNotification = null);
    });
  }

  Map<String, dynamic> _getStepDetails(int step) {
    final activeOrder = ref.watch(activeOrderProvider);
    final apiStatus = activeOrder?.status;

    // Calculate ETA from route if available
    String eta = '...';
    if (_routePoints.isNotEmpty && step >= 2) {
      double totalDist = 0;
      for (int i = 1; i < _routePoints.length; i++) {
        final dlat = _routePoints[i].latitude - _routePoints[i - 1].latitude;
        final dlng = _routePoints[i].longitude - _routePoints[i - 1].longitude;
        totalDist += sqrt(dlat * dlat + dlng * dlng) * 111320;
      }
      final mins = (totalDist / 500).round();
      eta = mins > 0 ? '$mins' : '...';
    }

    switch (step) {
      case 0:
        return {
          'status': 'Order Received',
          'description': 'Waiting for restaurant to confirm your order.',
          'eta': eta == '...' ? '...' : eta,
        };
      case 1:
        return {
          'status': 'Preparing',
          'description': 'The kitchen is crafting your selection.',
          'eta': eta == '...' ? '...' : eta,
        };
      case 2:
        return {
          'status': 'On the Way',
          'description': 'Your rider is heading to you.',
          'eta': eta,
        };
      default:
        return {
          'status': 'Delivered',
          'description': 'Your order has been delivered. Enjoy!',
          'eta': '0',
        };
    }
  }

  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _chatMessages.add({
        'id': 'msg_user_${DateTime.now().millisecondsSinceEpoch}',
        'text': text,
        'sender': 'user',
        'timestamp': 'Just now',
      });
      _chatInputController.clear();
      _isDriverTyping = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      String reply = 'Understood! I am on it.';
      final lower = text.toLowerCase();
      if (lower.contains('door') || lower.contains('leave')) {
        reply = 'Got it! I will leave it by your door.';
      } else if (lower.contains('nearby') || lower.contains('where')) {
        reply = 'Yes, I am heading your way now. Should be there shortly!';
      } else if (lower.contains('thanks') || lower.contains('thank')) {
        reply = 'No problem! Enjoy your meal.';
      }
      setState(() {
        _isDriverTyping = false;
        _chatMessages.add({
          'id': 'msg_reply_${DateTime.now().millisecondsSinceEpoch}',
          'text': reply,
          'sender': 'driver',
          'timestamp': 'Just now',
        });
      });
    });
  }

  void _startCall() {
    setState(() {
      _isCalling = true;
      _callState = 'ringing';
      _callDuration = 0;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _callState = 'connected');
      _callTimer?.cancel();
      _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _callDuration++);
      });
    });
  }

  void _endCall() {
    _callTimer?.cancel();
    setState(() => _callState = 'ended');
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() {
        _isCalling = false;
        _callState = null;
        _callDuration = 0;
      });
    });
  }

  String _formatCallTime(int secs) {
    final mins = secs ~/ 60;
    final rem = secs % 60;
    return '$mins:${rem < 10 ? '0' : ''}$rem';
  }

  Widget _buildNoActiveOrder(bool isDark) {
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.map_outlined,
                    size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'No active deliveries',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'When you place an order, live tracking will show up here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary(isDark),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.restaurant_menu, size: 18),
                label: const Text('Browse & order'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/orders'),
                child: Text(
                  'View order history',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeOrder = ref.watch(activeOrderProvider);

    // No active delivery — show an honest empty state instead of a fake track.
    if (activeOrder == null) {
      return _buildNoActiveOrder(isDark);
    }

    final stepDetails = _getStepDetails(_activeStep);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildMap(isDark)),
            ],
          ),
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.38,
            child: _buildZoomControls(isDark),
          ),
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.38 - 56,
            child: _buildViewToggleFAB(isDark),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: _buildPlayPauseButton(),
          ),
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 12,
            child: _buildNotificationBell(),
          ),
          if (_showStepTooltip) _buildStepTooltip(isDark),
          _buildBottomPanel(stepDetails, isDark),
          if (_isChatOpen) _buildChatModal(isDark),
          if (_isCalling) _buildCallModal(),
          if (_showFeedbackModal) _buildFeedbackModal(isDark),
          if (_inAppNotification != null && _inAppNotification!['visible'])
            _buildInAppNotification(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF18233c).withOpacity(0.9)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Semantics(
              label: 'Go to home',
              child: GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Tracking',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Order ID: #SD-5291',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              label: _isOfflineCached ? 'Offline mode enabled, tap to sync' : 'Tap to cache for offline',
              child: GestureDetector(
                onTap: () {
                  setState(() => _isSyncing = true);
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    setState(() {
                      _isSyncing = false;
                      _isOfflineCached = !_isOfflineCached;
                    });
                  });
                },
                child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isOfflineCached
                      ? Colors.amber.shade100.withOpacity(0.8)
                      : const Color(0xFF10b981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _isOfflineCached
                        ? Colors.amber.shade300.withOpacity(0.4)
                        : AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSyncing)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: _isOfflineCached ? Colors.amber : AppColors.primary,
                        ),
                      )
                    else if (_isOfflineCached) ...[
                      Icon(Icons.wifi_off_rounded,
                          size: 13, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'OFFLINE CACHE',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber.shade700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ] else ...[
                      Icon(Icons.wifi_rounded,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'ONLINE',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
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

  Widget _buildMap(bool isDark) {
    return ClipRRect(
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _mapCenter,
          initialZoom: 14,
          maxZoom: 19,
          minZoom: 1,
          onMapReady: () => _mapReady = true,
        ),
        children: [
          TileLayer(
            urlTemplate: TomTomService.tileUrl,
            userAgentPackageName: 'com.swiftdrop.app',
          ),
          if (_routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routePoints,
                  color: AppColors.primary,
                  strokeWidth: 5,
                ),
              ],
            ),
          MarkerLayer(
            markers: [
              if (_driverPosition != null)
                Marker(
                  point: _driverPosition!,
                  width: 44,
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                      ],
                    ),
                    child: const Icon(Icons.local_shipping, color: Colors.white, size: 20),
                  ),
                ),
              if (_destinationPosition != null)
                Marker(
                  point: _destinationPosition!,
                  width: 44,
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                      ],
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 22),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls(bool isDark) {
    final bgColor =
        isDark ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.95);
    return Column(
      children: [
        _buildControlBtn(
          Icons.add_rounded, bgColor, isDark, () {
          if (_mapReady) {
            final zoom = _mapController.camera.zoom + 1;
            _mapController.move(_mapController.camera.center, zoom);
          }
        }),
        const SizedBox(height: 8),
        _buildControlBtn(
          Icons.remove_rounded, bgColor, isDark, () {
          if (_mapReady) {
            final zoom = _mapController.camera.zoom - 1;
            _mapController.move(_mapController.camera.center, zoom);
          }
        }),
        const SizedBox(height: 8),
        _buildControlBtn(
          Icons.navigation_rounded, bgColor, isDark, () {
          if (_mapReady && _driverPosition != null) {
            _mapController.move(_driverPosition!, 15);
          }
        },
            color: AppColors.primary),
      ],
    );
  }

  Widget _buildViewToggleFAB(bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _is3DView = !_is3DView),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _is3DView ? Icons.view_in_ar : Icons.map_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            Text(
              _is3DView ? '3D' : '2D',
              style: GoogleFonts.inter(
                fontSize: 7,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBtn(IconData icon, Color bg, bool isDark, VoidCallback onTap,
      {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: color ?? (isDark ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _activeStep == 3 ? Colors.green : AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _activeStep == 3 ? 'Delivered' : 'Live Tracking',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBell() {
    return GestureDetector(
      onTap: () {
        setState(() => _notificationGranted = !_notificationGranted);
        if (_notificationGranted) {
          _showInAppNotification(
              'Notifications Enabled', 'You will receive push alerts for delivery updates.');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _notificationGranted
              ? const Color(0xFF10b981).withOpacity(0.15)
              : Colors.grey.shade100,
          shape: BoxShape.circle,
          border: _notificationGranted
              ? Border.all(color: AppColors.primary.withOpacity(0.2))
              : null,
        ),
        child: Stack(
          children: [
            Icon(
              _notificationGranted
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              size: 18,
              color: _notificationGranted ? AppColors.primary : Colors.grey,
            ),
            if (!_notificationGranted)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(Map<String, dynamic> stepDetails, bool isDark) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 60,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF18233c).withOpacity(0.95)
              : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStepHeader(stepDetails, isDark),
            const SizedBox(height: 12),
            _buildStepper(isDark),
            const SizedBox(height: 14),
            _buildCourierInfo(stepDetails, isDark),
            const SizedBox(height: 12),
            _buildContactButtons(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader(Map<String, dynamic> stepDetails, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _activeStep == 3 ? Colors.green : AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              stepDetails['status'],
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        ],
    );
  }

  Widget _buildStepper(bool isDark) {
    final steps = ['Received', 'Preparing', 'Out for Delivery', 'Delivered'];
    final icons = [
      Icons.receipt_long_rounded,
      Icons.restaurant_rounded,
      Icons.delivery_dining_rounded,
      Icons.location_on_rounded,
    ];

    return Column(
      children: [
        SizedBox(
          height: 36,
          child: Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final segIdx = index ~/ 2;
                final filled = segIdx < _activeStep;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: filled
                          ? AppColors.primary
                          : (isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }
              final stepIdx = index ~/ 2;
              final isActive = stepIdx == _activeStep;
              final isCompleted = stepIdx < _activeStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : isCompleted
                          ? AppColors.primary
                          : (isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade100),
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isCompleted ? Icons.check_rounded : icons[stepIdx],
                  size: 14,
                  color: (isActive || isCompleted)
                      ? Colors.white
                      : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (i) {
            final isActive = i == _activeStep;
            final isCompleted = i < _activeStep;
            return SizedBox(
              width: 72,
              child: Text(
                steps[i],
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: isActive
                      ? AppColors.primary
                      : isCompleted
                          ? (isDark ? Colors.grey.shade300 : Colors.grey.shade700)
                          : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                  letterSpacing: 0.3,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCourierInfo(Map<String, dynamic> stepDetails, bool isDark) {
    final activeOrder = ref.watch(activeOrderProvider);
    final restaurantName = activeOrder?.restaurantName ?? 'Restaurant';
    final riderName = activeOrder?.riderName ?? 'Assigned Rider';

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF10b981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.delivery_dining_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                restaurantName,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                stepDetails['description'],
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              stepDetails['eta'],
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Mins ETA',
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactButtons(bool isDark) {
    final activeOrder = ref.watch(activeOrderProvider);
    final riderName = activeOrder?.riderName ?? 'Assigned Rider';

    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                riderName,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'Status: ${_activeStep == 3 ? "Delivered" : "Active"}',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (_activeStep == 3)
                Semantics(
                  label: 'Rate order',
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showFeedbackModal = true;
                        _isFeedbackSubmitted = false;
                      });
                    },
                    child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade500,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.shade300.withOpacity(0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Rate Order',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                )
              else ...[
                Semantics(
                  label: 'Chat with rider',
                  child: GestureDetector(
                    onTap: () => setState(() => _isChatOpen = true),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10b981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Chat',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Semantics(
                  label: 'Call rider',
                  child: GestureDetector(
                    onTap: _startCall,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_rounded,
                              size: 13, color: Colors.blue.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Call',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepTooltip(bool isDark) {
    final details = _getStepDetails(_tooltipStep);
    return Positioned(
      left: 16,
      right: 16,
      bottom: 340,
      child: GestureDetector(
        onTap: () => setState(() => _showStepTooltip = false),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _showStepTooltip ? 1.0 : 0.0,
          child: _showStepTooltip
              ? Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18233c) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.delivery_dining_rounded, color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SwiftRider #42',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  details['status'],
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTooltipStat('ETA', '${details['eta']} min', isDark),
                          _buildTooltipStat('Status', _activeStep == 3 ? 'Done' : 'Active', isDark),
                          _buildTooltipStat('Rating', '4.9 ★', isDark),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildTooltipStat(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildChatModal(bool isDark) {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: isDark ? AppColors.darkBackground : Colors.white,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18233c) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.grey.shade100,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10b981).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.person_rounded,
                              color: AppColors.primary, size: 22),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10b981),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF18233c)
                                      : Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SwiftRider #42',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Your Courier',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade400,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isChatOpen = false),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 18, color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _chatMessages.length + (_isDriverTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _chatMessages.length) {
                      return _buildTypingIndicator();
                    }
                    return _buildChatBubble(_chatMessages[index], isDark);
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.grey.shade100,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'Leave at the door!',
                      'Are you nearby?',
                      'Call me when you arrive.',
                      'Thank you!'
                    ]
                        .map((p) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => _handleSendMessage(p),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF18233c)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.grey.shade100,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    p,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18233c) : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.grey.shade100,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatInputController,
                        onSubmitted: _handleSendMessage,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Send a message...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF10b981)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          _handleSendMessage(_chatInputController.text),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, bool isDark) {
    final isMe = msg['sender'] == 'user';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary
              : (isDark ? const Color(0xFF18233c) : Colors.grey.shade100),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg['text'],
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg['timestamp'],
              style: GoogleFonts.inter(
                fontSize: 8,
                color: isMe
                    ? Colors.white.withOpacity(0.6)
                    : Colors.grey.shade400,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF18233c)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallModal() {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: Colors.grey.shade900.withOpacity(0.97),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(),
                Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade700),
                      ),
                      child: Icon(Icons.person_rounded,
                          size: 50, color: Colors.green.shade400),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'SwiftRider #42',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your SwiftDrop Courier',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade400,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _callState == 'ringing'
                            ? 'Ringing...'
                            : _callState == 'connected'
                                ? 'Connected'
                                : 'Call Ended',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.green.shade400,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _callState == 'connected'
                          ? _formatCallTime(_callDuration)
                          : '0:00',
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        color: Colors.grey.shade300,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: _endCall,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call_end_rounded,
                            size: 30, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'End Call',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade400,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackModal(bool isDark) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showFeedbackModal = false),
        child: Container(
          color: Colors.black54.withOpacity(0.6),
          child: GestureDetector(
            onTap: () {},
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18233c) : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.shade100,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFeedbackHeader(isDark),
                    Flexible(
                      child: _isFeedbackSubmitted
                          ? _buildFeedbackSuccess()
                          : _buildFeedbackBody(isDark),
                    ),
                    _buildFeedbackFooter(isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.amber.shade100.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade600),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Feedback',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'Rate Restaurant & Courier',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade400,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showFeedbackModal = false),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded,
                  size: 18, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBody(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildRatingSection(
            'Rate Restaurant & Food',
            'The Burger Loft',
            _restaurantRating,
            (v) => setState(() => _restaurantRating = v),
            const ['Poor / Cold Food', 'Could be better', 'Good & Tasty',
                'Great Selection!', 'Exceptional Quality!'],
            isDark,
          ),
          const SizedBox(height: 20),
          _buildRatingSection(
            'Rate Delivery Driver',
            'SwiftRider #42',
            _deliveryRating,
            (v) => setState(() => _deliveryRating = v),
            const ['Slow / Unprofessional', 'Below Expectations',
                'Friendly & Standard', 'Fast & Courteous',
                'Unbelievably Swift & Polite!'],
            isDark,
          ),
          const SizedBox(height: 20),
          _buildQuickTags(isDark),
          const SizedBox(height: 20),
          _buildCommentBox(isDark),
        ],
      ),
    );
  }

  Widget _buildRatingSection(
    String title,
    String name,
    int rating,
    Function(int) onRate,
    List<String> descriptors,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.2)
            : Colors.grey.shade50.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        ),
      ),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade400,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => onRate(star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.star_rounded,
                    size: 32,
                    color: star <= rating
                        ? Colors.amber.shade400
                        : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                  ),
                ),
              );
            }),
          ),
          if (rating > 0) ...[
            const SizedBox(height: 6),
            Text(
              descriptors[rating - 1],
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.amber.shade600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickTags(bool isDark) {
    final tags = [
      'Tasty Food', 'Fresh & Hot', 'Generous Portion', 'Friendly Rider',
      'Perfect Pack', 'Super Fast', 'Polite Interaction', 'Great Price',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Feedback Tags',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            final selected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedTags.remove(tag);
                  } else {
                    _selectedTags.add(tag);
                  }
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF10b981)
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade50),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF10b981)
                        : (isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade200),
                  ),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? Colors.white
                        : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommentBox(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Comments',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: 3,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Write an optional comment...',
            hintStyle: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF10b981)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSuccess() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.thumb_up_rounded,
                size: 36, color: Colors.green.shade500),
          ),
          const SizedBox(height: 20),
          Text(
            'Feedback Logged!',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'THANK YOU SO MUCH!',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade400,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your rating was saved successfully!',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
          ),
        ),
      ),
      child: _isFeedbackSubmitted
          ? SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _showFeedbackModal = false);
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Return to Home',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          : Row(
              children: [
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () =>
                        setState(() => _showFeedbackModal = false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade200,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Maybe Later',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: (_restaurantRating == 0 && _deliveryRating == 0)
                        ? null
                        : () {
                            _saveFeedback();
                            setState(() => _isFeedbackSubmitted = true);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Submit Feedback',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInAppNotification() {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () => setState(() => _inAppNotification = null),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF18233c).withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 24,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF10b981).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_active_rounded,
                    color: const Color(0xFF10b981), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SWIFTDROP ALERT',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF10b981),
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'Just now',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _inAppNotification?['title'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _inAppNotification?['body'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey.shade300,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

