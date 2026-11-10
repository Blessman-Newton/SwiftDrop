import 'package:flutter/material.dart';
import '../../services/api_endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/auth_provider.dart';
import '../../providers/merchant_providers.dart';
import '../../providers/rider_providers.dart';
import '../../theme/app_theme.dart';

class RiderDashboardScreen extends ConsumerWidget {
  const RiderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(riderDashboardProvider);
    final available = ref.watch(riderAvailableOrdersProvider);
    final name = ref.watch(currentUserProvider)?.displayName?.split(' ').first ?? 'Kwame';
    final data = dashboard.valueOrNull;
    final bool online = data?['is_online'] == true ||
        (data == null && ref.watch(riderOnlineProvider) == true);
    final services = ((data?['service_types'] as List?) ?? const []).cast<String>();
    return Scaffold(
      backgroundColor: AppColors.paleMint,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(riderDashboardProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            children: [
              Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Good morning, $name',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: AppColors.nearBlack)),
                  const SizedBox(height: 4),
                  Text('Make today count in Sunyani.',
                      style: AppText.secondary(false)),
                ]),
                const Spacer(),
                IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: AppColors.primary)),
              ]),
              const SizedBox(height: 20),
              _onlineCard(context, ref, online),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _stat('TODAY', 'GHS ${(data?['today_earnings'] as num?)?.toStringAsFixed(2) ?? '0.00'}', Icons.payments_outlined)),
                const SizedBox(width: 10),
                Expanded(child: _stat('TRIPS', '${data?['today_trips'] ?? 0}', Icons.route_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _stat('RATING', '${data?['rating'] ?? '0.0'}', Icons.star_rounded)),
              ]),
              const SizedBox(height: 22),
              Text('Nearby requests',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.nearBlack)),
              const SizedBox(height: 10),
              _mapCard(context, available.valueOrNull ?? const []),
              const SizedBox(height: 22),
              Row(children: [
                Text('Your services',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.nearBlack)),
                const Spacer(),
                Text('${services.length} enabled',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepGreen)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _service(Icons.fastfood_rounded, 'Food', const Color(0xFFE86A22), services.contains('food')),
                _service(Icons.inventory_2_rounded, 'Pickup', const Color(0xFF5278D6), services.contains('pickup')),
                _service(Icons.local_gas_station_rounded, 'Gas', const Color(0xFFB16B22), services.contains('gas')),
                _service(Icons.spa_rounded, 'Beauty', const Color(0xFFB14E83), services.contains('beauty')),
              ]),
              const SizedBox(height: 22),
              _tipCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _onlineCard(BuildContext context, WidgetRef ref, bool online) =>
      GestureDetector(
        onTap: () => _setOnline(ref, !online),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: online ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: online ? AppColors.primary : Colors.black12)),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: online ? AppColors.primaryLight : AppColors.paleMint,
                    shape: BoxShape.circle),
                child: Icon(online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                    color: AppColors.primary)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(online ? 'You are online' : 'You are offline',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: online ? Colors.white : AppColors.nearBlack)),
                  const SizedBox(height: 3),
                  Text(online ? 'Ready to receive trips' : 'Go online to receive trips',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: online ? Colors.white70 : Colors.black54)),
                ])),
            Switch(
                value: online,
                onChanged: (value) => _setOnline(ref, value),
                activeThumbColor: AppColors.primaryLight),
          ]),
        ),
      );

  Widget _stat(String label, String value, IconData icon) => Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppColors.deepGreen, size: 20),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.nearBlack)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.black45,
                  letterSpacing: .7)),
        ]),
      );

  Future<void> _setOnline(WidgetRef ref, bool value) async {
    final service = ref.read(riderServiceProvider);
    final result = value ? await service.goOnline() : await service.goOffline();
    if (result) {
      ref.read(riderOnlineProvider.notifier).state = value;
      ref.invalidate(riderDashboardProvider);
      ref.invalidate(riderAvailableOrdersProvider);
    }
  }

  Widget _mapCard(BuildContext context, List<Map<String, dynamic>> orders) => Container(
          height: 190,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
          child: Stack(children: [
            FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(7.9465, -1.0232),
                initialZoom: 13,
                interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate: '${ApiEndpoints.baseUrl}/api/v1/maps/tile/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.blessman.swiftdrop',
                ),
                MarkerLayer(markers: [
                  for (final order in orders)
                    if (order['pickup_lat'] is num && order['pickup_lng'] is num)
                      Marker(
                        point: LatLng(
                          (order['pickup_lat'] as num).toDouble(),
                          (order['pickup_lng'] as num).toDouble(),
                        ),
                        width: 36,
                        height: 36,
                        child: const Icon(Icons.location_on_rounded,
                            color: AppColors.deepGreen, size: 34),
                      ),
                ]),
              ],
            ),
            Positioned(
              top: 14,
              left: 14,
              child: _mapPill(Icons.near_me_rounded, '${orders.length} requests nearby'),
            ),
            if (orders.isEmpty)
              const Center(child: Text('No nearby requests')),
          ]),
        );

  Widget _mapPill(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: AppColors.deepGreen),
          const SizedBox(width: 5),
          Text(text,
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.nearBlack)),
        ]),
      );

  Widget _service(IconData icon, String label, Color color, bool enabled) => Expanded(
        child: Column(children: [
          Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: enabled ? Colors.white : Colors.black12,
                  borderRadius: BorderRadius.circular(18)),
              child: Icon(icon, color: enabled ? color : Colors.black38, size: 24)),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.nearBlack)),
        ]),
      );

  Widget _tipCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFFE1F5E9),
            borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.deepGreen),
          const SizedBox(width: 12),
          Expanded(
              child: Text('Peak hours are 12–2pm and 5–8pm. Stay near the campus hub for more requests.',
                  style: GoogleFonts.inter(
                      fontSize: 12, height: 1.4, color: AppColors.deepGreen))),
        ]),
      );
}
