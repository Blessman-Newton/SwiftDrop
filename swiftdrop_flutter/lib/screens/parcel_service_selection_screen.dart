import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';

class ParcelServiceSelectionScreen extends ConsumerStatefulWidget {
  const ParcelServiceSelectionScreen({super.key});

  @override
  ConsumerState<ParcelServiceSelectionScreen> createState() =>
      _ParcelServiceSelectionScreenState();
}

class _ParcelServiceSelectionScreenState extends ConsumerState<ParcelServiceSelectionScreen> {
  late String _selectedService;
  late bool _insuranceIncluded;

  @override
  void initState() {
    super.initState();
    final booking = ref.read(parcelBookingProvider);
    _selectedService = booking.deliveryService;
    _insuranceIncluded = booking.insuranceIncluded;
  }

  double get _totalPrice {
    double base = _selectedService == 'swift'
        ? 12.50
        : _selectedService == 'standard'
            ? 7.00
            : 4.50;
    if (_insuranceIncluded) base += 1.00;
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(parcelBookingProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF4),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF161D19)),
                        onPressed: () => context.pop(),
                        padding: EdgeInsets.zero,
                      ),
                      Text(
                        'Delivery service',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF161D19),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Route Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Pickup
                        _buildRouteRow(
                          icon: Icons.location_on,
                          label: 'PICKUP',
                          value: booking.pickupLocation,
                          iconColor: const Color(0xFF10B981),
                          isLast: false,
                        ),
                        const SizedBox(height: 12),
                        // Delivery
                        _buildRouteRow(
                          icon: Icons.location_on,
                          label: 'DELIVERY',
                          value: booking.deliveryLocation,
                          iconColor: const Color(0xFF9D4300),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Available delivery options title
                  Text(
                    'Available delivery options',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF161D19),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Service Options
                  _buildServiceOption(
                    id: 'economy',
                    title: 'Economy',
                    subtitle: 'Cheapest option for non-urgent deliveries',
                    price: 'GHS 4.50',
                    time: '4-6 hrs',
                    badge: null,
                  ),
                  const SizedBox(height: 16),
                  _buildServiceOption(
                    id: 'standard',
                    title: 'Standard',
                    subtitle: 'Same-day delivery within a few hours',
                    price: 'GHS 7.00',
                    time: '2 hrs',
                    badge: null,
                  ),
                  const SizedBox(height: 16),
                  _buildServiceOption(
                    id: 'swift',
                    title: 'Swift',
                    subtitle: 'Express and instant within the hour',
                    price: 'GHS 12.50',
                    time: '30-45 min',
                    badge: 'Popular',
                  ),
                  const SizedBox(height: 20),

                  // Package Info
                  Text(
                    'PACKAGE INFO',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3C4A42),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Size', booking.packageSizeLabel),
                  const SizedBox(height: 8),
                  _buildInfoRow('Weight', '${booking.weight.round()} kg'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Type', booking.packageTypeLabel),
                  const SizedBox(height: 20),

                  // Insurance
                  _buildInsuranceOption(),
                ],
              ),
            ),
          ),

          // Bottom CTA
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFFF4FBF4),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 30,
                  offset: Offset(0, -10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Semantics(
                label: 'Confirm delivery for GHS ${_totalPrice.toStringAsFixed(2)}',
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                  onPressed: () {
                    ref.read(parcelBookingProvider.notifier).updateService(
                          _selectedService,
                          insurance: _insuranceIncluded,
                        );
                    context.push('/parcel/summary');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006C49),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF006C49).withValues(alpha: 0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Confirm & Pay  GHS ${_totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                     ],
                   ),
                 ),
               ),
             ),
             ),
             ),

         ],
       ),
     );
   }

  Widget _buildRouteRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icon, size: 22, color: iconColor),
            if (!isLast)
              Container(
                width: 1.5,
                height: 24,
                color: const Color(0xFF006C49),
              ),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3C4A42),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF161D19),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceOption({
    required String id,
    required String title,
    required String subtitle,
    required String price,
    required String time,
    required String? badge,
  }) {
    final isActive = _selectedService == id;
    return Semantics(
      label: '$title service, $price, $time${isActive ? ', selected' : ''}',
      child: GestureDetector(
        onTap: () => setState(() => _selectedService = id),
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8F5E8) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFF10B981) : const Color(0xFFE3EAE3),
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  const BoxShadow(
                    color: Color.fromRGBO(16, 185, 129, 0.15),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.03),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF161D19),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006C49),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6C7A71),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF161D19),
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6C7A71),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 20,
                color: isActive ? const Color(0xFF006C49) : const Color(0xFFBBCABF),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF6C7A71),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF161D19),
          ),
        ),
      ],
    );
  }

  Widget _buildInsuranceOption() {
    return Semantics(
      label: 'Include delivery insurance, adds one dollar${_insuranceIncluded ? ', selected' : ''}',
      child: GestureDetector(
        onTap: () {
          setState(() => _insuranceIncluded = !_insuranceIncluded);
          ref.read(parcelBookingProvider.notifier).toggleInsurance();
        },
        child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Include delivery insurance',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF161D19),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Protect your package against potential loss or damage during transit.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6C7A71),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Adds GHS 1.00',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF006C49),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
        onTap: () {
          setState(() => _insuranceIncluded = !_insuranceIncluded);
          ref.read(parcelBookingProvider.notifier).toggleInsurance();
        },
            child: AnimatedContainer(
              width: 56,
              height: 32,
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _insuranceIncluded ? const Color(0xFF006C49) : const Color(0xFFE3EAE3),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: _insuranceIncluded ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.1),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
