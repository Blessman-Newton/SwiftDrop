import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/merchant_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'toast_overlay.dart';

class RiderScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const RiderScaffold({super.key, required this.child});

  @override
  ConsumerState<RiderScaffold> createState() => _RiderScaffoldState();
}

class _RiderScaffoldState extends ConsumerState<RiderScaffold> {
  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/rider/dashboard')) return 0;
    if (location.startsWith('/rider/orders')) return 1;
    if (location.startsWith('/rider/active-delivery') ||
        location.startsWith('/rider/navigation')) return 1;
    if (location.startsWith('/rider/earnings')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    final isDark = ref.watch(riderDarkModeProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121814) : const Color(0xFFF4FBF4),
      body: ToastOverlay(
        child: widget.child,
      ),
      bottomNavigationBar: Container(
        height: 64,
        decoration: BoxDecoration(
          color: isDark
              ? const Color.fromRGBO(15, 23, 42, 0.95)
              : const Color.fromRGBO(255, 255, 255, 0.95),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? const Color.fromRGBO(30, 41, 59, 0.4)
                  : const Color.fromRGBO(241, 245, 249, 1),
              width: 1,
            ),
          ),
        ),
        child: BackdropFilter(
          filter: const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _RiderNavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                isActive: index == 0,
                onTap: () => context.go('/rider/dashboard'),
                isDark: isDark,
              ),
              _RiderNavItem(
                icon: Icons.local_shipping_rounded,
                label: 'Orders',
                isActive: index == 1,
                onTap: () => context.go('/rider/orders'),
                isDark: isDark,
              ),
              _RiderNavItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Earnings',
                isActive: index == 2,
                onTap: () => context.go('/rider/earnings'),
                isDark: isDark,
              ),
              _RiderNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isActive: false,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile coming soon!')),
                  );
                },
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiderNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _RiderNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? const Color(0xFF059669)
                  : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? const Color(0xFF059669)
                    : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
