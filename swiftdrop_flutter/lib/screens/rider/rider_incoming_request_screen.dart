import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class RiderIncomingRequestScreen extends StatefulWidget {
  const RiderIncomingRequestScreen({super.key});
  @override
  State<RiderIncomingRequestScreen> createState() =>
      _RiderIncomingRequestScreenState();
}

class _RiderIncomingRequestScreenState
    extends State<RiderIncomingRequestScreen> {
  int seconds = 30;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (seconds == 0) {
        timer?.cancel();
        context.go('/rider/orders');
      } else {
        setState(() => seconds--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.notifications_active_rounded,
                    color: AppColors.primaryLight, size: 22),
                const SizedBox(width: 8),
                Text('NEW DELIVERY REQUEST',
                    style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1)),
                const Spacer(),
                _timer(),
              ]),
              const SizedBox(height: 22),
              Text('A quick one for you',
                  style: AppText.display(false).copyWith(color: Colors.white)),
              const SizedBox(height: 6),
              Text('Sunyani • 2.4 km away',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 22),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(children: [
                    _serviceCard(),
                    const SizedBox(height: 12),
                    _routeCard(),
                    const SizedBox(height: 12),
                    _moneyCard(),
                  ]),
                ),
              ),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/rider/orders'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18))),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => context.go('/rider/active-delivery'),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18))),
                    child: const Text('Accept request',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timer() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14)),
        child: Text('${seconds}s',
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
      );

  Widget _serviceCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E8),
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.fastfood_rounded,
                  color: Color(0xFFE86A22), size: 28)),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Food delivery',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.nearBlack)),
            const SizedBox(height: 4),
            Text('KFC Sunyani • 1 order',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
          ]),
        ]),
      );

  Widget _routeCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(22)),
        child: Column(children: [
          _stop(Icons.storefront_rounded, 'PICK UP', 'KFC Sunyani, Main Street',
              AppColors.deepGreen),
          Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Container(height: 20, width: 1, color: Colors.black12)),
          _stop(Icons.location_on_rounded, 'DROP OFF',
              'UENR Hostel A, Sunyani', const Color(0xFFD85B4C)),
        ]),
      );

  Widget _stop(IconData icon, String label, String address, Color color) =>
      Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.black45,
                  letterSpacing: 1)),
          Text(address,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.nearBlack)),
        ]),
      ]);

  Widget _moneyCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          Expanded(
              child: _amount('DELIVERY FEE', 'GHS 18.00', AppColors.primary)),
          Container(
              height: 42,
              width: 1,
              color: AppColors.primary.withValues(alpha: .2)),
          Expanded(
              child: _amount('PAY ON DELIVERY', 'GHS 0.00', AppColors.primary)),
        ]),
      );

  Widget _amount(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 5),
          Text(value,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        ]),
      );
}
