import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_image.dart';

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
                                  const SizedBox(height: 2),
                                  Text(
                                    'GHS ${item.foodItem.price.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _qtyStepper(item.foodItem.id, item.quantity,
                                cartNotifier, ref, isDark, item.foodItem),
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

  Widget _qtyStepper(String id, int qty, CartNotifier notifier, WidgetRef ref,
      bool isDark, dynamic foodItem) {
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
            onPressed: () => notifier.removeItem(id),
            icon: const Icon(Icons.remove, size: 16, color: AppColors.primary),
          ),
          Text('$qty',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w800)),
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
            onPressed: () => notifier.addItem(foodItem, restaurantId: notifier.restaurantId),
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
          Text('Add items from a restaurant to get started',
              style: AppText.secondary(isDark)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/food-delivery'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Browse restaurants'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar(BuildContext context, bool isDark, double subtotal,
      String? restaurantId) {
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
            child: FilledButton(
              onPressed: restaurantId == null
                  ? null
                  : () => context.push('/restaurant/$restaurantId'),
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
            ),
          ),
        ],
      ),
    );
  }
}
