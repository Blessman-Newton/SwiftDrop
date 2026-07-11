import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_image.dart';
import '../utils/validators.dart';
import '../providers/providers.dart';

class ParcelBookingScreen extends ConsumerStatefulWidget {
  const ParcelBookingScreen({super.key});

  @override
  ConsumerState<ParcelBookingScreen> createState() => _ParcelBookingScreenState();
}

class _ParcelBookingScreenState extends ConsumerState<ParcelBookingScreen> {
  late final TextEditingController _pickupController;
  late final TextEditingController _deliveryController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final booking = ref.read(parcelBookingProvider);
    _pickupController = TextEditingController(
      text: booking.pickupLocation.isNotEmpty ? booking.pickupLocation : 'Current Location (123 Urban St)',
    );
    _deliveryController = TextEditingController(
      text: booking.deliveryLocation,
    );
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _deliveryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF4),
      body: Stack(
        children: [
          // Map background
          Positioned.fill(
            child: AppImage(
              url: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDq40mtloCwbz9qXTfGNEd30GaOgO69nGKiLdeJ1ozIxCKyWuUMB8jUsU9FeMG7XaCw_qXuJM4etF19BXtb-dGs5b0BIx1hD1vA0w_It_ON22xjffgVhQih5cc4farEZCT8JnjBhpvG8Q-NMUrFzBa59f3O6OcFAY1AxAFAs3SxhA_nLdF5D0maRwYFwYKrWNkF5EosxXjD0oEkuz21el6Q_Va5yQ5rsZ8HRIamksW-dqDf7RGRgWGP_xv42cGHV9O8fdowQCh5zuU',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF4FBF4),
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xFFF4FBF4),
                  ],
                  stops: [0.0, 0.15, 0.85, 1.0],
                ),
              ),
            ),
          ),
          // Top App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFF4FBF4),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Semantics(
                      label: 'Go back',
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: const Icon(Icons.arrow_back, size: 24, color: Color(0xFF161D19)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'SwiftDrop',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF006C49),
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      label: 'Help',
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Support center coming soon')),
                          );
                        },
                        child: const Icon(Icons.help_outline, size: 24, color: Color(0xFF161D19)),
                        ),
                      ),
                    ],
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            top: MediaQuery.of(context).padding.top + 56,
            left: 20,
            right: 20,
            bottom: 20,
            child: Form(
              key: _formKey,
              child: Column(
              children: [
                // Booking Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.1),
                        blurRadius: 25,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: const Color.fromRGBO(187, 202, 191, 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress indicator
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF006C49),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF006C49).withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 150,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: const DashedLinePainter(),
                          ),
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFFFF7E2D),
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      // Input fields
                      Expanded(
                        child: Column(
                          children: [
                            _buildLocationField(
                              label: 'PICKUP LOCATION',
                              controller: _pickupController,
                              hintText: 'Current Location (123 Urban St)',
                            ),
                            Container(
                              height: 1,
                              color: const Color.fromRGBO(187, 202, 191, 0.3),
                              margin: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            _buildLocationField(
                              label: 'DELIVERY LOCATION',
                              controller: _deliveryController,
                              hintText: 'Where is it going?',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Quick Actions (Saved Addresses)
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildSavedAddress(
                        icon: Icons.home,
                        label: 'Home',
                        address: '242 Oak Avenue',
                      ),
                      const SizedBox(width: 16),
                      _buildSavedAddress(
                        icon: Icons.work,
                        label: 'Work',
                        address: 'Innovation Plaza',
                      ),
                      const SizedBox(width: 16),
                      Semantics(
                        label: 'Add new address',
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3EAE3).withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.05),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Color(0xFF161D19),
                            size: 20,
                          ),
                        ),
                      ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Bottom Action Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        ref.read(parcelBookingProvider.notifier).updatePickup(_pickupController.text);
                        ref.read(parcelBookingProvider.notifier).updateDelivery(_deliveryController.text);
                        context.push('/parcel/details');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: const Color(0xFF00422B),
                      elevation: 8,
                      shadowColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue to Package Details',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                      ),
                    ),
                    ],
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required String label,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3C4A42),
                letterSpacing: 0.5,
              ),
            ),
            Semantics(
              label: 'Choose $label on map',
              child: GestureDetector(
                onTap: () {},
                child: Row(
                children: [
                  const Icon(Icons.map, size: 16, color: Color(0xFF006C49)),
                  const SizedBox(width: 4),
                  Text(
                    'Set on map',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF006C49),
                    ),
                  ),
                ],
              ),
            ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: (value) => Validators.required(value, fieldName: label),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(color: const Color(0xFF6C7A71)),
            filled: true,
            fillColor: const Color(0xFFE8F0E9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF161D19),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedAddress({
    required IconData icon,
    required String label,
    required String address,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3EAE3).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(9999),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF006C49), size: 16),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF161D19),
                ),
              ),
              Text(
                address,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: const Color(0xFF3C4A42),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashedLinePainter extends StatelessWidget {
  const DashedLinePainter({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedLinePainter(),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBBCABF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
