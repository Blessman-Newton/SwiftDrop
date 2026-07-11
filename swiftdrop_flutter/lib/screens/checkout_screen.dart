import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';
import '../models/models.dart';
import '../services/order_service.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final List<CartItem> cartItems;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double discount;
  final double total;
  final String deliveryAddress;
  final String? promoCode;
  final String orderType;
  final String? parcelPickup;
  final String? parcelDelivery;
  final String userEmail;

  const CheckoutScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.cartItems,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.discount,
    required this.total,
    required this.deliveryAddress,
    this.promoCode,
    this.orderType = 'food',
    this.parcelPickup,
    this.parcelDelivery,
    required this.userEmail,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF4FBF4);
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtextColor = isDark ? Colors.grey[400]! : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Checkout',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderSummary(surfaceColor, textColor, subtextColor),
                  const SizedBox(height: 16),
                  _buildPaymentInfo(surfaceColor, textColor, subtextColor),
                  if (_statusMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildStatusBanner(),
                  ],
                ],
              ),
            ),
          ),
          _buildPayButton(),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(Color surface, Color text, Color subtext) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.restaurantName,
            style: GoogleFonts.inter(fontSize: 13, color: subtext),
          ),
          const SizedBox(height: 12),
          if (widget.orderType == 'food') ...[
            ...widget.cartItems.map((ci) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${ci.quantity}x ${ci.foodItem.name}',
                          style: GoogleFonts.inter(fontSize: 14, color: text),
                        ),
                      ),
                      Text(
                        'GHS ${(ci.foodItem.price * ci.quantity).toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: text,
                        ),
                      ),
                    ],
                  ),
                )),
          ] else ...[
            if (widget.parcelPickup != null)
              _buildAddressRow('Pickup', widget.parcelPickup!, text, subtext),
            if (widget.parcelDelivery != null) ...[
              const SizedBox(height: 8),
              _buildAddressRow('Drop-off', widget.parcelDelivery!, text, subtext),
            ],
          ],
          const Divider(height: 24),
          _buildPriceRow('Subtotal', widget.subtotal, text),
          if (widget.discount > 0)
            _buildPriceRow('Discount', -widget.discount, AppColors.primary, isDiscount: true),
          _buildPriceRow('Delivery', widget.deliveryFee, text),
          _buildPriceRow('Tax', widget.tax, text),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
              Text(
                'GHS ${widget.total.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(String label, String address, Color text, Color subtext) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          label == 'Pickup' ? Icons.trip_origin : Icons.location_on,
          color: label == 'Pickup' ? AppColors.primary : AppColors.accent,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: subtext)),
              Text(address, style: GoogleFonts.inter(fontSize: 13, color: text)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(Color surface, Color text, Color subtext) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF6EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Payment',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: text,
                  ),
                ),
                Text(
                  'Pay via card, mobile money, or bank transfer',
                  style: GoogleFonts.inter(fontSize: 12, color: subtext),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final isError = _statusMessage.contains('failed') || _statusMessage.contains('error');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFEEF6EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: isError ? Colors.red : AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isError ? Colors.red : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: _isProcessing
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF006C49), Color(0xFF10B981)],
                    ),
              color: _isProcessing ? Colors.grey[300] : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isProcessing
                  ? null
                  : [
                      BoxShadow(
                        color: const Color.fromRGBO(0, 108, 73, 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
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
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF006C49),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _statusMessage.isNotEmpty ? _statusMessage : 'Processing...',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF006C49),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Pay GHS ${widget.total.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double value, Color text, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: text)),
          Text(
            '${isDiscount ? '-' : ''}GHS ${value.abs().toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDiscount ? AppColors.primary : text,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!ApiClient().isAuthenticated) {
      setState(() => _statusMessage = 'Please log in to place an order');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Creating order...';
    });

    // Step 1: Create order first
    final orderItems = widget.cartItems
        .map((ci) => {
              'name': ci.foodItem.name,
              'quantity': ci.quantity,
              'price': ci.foodItem.price,
            })
        .toList();

    final orderResult = await OrderService().createOrder(
      orderType: widget.orderType,
      restaurantName: widget.restaurantName,
      pickupAddress: widget.orderType == 'food' ? widget.restaurantName : (widget.parcelPickup ?? ''),
      deliveryAddress: widget.deliveryAddress,
      subtotal: widget.subtotal,
      deliveryFee: widget.deliveryFee,
      tax: widget.tax,
      discount: widget.discount,
      total: widget.total,
      promoCode: widget.promoCode,
      items: widget.orderType == 'food' ? orderItems : null,
    );

    if (orderResult == null || orderResult['id'] == null) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Failed to create order. Please try again.';
      });
      return;
    }

    final orderId = orderResult['id'] as String;

    // Step 2: Initialize payment
    setState(() => _statusMessage = 'Initializing payment...');

    final paymentResult = await OrderService().initializePayment(
      orderId: orderId,
      email: widget.userEmail,
      amount: widget.total,
    );

    if (paymentResult == null || paymentResult['access_code'] == null) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Failed to initialize payment. Please try again.';
      });
      return;
    }

    // Step 3: Launch Paystack checkout
    setState(() => _statusMessage = 'Opening payment...');

    try {
      final reference = PayWithPayStack().generateUuidV4();

      await PayWithPayStack().now(
        context: context,
        secretKey: 'sk_test_18e607bd21de019b1407a895b4a8b0c6c0bc6c36',
        customerEmail: widget.userEmail,
        reference: reference,
        currency: 'GHS',
        amount: widget.total,
        callbackUrl: 'https://swiftdrop-fvcd.onrender.com/api/v1/payments/webhook',
        channels: [
          PaystackChannel.card,
          PaystackChannel.mobileMoney,
          PaystackChannel.bankTransfer,
        ],
        customFields: [
          PaystackCustomField(
            displayName: 'Order ID',
            variableName: 'order_id',
            value: orderId,
          ),
        ],
        transactionCompleted: (PaymentData data) async {
          if (data.reference != null) {
            await _handlePaymentSuccess(data.reference!);
          }
        },
        transactionNotCompleted: (String reason) {
          setState(() {
            _isProcessing = false;
            _statusMessage = 'Payment failed: $reason';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Payment error: $e';
      });
    }
  }

  Future<void> _handlePaymentSuccess(String reference) async {
    setState(() => _statusMessage = 'Verifying payment...');

    // Step 4: Verify payment
    final verifyResult = await OrderService().verifyPayment(reference);

    if (verifyResult != null && verifyResult['status'] == 'success') {
      // Payment verified - now confirm order
      setState(() => _statusMessage = 'Payment confirmed!');

      // Save order locally
      // (The order was already created on the backend)

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Navigate to orders screen
        context.go('/orders');
      }
    } else {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Payment verification pending. Your order has been placed.';
      });

      // Even if verification is pending, order was created
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        context.go('/orders');
      }
    }
  }
}
