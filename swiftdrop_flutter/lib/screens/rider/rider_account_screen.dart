import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../providers/rider_providers.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class RiderAccountScreen extends ConsumerStatefulWidget {
  const RiderAccountScreen({super.key});

  @override
  ConsumerState<RiderAccountScreen> createState() => _RiderAccountScreenState();
}

class _RiderAccountScreenState extends ConsumerState<RiderAccountScreen> {
  static const _services = {
    'food': ('Food', Icons.fastfood_rounded, Color(0xFFE86A22)),
    'pickup': ('Pickup', Icons.inventory_2_rounded, Color(0xFF5278D6)),
    'gas': ('Gas', Icons.local_gas_station_rounded, Color(0xFFB16B22)),
    'beauty': ('Beauty', Icons.spa_rounded, Color(0xFFB14E83)),
  };
  final Set<String> _selected = {};
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(riderSettingsProvider);
    final data = settings.valueOrNull;
    if (data != null && !_loaded) {
      _selected.addAll(((data['service_types'] as List?) ?? const []).cast<String>());
      _loaded = true;
    }
    final name = data?['name'] as String? ?? 'Rider';
    final rating = data?['rating'] ?? 0;
    final deliveries = data?['total_deliveries'] ?? 0;
    return Scaffold(
      backgroundColor: AppColors.paleMint,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(riderSettingsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              Text('Account', style: AppText.display(false)),
              const SizedBox(height: 6),
              Text('Keep your rider details ready for every trip.',
                  style: AppText.secondary(false)),
              const SizedBox(height: 24),
              _profileCard(name, data),
              const SizedBox(height: 20),
              Text('SERVICES YOU PROVIDE',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800,
                      letterSpacing: 1.2, color: AppColors.deepGreen)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Material(
                  color: Colors.transparent,
                  child: Column(children: _services.entries.map((entry) {
                    final service = entry.value;
                    return SwitchListTile(
                      secondary: Icon(service.$2, color: service.$3),
                      title: Text(service.$1, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      value: _selected.contains(entry.key),
                      onChanged: (value) => _updateService(entry.key, value),
                      activeThumbColor: AppColors.primary,
                    );
                  }).toList()),
                ),
              ),
              const SizedBox(height: 14),
              _section('Rider setup', [
                _item(Icons.description_outlined, 'Documents',
                    'Ghana Card, selfie and vehicle documents'),
                _item(Icons.badge_outlined, 'Vehicle',
                    data?['vehicle_type'] as String? ?? 'Not provided'),
                _item(Icons.account_balance_wallet_outlined, 'Available balance',
                    'GHS ${data?['earnings_balance'] ?? '0.00'}'),
                _item(Icons.star_outline_rounded, 'Rating & performance',
                    '$rating rating • $deliveries deliveries'),
              ]),
              const SizedBox(height: 14),
              _section('Support & safety', [
                _item(Icons.help_outline_rounded, 'Help centre',
                    'Quick answers and chat support'),
                _item(Icons.shield_outlined, 'Emergency safety',
                    'Call your emergency contact'),
                _item(Icons.settings_outlined, 'App settings',
                    'Notifications and appearance'),
              ]),
              const SizedBox(height: 14),
              _section('Account actions', [
                _actionItem(
                  Icons.shopping_bag_outlined,
                  'Switch to customer',
                  'Browse SwiftDrop and place customer orders',
                  () async {
                    await ref.read(userRoleProvider.notifier).setRole(UserRole.customer);
                    if (context.mounted) context.go('/home');
                  },
                ),
                _actionItem(
                  Icons.logout_rounded,
                  'Sign out',
                  'End this rider session on this device',
                  () async {
                    await ref.read(currentUserProvider.notifier).signOut();
                    if (context.mounted) context.go('/auth');
                  },
                  destructive: true,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileCard(String name, Map<String, dynamic>? data) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(24)),
    child: Row(children: [
      const CircleAvatar(radius: 28, backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.person_rounded, color: AppColors.primary, size: 30)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(data?['phone'] as String? ?? 'Rider profile',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
      ])),
    ]),
  );

  Future<void> _updateService(String service, bool enabled) async {
    setState(() => enabled ? _selected.add(service) : _selected.remove(service));
    final result = await ref.read(riderServiceProvider).updateSettings(
      serviceTypes: _selected.toList(),
    );
    if (result == null && mounted) {
      setState(() => enabled ? _selected.remove(service) : _selected.add(service));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save service preference')));
    } else {
      ref.invalidate(riderSettingsProvider);
      ref.invalidate(riderDashboardProvider);
    }
  }

  Widget _section(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800,
          letterSpacing: 1.2, color: AppColors.deepGreen)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Material(color: Colors.transparent, child: Column(children: children)),
      ),
    ],
  );

  Widget _item(IconData icon, String title, String subtitle) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
    leading: Icon(icon, color: AppColors.deepGreen, size: 21),
    title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
    subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.black54)),
  );

  Widget _actionItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool destructive = false,
  }) =>
      ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        leading: Icon(icon,
            color: destructive ? const Color(0xFFBA1A1A) : AppColors.deepGreen,
            size: 21),
        title: Text(title,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: destructive ? const Color(0xFFBA1A1A) : AppColors.nearBlack)),
        subtitle: Text(subtitle,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.black54)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black38),
      );
}
