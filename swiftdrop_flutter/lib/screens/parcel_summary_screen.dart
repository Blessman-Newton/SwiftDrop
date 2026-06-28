import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../utils/validators.dart';

class ParcelSummaryScreen extends StatefulWidget {
  const ParcelSummaryScreen({super.key});

  @override
  State<ParcelSummaryScreen> createState() => _ParcelSummaryScreenState();
}

class _ParcelSummaryScreenState extends State<ParcelSummaryScreen> {
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
                                '123 Urban Business Center',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF161D19),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Central District, Tech Park',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF3C4A42),
                                ),
                              ),
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
                                '456 Residential Avenue',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF161D19),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Oakwood Hills, Block B',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF3C4A42),
                                ),
                              ),
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
                                      'SwiftDrop Express',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF3C4A42),
                                      ),
                                    ),
                                    Text(
                                      '15-25 min',
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
                                      'Small Box (<2kg)',
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
                            _formKey.currentState!.validate();
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
                        _buildPriceRow('Delivery Fee', '\$8.50'),
                        const SizedBox(height: 8),
                        _buildPriceRow('Service Fee', '\$1.50'),
                        const SizedBox(height: 8),
                        _buildPriceRow('Flash Discount', '-\$2.00', isDiscount: true),
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
                              '\$8.00',
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
                            '14:45 - 14:55',
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
                            '\$8.00',
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
                                setState(() {
                                  _isProcessing = false;
                                  _orderSuccess = true;
                                });
                                await Future.delayed(const Duration(seconds: 1));
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Order confirmed! A courier is being assigned.',
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
