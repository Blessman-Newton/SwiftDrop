import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class RiderAccountScreen extends StatelessWidget {
  const RiderAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paleMint,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            Text('Account', style: AppText.display(false)),
            const SizedBox(height: 6),
            Text('Keep your rider details ready for every trip.',
                style: AppText.secondary(false)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.person_rounded,
                        color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kwame Mensah',
                            style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text('Rider ID  •  DR-2048',
                            style: GoogleFonts.inter(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _section('Rider setup', [
              _item(Icons.badge_outlined, 'Documents',
                  'Ghana Card, selfie and bike'),
              _item(Icons.account_balance_wallet_outlined, 'Payout details',
                  'MTN Mobile Money •••• 4821'),
              _item(Icons.star_outline_rounded, 'Rating & performance',
                  '4.9 rating • 98% completion'),
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
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.deepGreen)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(children: children),
          ),
        ],
      );

  Widget _item(IconData icon, String title, String subtitle) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: AppColors.paleMint,
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.deepGreen, size: 21),
        ),
        title: Text(title,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.nearBlack)),
        subtitle: Text(subtitle,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.black54)),
        trailing:
            const Icon(Icons.chevron_right_rounded, color: Colors.black38),
      );
}
