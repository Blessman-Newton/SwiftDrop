import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen> {
  bool _showActive = true;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final activeOrders = orders.where((o) => o.status != OrderStatus.completed).toList();
    final pastOrders = orders.where((o) => o.status == OrderStatus.completed).toList();
    final displayOrders = _showActive ? activeOrders : pastOrders;
    final filteredOrders = _searchController.text.isEmpty
        ? displayOrders
        : displayOrders.where((o) =>
            o.restaurantName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            o.id.toLowerCase().contains(_searchController.text.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF4),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFF4FBF4),
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF006C49)),
                  onPressed: () => context.go('/home'),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 12),
                Text(
                  'Booking History',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF006C49),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0E9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Icon(Icons.search, color: Color(0xFF6C7A71)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Find specific orders or restaurants',
                              hintStyle: GoogleFonts.inter(color: const Color(0xFF6C7A71)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF161D19)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF6EE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _showActive = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _showActive ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _showActive ? const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 5, offset: Offset(0, 2))] : [],
                              ),
                              child: Center(
                                child: Text('Active (${activeOrders.length})',
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _showActive ? const Color(0xFF006C49) : const Color(0xFF3C4A42))),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _showActive = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_showActive ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !_showActive ? const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 5, offset: Offset(0, 2))] : [],
                              ),
                              child: Center(
                                child: Text('Past (${pastOrders.length})',
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: !_showActive ? const Color(0xFF006C49) : const Color(0xFF3C4A42))),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filteredOrders.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(_showActive ? Icons.receipt_long : Icons.history, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(_showActive ? 'No active orders' : 'No past orders',
                              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredOrders.map((order) => _buildOrderCard(order)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final isActive = order.status != OrderStatus.completed;
    final isParcel = order.orderType == 'parcel';
    final statusColor = _getStatusColor(order.status);
    final statusLabel = _getStatusLabel(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F0E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: isParcel ? const Color(0xFFFFDBCA) : const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(isParcel ? Icons.inventory_2 : Icons.restaurant,
                    color: isParcel ? const Color(0xFF9D4300) : const Color(0xFF006C49), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(order.restaurantName,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF161D19))),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isParcel ? const Color(0xFFFFDBCA) : const Color(0xFFDAE2FD),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(isParcel ? 'Parcel' : 'Food',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold,
                                color: isParcel ? const Color(0xFF341100) : const Color(0xFF5C647A))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${order.id} • ${_formatDate(order.createdAt)}',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF3C4A42))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(9999)),
                child: Text(statusLabel,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE8F0E9)), bottom: BorderSide(color: Color(0xFFE8F0E9))),
            ),
            child: isParcel
                ? Column(
                    children: [
                      Row(children: [
                        const Icon(Icons.trip_origin, color: Color(0xFF6C7A71), size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Pick up: ${order.parcelPickupLocation ?? 'N/A'}',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF3C4A42)))),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.location_on, color: Color(0xFF006C49), size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Drop off: ${order.parcelDeliveryLocation ?? 'N/A'}',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF161D19)))),
                      ]),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${order.items.length} items • Total GHS ${order.totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF3C4A42))),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          if (isActive)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/map'),
                icon: const Icon(Icons.location_on, size: 20),
                label: Text('Track Live Order', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: const Color(0xFF00422B),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('GHS ${order.totalPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF161D19))),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006C49),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Reorder', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.amber.shade600;
      case OrderStatus.accepted: return const Color(0xFF006C49);
      case OrderStatus.outForDelivery: return const Color(0xFF10B981);
      case OrderStatus.completed: return Colors.grey;
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return 'Pending';
      case OrderStatus.accepted: return 'Accepted';
      case OrderStatus.outForDelivery: return 'In Transit';
      case OrderStatus.completed: return 'Delivered';
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
