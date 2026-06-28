import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          _buildHeader(context, isDark),
          Expanded(
            child: orders.isEmpty ? _buildEmptyState(isDark) : _buildOrderList(orders, ref, context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 20, 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkBackground.withOpacity(0.8)
              : Colors.white.withOpacity(0.8),
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.grey.shade100,
            ),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/home'),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Order History',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your order history will appear here',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders, WidgetRef ref, BuildContext context, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order, ref, context, isDark);
      },
    );
  }

  Widget _buildOrderCard(
      Order order, WidgetRef ref, BuildContext context, bool isDark) {
    final statusColor = _getStatusColor(order.status);
    final statusLabel = _getStatusLabel(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18233c) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            order.restaurantName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.items
                          .map((i) => '${i.quantity}x ${i.foodItem.name}')
                          .join(', '),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(order.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${order.totalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.shade100,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ref.read(ordersProvider.notifier).reorder(
                          order.items,
                          order.restaurantId,
                          order.restaurantName,
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Reordered from ${order.restaurantName}',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Reorder',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.amber.shade600;
      case OrderStatus.accepted:
        return AppColors.primary;
      case OrderStatus.outForDelivery:
        return AppColors.primary;
      case OrderStatus.completed:
        return Colors.grey.shade500;
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Preparing';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.completed:
        return 'Delivered';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}
