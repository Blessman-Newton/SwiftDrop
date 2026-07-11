import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/merchant_providers.dart';
import '../../services/tomtom_service.dart';
import '../../models/models.dart';

class RiderNavigationScreen extends ConsumerStatefulWidget {
  const RiderNavigationScreen({super.key});

  @override
  ConsumerState<RiderNavigationScreen> createState() =>
      _RiderNavigationScreenState();
}

class _RiderNavigationScreenState extends ConsumerState<RiderNavigationScreen>
    with SingleTickerProviderStateMixin {
  late Timer _countdownTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _distance = 400;
  int _zoomLevel = 16;
  bool _isDarkMap = false;

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

    _countdownTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      setState(() {
        _distance -= 4;
        if (_distance < 15) {
          _distance = 400;
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF4),
      body: Stack(
        children: [
          _buildMapBackground(),
          _buildNavigationHeader(),
          _buildRiderPosition(),
          _buildMapControls(),
          _buildNavigationFooter(),
        ],
      ),
    );
  }

  Widget _buildMapBackground() {
    return Positioned.fill(
      child: FlutterMap(
        options: MapOptions(
          initialCenter: TomTomService.defaultCenter,
          initialZoom: 16,
          maxZoom: 19,
          minZoom: 1,
        ),
        children: [
          TileLayer(
            urlTemplate: TomTomService.tileUrl,
            userAgentPackageName: 'com.swiftdrop.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: TomTomService.defaultCenter,
                width: 36,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  child: const Icon(Icons.local_shipping, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationHeader() {
    return Positioned(
      top: 40,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF065F46),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color.fromRGBO(5, 150, 105, 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.turn_right,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Turn Right onto Main St',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'In ${_distance}m',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFA7F3D0),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.only(left: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Color.fromRGBO(255, 255, 255, 0.15),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'NEXT',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF6EE7B7),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 20,
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

  Widget _buildRiderPosition() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Center(
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Transform.rotate(
                    angle: 0.7854,
                    child: const Icon(
                      Icons.navigation_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: 20,
      bottom: 176,
      child: Column(
        children: [
          _MapControlButton(
            icon: Icons.add,
            onTap: () {
              setState(() {
                if (_zoomLevel < 20) _zoomLevel++;
              });
            },
          ),
          const SizedBox(height: 14),
          _MapControlButton(
            icon: Icons.remove,
            onTap: () {
              setState(() {
                if (_zoomLevel > 12) _zoomLevel--;
              });
            },
          ),
          const SizedBox(height: 14),
          _MapControlButton(
            icon: Icons.layers_rounded,
            iconColor: _isDarkMap ? const Color(0xFF059669) : null,
            onTap: () {
              setState(() {
                _isDarkMap = !_isDarkMap;
              });
            },
          ),
          const SizedBox(height: 14),
          _MapControlButton(
            icon: Icons.navigation_rounded,
            isFilled: true,
            onTap: () {
              setState(() {
                _zoomLevel = 16;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationFooter() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Color(0xF2FFFFFF),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 30,
              offset: Offset(0, -8),
            ),
          ],
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
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
                          '12',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'MIN',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Arrival: 14:42',
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
                          '3.4',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'KM',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
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
                        'Destination: 242 Market St',
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
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.help_outline_rounded,
                            size: 16,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Support Help',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF475569),
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
                    onTap: _handleExit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x4DE11D48),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Exit Route',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
          color: isFilled ? const Color(0xFF059669) : Colors.white,
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

