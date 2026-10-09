import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/rider_providers.dart';
import '../../providers/merchant_providers.dart';
import '../../services/tomtom_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class RiderNavigationScreen extends ConsumerStatefulWidget {
  const RiderNavigationScreen({super.key});

  @override
  ConsumerState<RiderNavigationScreen> createState() =>
      _RiderNavigationScreenState();
}

class _RiderNavigationScreenState extends ConsumerState<RiderNavigationScreen>
    with SingleTickerProviderStateMixin {
  late Timer _gpsTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isDarkMap = false;
  LatLng _riderPosition = TomTomService.defaultCenter;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _initGPS();
  }

  void _initGPS() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _riderPosition = LatLng(pos.latitude, pos.longitude);
      });

      _gpsTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        try {
          final currentPos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          );
          if (mounted) {
            setState(() {
              _riderPosition = LatLng(currentPos.latitude, currentPos.longitude);
            });
            // Update location on backend
            final service = ref.read(riderServiceProvider);
            service.updateLocation(currentPos.latitude, currentPos.longitude);
          }
        } catch (_) {}
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _gpsTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleExit() {
    ref
        .read(riderToastsProvider.notifier)
        .add('Navigation terminated', ToastType.info);
    context.go('/rider/active-delivery');
  }

  @override
  Widget build(BuildContext context) {
    final activeOrder = ref.watch(riderActiveDeliveryProvider).valueOrNull;

    // Parse targets
    final pickupLat = activeOrder?['pickup_lat'] as double?;
    final pickupLng = activeOrder?['pickup_lng'] as double?;
    final deliveryLat = activeOrder?['delivery_lat'] as double?;
    final deliveryLng = activeOrder?['delivery_lng'] as double?;

    final status = activeOrder?['status'] as String?;
    final isCollected = status == 'collected' || status == 'picked_up' || status == 'en_route';

    final targetLat = isCollected ? deliveryLat : pickupLat;
    final targetLng = isCollected ? deliveryLng : pickupLng;

    final target = (targetLat != null && targetLng != null)
        ? LatLng(targetLat, targetLng)
        : TomTomService.defaultCenter;

    final destAddress = isCollected
        ? (activeOrder?['delivery_address'] ?? 'Customer Address')
        : (activeOrder?['pickup_address'] ?? activeOrder?['restaurant_name'] ?? 'Pickup Depot');

    final instruction = isCollected ? "Deliver to customer location" : "Collect items from merchant";
    final instructionIcon = isCollected ? Icons.home_rounded : Icons.storefront_rounded;

    // Distance calculation
    final distanceInMeters = Geolocator.distanceBetween(
      _riderPosition.latitude,
      _riderPosition.longitude,
      target.latitude,
      target.longitude,
    );

    final distanceInKm = distanceInMeters / 1000.0;
    // Assuming standard speed of ~40km/h (666m per min)
    final durationInMinutes = (distanceInMeters / 600.0).ceil();
    final arrivalTime = DateTime.now().add(Duration(minutes: durationInMinutes));
    final arrivalStr = "${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}";

    // Midpoint to center map dynamically
    final centerLat = (_riderPosition.latitude + target.latitude) / 2.0;
    final centerLng = (_riderPosition.longitude + target.longitude) / 2.0;
    final centerLatLng = LatLng(centerLat, centerLng);

    double zoom = 15.0;
    if (distanceInKm > 8.0) {
      zoom = 11.5;
    } else if (distanceInKm > 4.0) {
      zoom = 13.0;
    } else if (distanceInKm > 1.5) {
      zoom = 14.0;
    } else if (distanceInKm > 0.5) {
      zoom = 15.0;
    } else {
      zoom = 16.0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF4),
      body: Stack(
        children: [
          // Map Background
          Positioned.fill(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: centerLatLng,
                initialZoom: zoom,
                maxZoom: 19,
                minZoom: 1,
              ),
              children: [
                TileLayer(
                  urlTemplate: TomTomService.tileUrl,
                  userAgentPackageName: 'com.swiftdrop.app',
                ),
                // Routing polyline
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_riderPosition, target],
                      color: const Color(0xFF006C49),
                      strokeWidth: 5,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                // Markers layer
                MarkerLayer(
                  markers: [
                    // Rider Marker with pulse
                    Marker(
                      point: _riderPosition,
                      width: 64,
                      height: 64,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 44 * _pulseAnimation.value,
                                height: 44 * _pulseAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF10B981).withAlpha(
                                    (40 - (_pulseAnimation.value - 1.0) * 40).round(),
                                  ),
                                ),
                              ),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF006C49),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                                  ],
                                ),
                                child: const Icon(Icons.local_shipping, color: Colors.white, size: 16),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    // Destination Marker
                    Marker(
                      point: target,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Icon(instructionIcon, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Header Instruction Panel
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF006C49),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        instructionIcon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            instruction,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            destAddress,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFA7F3D0),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Zoom Controls
          Positioned(
            right: 20,
            bottom: 230,
            child: Column(
              children: [
                _MapControlButton(
                  icon: Icons.add,
                  onTap: () {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                _MapControlButton(
                  icon: Icons.remove,
                  onTap: () {
                    setState(() {});
                  },
                ),
              ],
            ),
          ),

          // Navigation Bottom Info Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$durationInMinutes',
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF006C49),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'MIN',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF94A3B8),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Arrival: $arrivalStr',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                distanceInKm.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'KM',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF94A3B8),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: 160,
                            child: Text(
                              destAddress,
                              textAlign: TextAlign.end,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF006C49)),
                          label: Text(
                            'Call Customer',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.grey[100],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            final phone = activeOrder?['customer_phone'] as String?;
                            if (phone != null && phone.isNotEmpty) {
                              ref.read(riderToastsProvider.notifier).add('Dialing customer: $phone', ToastType.info);
                            } else {
                              ref.read(riderToastsProvider.notifier).add('Customer phone not available', ToastType.error);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                          label: Text(
                            'Exit Route',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: const Color(0xFFE11D48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _handleExit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool isFilled;

  const _MapControlButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isFilled ? const Color(0xFF006C49) : Colors.white,
          shape: BoxShape.circle,
          border: isFilled ? null : Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: isFilled
                  ? const Color(0x33000000)
                  : const Color(0x26000000),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isFilled
              ? Colors.white
              : iconColor ?? const Color(0xFF475569),
        ),
      ),
    );
  }
}

