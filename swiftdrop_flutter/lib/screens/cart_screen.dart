import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_image.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtotal = cartNotifier.subtotal;
    final restaurantId = cartNotifier.restaurantId;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: Column(
        children: [
          _buildHeader(context, isDark, cart.isNotEmpty, cartNotifier),
          Expanded(
            child: cart.isEmpty
                ? _buildEmptyState(context, isDark)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    itemCount: cart.length,
                    itemBuilder: (context, i) {
                      final item = cart[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface(isDark),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border(isDark)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: AppImage(
                                    url: item.foodItem.imageUrl,
                                    fit: BoxFit.cover,
                                    fallbackSeed: item.foodItem.name),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.foodItem.name,
                                      style: AppText.title(isDark),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  if (item.extras.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.extras.map((e) => '${e.quantity}x ${e.name}').join(', '),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    'GHS ${(item.totalPrice / item.quantity).toStringAsFixed(2)} each',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _qtyStepper(item, cartNotifier, ref, isDark),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (cart.isNotEmpty)
            _buildCheckoutBar(context, isDark, subtotal, restaurantId),
        ],
      ),
    );
  }

  Widget _qtyStepper(CartItem item, CartNotifier notifier, WidgetRef ref,
      bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
            onPressed: () => notifier.decreaseQuantity(item),
            icon: const Icon(Icons.remove, size: 16, color: AppColors.primary),
          ),
          Text('${item.quantity}',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w800)),
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
            onPressed: () => notifier.increaseQuantity(item),
            icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool hasItems,
      CartNotifier notifier) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your Cart', style: AppText.heading(isDark)),
            if (hasItems)
              TextButton(
                onPressed: () => notifier.clearCart(),
                child: Text('Clear',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined,
              size: 64, color: AppColors.textSecondary(isDark).withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: AppText.title(isDark)),
          const SizedBox(height: 6),
          Text('Add items to get started',
              style: AppText.secondary(isDark)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar(BuildContext context, bool isDark, double subtotal,
      String? restaurantId) {
    final isCosmetics = restaurantId == 'cosmetics_store';
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        border: Border(top: BorderSide(color: AppColors.border(isDark))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: AppText.secondary(isDark)),
              Text('GHS ${subtotal.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary(isDark))),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Delivery & taxes calculated at checkout',
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textSecondary(isDark))),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Consumer(
              builder: (context, ref, _) {
                return FilledButton(
                  onPressed: restaurantId == null
                      ? null
                      : () {
                          if (isCosmetics) {
                            _navigateToCosmeticsCheckout(context, ref);
                          } else {
                            context.push('/restaurant/$restaurantId?checkout=true');
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Proceed to checkout',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCosmeticsCheckout(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please log in to proceed',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final cart = ref.read(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final subtotal = cartNotifier.subtotal;
    final deliveryFee = 5.0; // flat cosmetics delivery fee
    final tax = subtotal * 0.05; // 5% service fee
    final total = subtotal + deliveryFee + tax;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          restaurantId: 'cosmetics_store',
          restaurantName: 'Doorush Cosmetics',
          cartItems: cart,
          subtotal: subtotal,
          deliveryFee: deliveryFee,
          tax: tax,
          discount: 0,
          total: total,
          deliveryAddress: 'Select delivery address',
          orderType: 'cosmetics',
          userEmail: user.email,
        ),
      ),
    );
  }
}
