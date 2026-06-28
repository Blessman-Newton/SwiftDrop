import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_image.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  bool _showActive = true;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF4),
      body: Column(
        children: [
          // Top App Bar
          Container(
            color: const Color(0xFFF4FBF4),
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF006C49)),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 12),
                Text(
                  'SwiftDrop',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF006C49),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon:
                      const Icon(Icons.notifications, color: Color(0xFF006C49)),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
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
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0E9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.04),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
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
                            decoration: InputDecoration(
                              hintText: 'Find specific orders or restaurants',
                              hintStyle: GoogleFonts.inter(
                                  color: const Color(0xFF6C7A71)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: const Color(0xFF161D19),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tab Switcher
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF6EE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                label:
                                    'Active orders${_showActive ? ', selected' : ''}',
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _showActive = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _showActive
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: _showActive
                                          ? const [
                                              BoxShadow(
                                                color: Color.fromRGBO(
                                                    0, 0, 0, 0.05),
                                                blurRadius: 5,
                                                offset: Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Active',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _showActive
                                              ? const Color(0xFF006C49)
                                              : const Color(0xFF3C4A42),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Semantics(
                                label:
                                    'Past orders${!_showActive ? ', selected' : ''}',
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _showActive = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: !_showActive
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: !_showActive
                                          ? const [
                                              BoxShadow(
                                                color: Color.fromRGBO(
                                                    0, 0, 0, 0.05),
                                                blurRadius: 5,
                                                offset: Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Past',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: !_showActive
                                              ? const Color(0xFF006C49)
                                              : const Color(0xFF3C4A42),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Orders List
                  if (_showActive) ...[
                    _buildActiveOrderCard(
                      icon: Icons.restaurant,
                      iconBg: const Color(0xFF10B981).withValues(alpha: 0.2),
                      iconColor: const Color(0xFF006C49),
                      title: 'The Burger Loft',
                      badge: 'Food',
                      badgeBg: const Color(0xFFDAE2FD),
                      badgeText: const Color(0xFF5C647A),
                      orderId: '#SD-92834',
                      time: 'Today, 12:45 PM',
                      statusLabel: 'In Transit',
                      statusIcon: Icons.directions_bike,
                      statusBg: const Color(0xFF10B981),
                      statusText: Colors.white,
                      middleChild: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '3 items • Total \$42.50',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: const Color(0xFF3C4A42),
                            ),
                          ),
                          Row(
                            children: [
                              _buildAvatar(
                                  'https://lh3.googleusercontent.com/aida-public/AB6AXuAVlNzCvQRUt0dfXgb9QpmjzlUiQREb8q6IoFxHXnglZRLlD52L2HjSVsdh264_XXSw0lQ9RCEcF8ztjVGKgMAXDeSYMKHJhCjONBq4RonFzB0TwOf3uwpw7IPfESBzzFZ40qxndDjUF7Ud5N3AkFQDtKy5ufzqzjpKR1o8Ddmzuwo-5JxNm1HgWweGd7BEhGx_IugBBU9kc6R-jEmlOhjOf82f8ZxP5yDrfcWwK33A2usuVga2dLyzwERW0JEMrFxXVCsJydPnidk'),
                              Transform.translate(
                                offset: const Offset(-8, 0),
                                child: _buildAvatar(
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuD15Vq4mdGMYku9jcnHFLbwutUAPjBVKIARjZs5W7GE3tOHUD0nGQN07AC0lW4AXeRicK-MmbPFzFstbKPbL-gy84xUXGZCGlM8JzvXxIMvoGUOeQT2ZkRmPYpRgt4htR5f5AFb1nFDIctQj_xpu8sg_3uLmtXPDdQplrsJE5D7rPuMjZJK9gapRSVtSAIi1EVYSF4G7ffBJIDfQ0Hk5cT0bR6zDtJ6B2Ns_OJ_ihVTC3GlM3xDCHmgkyaW7j8enaLNQmNqg0qZBN8'),
                              ),
                              Transform.translate(
                                offset: const Offset(-16, 0),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDDE4DD),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '+1',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF161D19),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      bottomChild: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/map'),
                          icon: const Icon(Icons.location_on, size: 20),
                          label: Text('Track Live Order',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: const Color(0xFF00422B),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActiveOrderCard(
                      icon: Icons.inventory_2,
                      iconBg: const Color(0xFFFF7E2D).withValues(alpha: 0.1),
                      iconColor: const Color(0xFF9D4300),
                      title: 'Parcel to Downtown',
                      badge: 'Parcel',
                      badgeBg: const Color(0xFFFFDBCA),
                      badgeText: const Color(0xFF341100),
                      orderId: '#SD-88120',
                      time: 'Today, 10:15 AM',
                      statusLabel: 'Picking Up',
                      statusIcon: Icons.schedule,
                      statusBg: const Color(0xFFDDE4DD),
                      statusText: const Color(0xFF3C4A42),
                      middleChild: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.trip_origin,
                                  color: Color(0xFF6C7A71), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Pick up: 124 North Green St.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF3C4A42),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Color(0xFF006C49), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Drop off: Financial District Tower 4',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF161D19),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      bottomChild: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF006C49),
                            side: const BorderSide(
                                color: Color(0xFF10B981), width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'View Logistics Details',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Past orders
                    _buildPastOrderCard(
                      title: 'Sushi Zen Master',
                      orderId: '#SD-77123',
                      time: 'Oct 24, 7:30 PM',
                      price: '\$58.00',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String badge,
    required Color badgeBg,
    required Color badgeText,
    required String orderId,
    required String time,
    required String statusLabel,
    required IconData statusIcon,
    required Color statusBg,
    required Color statusText,
    required Widget middleChild,
    required Widget bottomChild,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F0E9), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF161D19),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$orderId • $time',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF3C4A42),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusText),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE8F0E9)),
                bottom: BorderSide(color: Color(0xFFE8F0E9)),
              ),
            ),
            child: middleChild,
          ),
          const SizedBox(height: 12),
          bottomChild,
        ],
      ),
    );
  }

  Widget _buildPastOrderCard({
    required String title,
    required String orderId,
    required String time,
    required String price,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F0E9), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE4DD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant,
                    color: Color(0xFF3C4A42), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF161D19),
                      ),
                    ),
                    Text(
                      '$orderId • $time',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF3C4A42),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE4DD),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'Delivered',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6C7A71),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                price,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF161D19),
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006C49),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Reorder',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String url) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: AppImage(url: url, fit: BoxFit.cover),
      ),
    );
  }
}
