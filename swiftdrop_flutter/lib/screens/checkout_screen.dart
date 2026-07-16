import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/order_service.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'address_selection_screen.dart';
import 'momo_payment_screen.dart';

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
  late String _deliveryAddress;
  MoMoPaymentResult? _momoPayment;

  // 'doorstep' = deliver to address, 'pickup' = collect from restaurant.
  String _deliveryMethod = 'doorstep';

  bool get _isPickup => _deliveryMethod == 'pickup';
  bool get _isFood => widget.orderType == 'food';

  double get _effectiveDeliveryFee =>
      (_isFood && _isPickup) ? 0.0 : widget.deliveryFee;
  double get _effectiveTotal =>
      widget.total - widget.deliveryFee + _effectiveDeliveryFee;

  @override
  void initState() {
    super.initState();
    _deliveryAddress = widget.deliveryAddress;
  }

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
                  if (_isFood) ...[
                    _buildDeliveryMethod(surfaceColor, textColor, subtextColor),
                    const SizedBox(height: 12),
                  ],
                  if (!_isPickup || !_isFood)
                    _buildDeliveryAddress(
                        surfaceColor, textColor, subtextColor),
                  if (!_isPickup || !_isFood) const SizedBox(height: 12),
                  _buildOrderSummary(surfaceColor, textColor, subtextColor),
                  const SizedBox(height: 12),
                  _buildPaymentMethod(surfaceColor, textColor, subtextColor),
                  if (_statusMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
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

  // ─── Delivery Method Section ─────────────────────────────────────────────────
  Widget _buildDeliveryMethod(Color surface, Color text, Color subtext) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
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
          Text('Delivery Method',
              style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w700, color: text)),
          const SizedBox(height: 12),
          _deliveryOption(
            value: 'doorstep',
            icon: Icons.delivery_dining,
            title: 'Deliver to my doorstep',
            subtitle: widget.deliveryFee == 0
                ? 'Free delivery'
                : 'GHS ${widget.deliveryFee.toStringAsFixed(2)} delivery fee',
            text: text,
            subtext: subtext,
          ),
          const SizedBox(height: 8),
          _deliveryOption(
            value: 'pickup',
            icon: Icons.storefront,
            title: 'Pick up from restaurant',
            subtitle: 'No delivery fee • collect it yourself',
            text: text,
            subtext: subtext,
          ),
        ],
      ),
    );
  }

  Widget _deliveryOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color text,
    required Color subtext,
  }) {
    final selected = _deliveryMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _deliveryMethod = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : const Color.fromRGBO(128, 128, 128, 0.2),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? AppColors.primary : subtext, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: text)),
                  Text(subtitle,
                      style: GoogleFonts.inter(fontSize: 11, color: subtext)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : subtext,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Delivery Address Section ────────────────────────────────────────────────
  Widget _buildDeliveryAddress(Color surface, Color text, Color subtext) {
    return GestureDetector(
      onTap: _openAddressSelection,
      child: Container(
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
              child: const Icon(Icons.location_on, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Deliver To',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: subtext,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF6EE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Tap to change',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _deliveryAddress,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: text,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: subtext, size: 22),
          ],
        ),
      ),
    );
  }

  // ─── Order Summary ───────────────────────────────────────────────────────────
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
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: text),
          ),
          const SizedBox(height: 4),
          Text(widget.restaurantName, style: GoogleFonts.inter(fontSize: 13, color: subtext)),
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
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: text),
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
          _buildPriceRow(
              _isPickup && _isFood ? 'Delivery (Pickup)' : 'Delivery',
              _effectiveDeliveryFee,
              text),
          _buildPriceRow('Tax', widget.tax, text),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
              Text(
                'GHS ${_effectiveTotal.toStringAsFixed(2)}',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
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

  // ─── Payment Method Section ──────────────────────────────────────────────────
  Widget _buildPaymentMethod(Color surface, Color text, Color subtext) {
    return GestureDetector(
      onTap: _openMoMoSelection,
      child: Container(
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
                color: _momoPayment != null
                    ? const Color(0xFFEEF6EE)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.phone_android,
                color: _momoPayment != null ? AppColors.primary : const Color(0xFF6B7280),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: subtext),
                  ),
                  const SizedBox(height: 4),
                  if (_momoPayment != null) ...[
                    Text(
                      '${_getProviderName(_momoPayment!.provider)} •••• ${_momoPayment!.phoneNumber.substring(_momoPayment!.phoneNumber.length - 4)}',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: text),
                    ),
                    Text(
                      _momoPayment!.displayName,
                      style: GoogleFonts.inter(fontSize: 12, color: subtext),
                    ),
                  ] else ...[
                    Text(
                      'Add Mobile Money',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: text),
                    ),
                    Text(
                      'MTN MoMo, Telecel Cash, AirtelTigo',
                      style: GoogleFonts.inter(fontSize: 12, color: subtext),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _momoPayment != null ? const Color(0xFFEEF6EE) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _momoPayment != null ? 'Change' : 'Add',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _momoPayment != null ? AppColors.primary : const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Status Banner ───────────────────────────────────────────────────────────
  Widget _buildStatusBanner() {
    final isError = _statusMessage.contains('failed') || _statusMessage.contains('error');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFEF2F2) : const Color(0xFFEEF6EE),
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

  // ─── Pay Button ──────────────────────────────────────────────────────────────
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF006C49)),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _statusMessage.isNotEmpty ? _statusMessage : 'Processing...',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF006C49)),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Pay GHS ${_effectiveTotal.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Price Row ───────────────────────────────────────────────────────────────
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

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  String _getProviderName(String id) {
    switch (id) {
      case 'mtn': return 'MTN MoMo';
      case 'telecel': return 'Telecel Cash';
      case 'airteltigo': return 'AirtelTigo';
      default: return 'MoMo';
    }
  }

  // ─── Navigation ──────────────────────────────────────────────────────────────
  Future<void> _openAddressSelection() async {
    final result = await Navigator.of(context).push<AddressSelectionResult>(
      MaterialPageRoute(
        builder: (_) => AddressSelectionScreen(
          currentAddress: _deliveryAddress,
        ),
      ),
    );
    if (result != null) {
      setState(() => _deliveryAddress = result.address);
    }
  }

  Future<void> _openMoMoSelection() async {
    final result = await Navigator.of(context).push<MoMoPaymentResult>(
      MaterialPageRoute(
        builder: (_) => MoMoPaymentScreen(currentMethod: _momoPayment),
      ),
    );
    if (result != null) {
      setState(() => _momoPayment = result);
    }
  }

  // ─── Payment Processing ──────────────────────────────────────────────────────
  Future<void> _processPayment() async {
    if (!ApiClient().isAuthenticated) {
      setState(() => _statusMessage = 'Please log in to place an order');
      return;
    }

    if (_momoPayment == null) {
      setState(() => _statusMessage = 'Please add a Mobile Money payment method');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Creating order...';
    });

    // Step 1: Create order
    final orderItems = widget.cartItems
        .map((ci) {
          final extrasText = ci.extras.isEmpty
              ? ''
              : ' (${ci.extras.map((e) => '${e.quantity}x ${e.name}').join(', ')})';
          final finalPrice = ci.foodItem.price +
              ci.extras.fold(0.0, (sum, ext) => sum + ext.price * ext.quantity);
          return {
            'name': '${ci.foodItem.name}$extrasText',
            'quantity': ci.quantity,
            'price': finalPrice,
          };
        })
        .toList();

    final orderResult = await OrderService().createOrder(
      orderType: widget.orderType,
      restaurantName: widget.restaurantName,
      pickupAddress: widget.orderType == 'food' ? widget.restaurantName : (widget.parcelPickup ?? ''),
      deliveryAddress: _isPickup && _isFood
          ? 'Pickup at ${widget.restaurantName}'
          : _deliveryAddress,
      subtotal: widget.subtotal,
      deliveryFee: _effectiveDeliveryFee,
      tax: widget.tax,
      discount: widget.discount,
      total: _effectiveTotal,
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
      amount: _effectiveTotal,
    );

    if (paymentResult == null || paymentResult['access_code'] == null) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Failed to initialize payment. Please try again.';
      });
      return;
    }

    // Step 3: Launch Paystack checkout (MoMo is accessed through Paystack's mobile money channel)
    // Step 3: Launch Paystack hosted secure page
    setState(() => _statusMessage = 'Opening secure payment gateway...');

    final authUrl = paymentResult['authorization_url'] as String;
    final reference = paymentResult['reference'] as String;

    try {
      final uri = Uri.parse(authUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        _showPaymentVerificationDialog(reference);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Failed to open payment gateway: $e';
      });
    }
  }

  void _showPaymentVerificationDialog(String reference) {
    bool isVerifying = false;
    Timer? verificationTimer;
    int checkCount = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (verificationTimer == null) {
              verificationTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
                checkCount++;
                if (checkCount > 15) {
                  timer.cancel();
                  if (mounted) {
                    setDialogState(() => isVerifying = false);
                  }
                  return;
                }
                
                try {
                  final verifyResult = await OrderService().verifyPayment(reference);
                  if (verifyResult != null && verifyResult['status'] == 'success') {
                    timer.cancel();
                    Navigator.of(dialogContext).pop();
                    _showOrderPlaced();
                  }
                } catch (_) {}
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Complete Payment',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 20),
                  Text(
                    'We launched the Paystack secure checkout page. Please complete payment there, then return to the app.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Waiting for payment confirmation...',
                    style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    verificationTimer?.cancel();
                    Navigator.of(dialogContext).pop();
                    setState(() {
                      _isProcessing = false;
                      _statusMessage = 'Payment pending check. You can verify it in your orders list.';
                    });
                  },
                  child: Text('Cancel', style: GoogleFonts.inter(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: isVerifying ? null : () async {
                    setDialogState(() => isVerifying = true);
                    try {
                      final verifyResult = await OrderService().verifyPayment(reference);
                      if (verifyResult != null && verifyResult['status'] == 'success') {
                        verificationTimer?.cancel();
                        Navigator.of(dialogContext).pop();
                        _showOrderPlaced();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Payment not completed yet or pending. Try again soon.', style: GoogleFonts.inter()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (_) {}
                    setDialogState(() => isVerifying = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isVerifying 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Verify Now', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      verificationTimer?.cancel();
    });
  }

  void _showOrderPlaced() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFEEF6EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 44),
              ),
              const SizedBox(height: 16),
              Text('Order placed!',
                  style: GoogleFonts.inter(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                _isPickup && _isFood
                    ? 'Your order from ${widget.restaurantName} is confirmed. We\'ll let you know when it\'s ready for pickup.'
                    : 'Your order from ${widget.restaurantName} is confirmed and on its way. You can track it live.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF6C7A71)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/map');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Track my order',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/home');
                },
                child: Text('Continue shopping',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6C7A71))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
