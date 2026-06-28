import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/providers.dart';
import '../widgets/app_image.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Order? _selectedOrder;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF4),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      Row(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF10B981),
                                width: 4,
                              ),
                            ),
                            child: Stack(
                              children: [
                                ClipOval(
                                  child: AppImage(
                                    url: user?.avatarUrl ??
                                        'https://lh3.googleusercontent.com/aida-public/AB6AXuAwqgDiwFP1vJ2CnxsRalve_zQVmL3gs-rHYpCzbOuwKY7l_jwMY67AqghN3uJcNrCk0eCbDXB8croeuW5FYOt1oEDe63rSihQSS7B91ARrQtcFqfSteTXbrJrcZz_uStSZWL2cruRdPUfFaHNnFAEEoEdzKzQ6V7PeaiNQZqzLD81plfykwT2wPRK1Y4P9vr6E4BmbCPLuO0U4GO8K0N0hcZHho42zQfWcFIu9bjLUf_uoCrFu0RfGnF_PJyxVfHytX8-sF3_nTw4',
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF006C49),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.displayName ?? 'Alex Johnson',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF161D19),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFDBCA),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.workspace_premium,
                                          size: 14, color: Color(0xFF341100)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Gold Member',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF341100),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Wallet Section
                      Row(
                        children: [
                          // Main Wallet Card
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF006C49),
                                    Color(0xFF10B981)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 108, 73, 0.25),
                                    blurRadius: 16,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'SwiftBalance',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                            Icons.account_balance_wallet,
                                            color: Colors.white,
                                            size: 24),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '\$142.50',
                                    style: GoogleFonts.inter(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      _buildWalletAction(
                                          Icons.add_circle, 'Top Up'),
                                      const SizedBox(width: 8),
                                      _buildWalletAction(Icons.send, 'Send'),
                                      const SizedBox(width: 8),
                                      _buildWalletAction(
                                          Icons.history, 'History'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Points Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF6EE),
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
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Points',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF3C4A42),
                                        ),
                                      ),
                                      Text(
                                        '2,450',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF006C49),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(9999),
                                    child: LinearProgressIndicator(
                                      value: 0.75,
                                      backgroundColor: const Color(0xFFBBCABF),
                                      valueColor: const AlwaysStoppedAnimation(
                                          Color(0xFF006C49)),
                                      minHeight: 8,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '550 more for Platinum',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF3C4A42),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () {},
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF006C49),
                                        side: const BorderSide(
                                            color: Color(0xFF006C49)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'Redeem',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
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
                      const SizedBox(height: 24),

                      // Account Settings
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 16, 24, 12),
                              child: Text(
                                'Account Settings',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF161D19),
                                ),
                              ),
                            ),
                            const Divider(color: Color(0xFFDDE4DD), height: 1),
                            _buildSettingsItem(
                              icon: Icons.person,
                              label: 'Personal Information',
                              iconBg: const Color(0xFF10B981)
                                  .withValues(alpha: 0.2),
                              iconColor: const Color(0xFF006C49),
                            ),
                            _buildSettingsItem(
                              icon: Icons.payments,
                              label: 'Payment Methods',
                              iconBg: const Color(0xFFDAE2FD),
                              iconColor: const Color(0xFF565E74),
                            ),
                            _buildSettingsItem(
                              icon: Icons.location_on,
                              label: 'Saved Addresses',
                              iconBg: const Color(0xFFFFDBCA),
                              iconColor: const Color(0xFF9D4300),
                            ),
                            _buildSettingsItem(
                              icon: Icons.notifications_active,
                              label: 'Notifications',
                              iconBg: const Color(0xFF10B981)
                                  .withValues(alpha: 0.2),
                              iconColor: const Color(0xFF006C49),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFBA1A1A),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '2',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            _buildSettingsItem(
                              icon: Icons.group_add,
                              label: 'Refer a Friend',
                              iconBg: const Color(0xFFDAE2FD),
                              iconColor: const Color(0xFF565E74),
                            ),
                            _buildSettingsItem(
                              icon: Icons.security,
                              label: 'Security',
                              iconBg: const Color(0xFFFFDAD6),
                              iconColor: const Color(0xFFBA1A1A),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign Out
                      Semantics(
                        label: 'Sign out',
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () {
                              ref.read(currentUserProvider.notifier).signOut();
                              context.go('/role-selection');
                            },
                            icon: const Icon(Icons.logout,
                                color: Color(0xFFBA1A1A)),
                            label: Text(
                              'Sign Out',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFBA1A1A),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_selectedOrder != null) _buildOrderDetailModal(),
        ],
      ),
    );
  }

  Widget _buildWalletAction(IconData icon, String label) {
    return Expanded(
      child: Semantics(
        label: label,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required Color iconBg,
    required Color iconColor,
    Widget? trailing,
  }) {
    return Column(
      children: [
        const Divider(color: Color(0xFFDDE4DD), height: 1),
        Semantics(
          label: label,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color(0xFF161D19),
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  trailing,
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.chevron_right, color: Color(0xFF6C7A71)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetailModal() {
    if (_selectedOrder == null) return const SizedBox.shrink();
    final order = _selectedOrder!;
    return GestureDetector(
      onTap: () => setState(() => _selectedOrder = null),
      child: Container(
        color: Colors.black54,
        child: GestureDetector(
          onTap: () {},
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBBCABF),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order Details',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF161D19),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedOrder = null),
                        child:
                            const Icon(Icons.close, color: Color(0xFF6C7A71)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4FBF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt_long,
                              color: Color(0xFF006C49), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.restaurantName,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF161D19),
                                ),
                              ),
                              Text(
                                '${order.id} • ${_formatOrderDate(order.createdAt)}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF3C4A42),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ITEMS',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3C4A42),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}x ${item.foodItem.name}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF161D19),
                                ),
                              ),
                            ),
                            Text(
                              '\$${(item.foodItem.price * item.quantity).toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF161D19),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Color(0xFFE3EAE3)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF161D19),
                        ),
                      ),
                      Text(
                        '\$${order.totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF006C49),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF6EE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 16, color: Color(0xFF006C49)),
                        const SizedBox(width: 8),
                        Text(
                          'Delivered on ${_formatOrderDate(order.createdAt)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF3C4A42),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatOrderDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
