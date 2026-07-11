import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../utils/validators.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../services/order_service.dart';
import '../services/api_client.dart';


class ParcelSummaryScreen extends ConsumerStatefulWidget {
  const ParcelSummaryScreen({super.key});

  @override
  ConsumerState<ParcelSummaryScreen> createState() => _ParcelSummaryScreenState();
}

class _ParcelSummaryScreenState extends ConsumerState<ParcelSummaryScreen> {
  final _promoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  bool _orderSuccess = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
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
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
              child: Form(
                key: _formKey,
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
                        'Review Order',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF006C49),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.help, color: Color(0xFF006C49)),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Route Information
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.04),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Route icons
                        Column(
                          children: [
                            Icon(Icons.trip_origin, color: const Color(0xFF006C49), size: 20),
                            Container(
                              width: 1.5,
                              height: 48,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: const Color(0xFFBBCABF),
                            ),
                            Icon(Icons.location_on, color: const Color(0xFF9D4300), size: 20),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Addresses
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pickup',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF3C4A42),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                booking.pickupLocation,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF161D19),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const SizedBox(height: 16),
                              Text(
                                'Drop-off',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF3C4A42),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                booking.deliveryLocation,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF161D19),
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                          ),
                        ),
                        // Edit button
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text(
                            'Edit',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF006C49),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Service & Item Section
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.04),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.electric_moped, color: Color(0xFF00422B), size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.serviceDisplayName,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF3C4A42),
                                      ),
                                    ),
                                    Text(
                                      booking.deliveryEta,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF161D19),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.04),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDAE2FD),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.inventory_2, color: Color(0xFF5C647A), size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Package Type',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF3C4A42),
                                      ),
                                    ),
                                    Text(
                                      '${booking.packageTypeLabel} (${booking.packageSizeLabel})',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF161D19),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Payment Method
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.04),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments, color: Color(0xFF565E74), size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Method',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF161D19),
                                ),
                              ),
                              Text(
                                'Apple Pay •••• 9821',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF3C4A42),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Change',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF006C49),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Promo Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.04),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer, color: Color(0xFF9D4300), size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF6EE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextFormField(
                              controller: _promoController,
                              validator: Validators.promoCode,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                hintText: 'Add Promo Code',
                                hintStyle: GoogleFonts.inter(color: const Color(0xFF6C7A71)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: const Color(0xFF161D19),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              ref.read(parcelBookingProvider.notifier).applyPromo(_promoController.text.toUpperCase());
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF565E74),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Apply',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price Breakdown
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.04),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRICE BREAKDOWN',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3C4A42),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPriceRow('Delivery Fee', 'GHS ${booking.deliveryFee.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _buildPriceRow('Service Fee', 'GHS ${booking.serviceFee.toStringAsFixed(2)}'),
                        if (booking.insuranceIncluded) ...[
                          const SizedBox(height: 8),
                          _buildPriceRow('Insurance', 'GHS ${booking.insuranceFee.toStringAsFixed(2)}'),
                        ],
                        if (booking.discount > 0) ...[
                          const SizedBox(height: 8),
                          _buildPriceRow('Promo Discount', '-GHS ${booking.discount.toStringAsFixed(2)}', isDiscount: true),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Color(0xFFBBCABF)),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF161D19),
                              ),
                            ),
                            Text(
                              'GHS ${booking.total.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF006C49),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          ),

          // Sticky Bottom Confirmation
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.08),
                  blurRadius: 30,
                  offset: Offset(0, -10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBBCABF),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ETA + Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated Arrival',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF3C4A42),
                            ),
                          ),
                          Text(
                            booking.deliveryEta,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF161D19),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total Amount',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF3C4A42),
                            ),
                          ),
                          Text(
                            'GHS ${booking.total.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF161D19),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF006C49), Color(0xFF10B981)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 108, 73, 0.3),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isProcessing
                            ? null
                            : () async {
                                setState(() => _isProcessing = true);
                                await Future.delayed(const Duration(seconds: 2));
                                final booking = ref.read(parcelBookingProvider);
                                final orderId = 'PARCEL-${DateTime.now().millisecondsSinceEpoch}';

                                // Save order locally
                                ref.read(ordersProvider.notifier).addOrder(Order(
                                  id: orderId,
                                  restaurantId: 'swiftdrop-parcel',
                                  restaurantName: 'SwiftDrop Parcel',
                                  items: const [],
                                  totalPrice: booking.total,
                                  status: OrderStatus.pending,
                                  createdAt: DateTime.now(),
                                  trackingStep: 0,
                                  orderType: 'parcel',
                                  parcelPickupLocation: booking.pickupLocation,
                                  parcelDeliveryLocation: booking.deliveryLocation,
                                ));

                                // Also call backend API (fire and forget)
                                if (ApiClient().isAuthenticated) {
                                  OrderService().createOrder(
                                    orderType: 'parcel',
                                    restaurantName: 'SwiftDrop Parcel',
                                    pickupAddress: booking.pickupLocation,
                                    deliveryAddress: booking.deliveryLocation,
                                    subtotal: booking.deliveryFee + booking.serviceFee,
                                    deliveryFee: booking.deliveryFee,
                                    tax: 0,
                                    discount: booking.discount,
                                    total: booking.total,
                                    promoCode: booking.promoCode,
                                  );
                                }

                                setState(() {
                                  _isProcessing = false;
                                  _orderSuccess = true;
                                });
                                await Future.delayed(const Duration(seconds: 1));
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Parcel order confirmed! Tracking: $orderId',
                                        style: GoogleFonts.inter(),
                                      ),
                                      backgroundColor: const Color(0xFF006C49),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isProcessing
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Processing...',
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : _orderSuccess
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white, size: 28),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Success!',
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Confirm Order',
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                       const Icon(Icons.chevron_right, size: 28),
                                     ],
                                   ),
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

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: isDiscount ? const Color(0xFF006C49) : const Color(0xFF3C4A42),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: isDiscount ? const Color(0xFF006C49) : const Color(0xFF161D19),
          ),
        ),
      ],
    );
  }
}
