import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/providers.dart';
import '../widgets/app_image.dart';
import '../widgets/notifications_sheet.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Saved addresses list
  final List<String> _addresses = [
    'Home: 123 Oak Street, Sunyani',
    'Work: 456 Tech Park Drive, Sunyani',
  ];

  // Selected language
  String _currentLanguage = 'English';

  // Referral code
  final String _referralCode = 'SWIFT-ALEX-2026';

  // Mock wallet transactions
  final List<Map<String, dynamic>> _transactions = [
    {'title': 'Wallet Top Up', 'amount': '+GHS 25.00', 'date': 'Today, 10:24 AM', 'type': 'credit'},
    {'title': 'Order #SF-8219', 'amount': '-GHS 42.50', 'date': 'Yesterday, 6:15 PM', 'type': 'debit'},
    {'title': 'Points Redeemed', 'amount': '+GHS 10.00', 'date': 'July 22, 2:40 PM', 'type': 'credit'},
  ];

  // Coupons
  final List<Map<String, dynamic>> _coupons = [
    {'code': 'SWIFT50', 'desc': '50% off your first order', 'valid': true},
    {'code': 'FREEDEL', 'desc': 'Free delivery on orders above GHS 30', 'valid': true},
    {'code': 'COSMETIC10', 'desc': '10% off cosmetics list', 'valid': true},
  ];

  // Help FAQ
  final List<Map<String, String>> _faqs = [
    {'q': 'How do I track my order?', 'a': 'You can track your order in real-time by clicking the tracking option in the active order card on the home screen or inside the Orders tab.'},
    {'q': 'Can I pay with Mobile Money (MoMo)?', 'a': 'Yes! Doorush supports MTN, Telecel, and AirtelTigo for both instant checkout payments and rider cashouts.'},
    {'q': 'What is the refund policy?', 'a': 'Refunds are automatically credited to your SwiftBalance when an order is cancelled by the merchant or failed to deliver.'},
    {'q': 'How do I contact customer support?', 'a': 'You can tap on the Live Chat option under Help & Support to chat with a support agent instantly.'},
  ];

  // Live chat mock messages
  final List<Map<String, dynamic>> _chatMessages = [
    {'sender': 'support', 'text': 'Hello! How can I help you today?', 'time': '10:00 AM'},
  ];
  final _chatController = TextEditingController();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            onPressed: () => NotificationsSheet.show(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                    ),
                    child: ClipOval(
                      child: AppImage(
                        url: user?.avatarUrl ?? '',
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        fallbackSeed: user?.displayName ?? 'Alex Johnson',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Alex Johnson',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary(isDark),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'customer@swiftdrop.com',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${profile.membershipTier} Member',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    onPressed: () => _showEditProfileSheet(user),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // GENERAL SECTION
            _buildCategoryGroup(
              'General',
              [
                _buildSettingsItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Personal Profile',
                  iconBg: const Color(0xFFE8F5E9),
                  iconColor: const Color(0xFF2E7D32),
                  onTap: () => _showEditProfileSheet(user),
                ),
                _buildSettingsItem(
                  icon: Icons.location_on_outlined,
                  label: 'My Address',
                  iconBg: const Color(0xFFFFF3E0),
                  iconColor: const Color(0xFFE65100),
                  onTap: () => _showSavedAddressesSheet(),
                ),
                _buildSettingsItem(
                  icon: Icons.language_rounded,
                  label: 'Language',
                  iconBg: const Color(0xFFE8EAF6),
                  iconColor: const Color(0xFF283593),
                  trailing: Text(
                    _currentLanguage,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                  ),
                  onTap: () => _showLanguageSheet(),
                ),
              ],
              isDark,
            ),

            // PROMOTIONAL ACTIVITY SECTION
            _buildCategoryGroup(
              'Promotional Activity',
              [
                _buildSettingsItem(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Coupon',
                  iconBg: const Color(0xFFFCE4EC),
                  iconColor: const Color(0xFFC2185B),
                  onTap: () => _showCouponsSheet(),
                ),
                _buildSettingsItem(
                  icon: Icons.stars_rounded,
                  label: 'Loyalty Points',
                  iconBg: const Color(0xFFFFFDE7),
                  iconColor: const Color(0xFFF57F17),
                  trailing: Text(
                    '${profile.points} pts',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFF57F17)),
                  ),
                  onTap: () => _showLoyaltyPointsSheet(profile),
                ),
              ],
              isDark,
            ),

            // ACTIVITIES SECTION
            _buildCategoryGroup(
              'Activities & Partnerships',
              [
                _buildSettingsItem(
                  icon: Icons.share_outlined,
                  label: 'Referral & Earn',
                  iconBg: const Color(0xFFE0F7FA),
                  iconColor: const Color(0xFF00838F),
                  onTap: () => _showReferralSheet(),
                ),
                _buildSettingsItem(
                  icon: Icons.delivery_dining_rounded,
                  label: 'Join as Delivery Rider',
                  iconBg: const Color(0xFFF3E5F5),
                  iconColor: const Color(0xFF6A1B9A),
                  onTap: () => _showJoinRiderSheet(),
                ),
                _buildSettingsItem(
                  icon: Icons.storefront_rounded,
                  label: 'Open a Store',
                  iconBg: const Color(0xFFEFEBE9),
                  iconColor: const Color(0xFF4E342E),
                  onTap: () => _showOpenStoreSheet(),
                ),
              ],
              isDark,
            ),

            // HELP & SUPPORT SECTION
            _buildCategoryGroup(
              'Help & Support',
              [
                _buildSettingsItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Live Chat',
                  iconBg: const Color(0xFFFFF8E1),
                  iconColor: const Color(0xFFFF8F00),
                  onTap: () => _showLiveChatSheet(),
                ),
                _buildSettingsItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  iconBg: const Color(0xFFE0F2F1),
                  iconColor: const Color(0xFF00695C),
                  onTap: () => _showHelpSupportSheet(),
                ),
                _buildSettingsItem(
                  icon: Icons.info_outline_rounded,
                  label: 'About Us',
                  iconBg: const Color(0xFFECEFF1),
                  iconColor: const Color(0xFF37474F),
                  onTap: () => _showLegalDocSheet('About Us', 'Doorush is the ultimate convenience platform in Sunyani, delivering fresh local and international food, gas refills, cosmetics, and custom courier pickup & delivery. Our mission is to connect customers, merchants, and riders seamlessly.'),
                ),
                _buildSettingsItem(
                  icon: Icons.description_outlined,
                  label: 'Terms & Conditions',
                  iconBg: const Color(0xFFECEFF1),
                  iconColor: const Color(0xFF37474F),
                  onTap: () => _showLegalDocSheet('Terms & Conditions', 'By using Doorush, you agree to our terms of service. Orders must be paid viaPaystack before delivery dispatch. Merchants are responsible for food quality and preparation, while riders handle secure transit.'),
                ),
                _buildSettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  iconBg: const Color(0xFFECEFF1),
                  iconColor: const Color(0xFF37474F),
                  onTap: () => _showLegalDocSheet('Privacy Policy', 'Your personal data is encrypted and secure. We track rider locations during active deliveries to ensure secure drop-offs. We never sell or share your transaction and contact details with unverified third parties.'),
                ),
                _buildSettingsItem(
                  icon: Icons.undo_rounded,
                  label: 'Refund Policy',
                  iconBg: const Color(0xFFECEFF1),
                  iconColor: const Color(0xFF37474F),
                  onTap: () => _showLegalDocSheet('Refund Policy', 'If your order is declined or cancelled, refunds are instantly credited back to your SwiftBalance. Instant transfers back to your mobile money wallet can take up to 24 hours depending on network providers.'),
                ),
                _buildSettingsItem(
                  icon: Icons.cancel_presentation_outlined,
                  label: 'Cancellation Policy',
                  iconBg: const Color(0xFFECEFF1),
                  iconColor: const Color(0xFF37474F),
                  onTap: () => _showLegalDocSheet('Cancellation Policy', 'Orders can be cancelled free of charge before the merchant accepts them. Once preparation begins, cancellation will incur a 50% penalty to compensate the merchant for ingredients used.'),
                ),
              ],
              isDark,
            ),
            const SizedBox(height: 16),

            // SIGN OUT BUTTON
            Semantics(
              label: 'Sign out',
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    ref.read(currentUserProvider.notifier).signOut();
                    context.go('/role-selection');
                  },
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFFBA1A1A)),
                  label: Text(
                    'Sign Out',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFBA1A1A),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFFFFDAD6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGroup(String title, List<Widget> children, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey[200]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required Color iconBg,
    required Color iconColor,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(isDark),
                  ),
                ),
              ),
              if (trailing != null) ...[
                trailing,
                const SizedBox(width: 8),
              ],
              Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white30 : Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Dynamic Sheet Helpers ---

  void _showEditProfileSheet(User? user) {
    final nameCtrl = TextEditingController(text: user?.displayName ?? 'Alex Johnson');
    final emailCtrl = TextEditingController(text: user?.email ?? 'customer@swiftdrop.com');
    final phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '+233201234567');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Personal Profile',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final updatedUser = user?.copyWith(
                      displayName: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      phoneNumber: phoneCtrl.text.trim(),
                    ) ?? User(
                      uid: 'mock_uid',
                      email: emailCtrl.text.trim(),
                      displayName: nameCtrl.text.trim(),
                      phoneNumber: phoneCtrl.text.trim(),
                      walletBalance: 0.0,
                      loyaltyPoints: 0,
                      membershipTier: 'Silver',
                    );
                    ref.read(currentUserProvider.notifier).state = updatedUser;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Profile updated successfully!', style: GoogleFonts.inter())),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSavedAddressesSheet() {
    final addrCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Saved Addresses',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                ..._addresses.map((addr) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.location_on, color: AppColors.primary),
                    title: Text(addr, style: GoogleFonts.inter(fontSize: 14)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() => _addresses.remove(addr));
                        setSheetState(() {});
                      },
                    ),
                  ),
                )),
                const SizedBox(height: 16),
                TextField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Add New Address',
                    prefixIcon: Icon(Icons.add_location_alt_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (addrCtrl.text.trim().isNotEmpty) {
                        setState(() => _addresses.add(addrCtrl.text.trim()));
                        addrCtrl.clear();
                        setSheetState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Address added successfully!', style: GoogleFonts.inter())),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Add Address', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageSheet() {
    final languages = ['English', 'Twi', 'Ga', 'Hausa', 'French'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Language / Kasa',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: languages.length,
                itemBuilder: (ctx, idx) {
                  final lang = languages[idx];
                  return RadioListTile<String>(
                    title: Text(lang, style: GoogleFonts.inter()),
                    value: lang,
                    groupValue: _currentLanguage,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _currentLanguage = val);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Language changed to $val', style: GoogleFonts.inter())),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCouponsSheet() {
    final promoCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Coupons',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                ..._coupons.map((coupon) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.local_offer_outlined, color: AppColors.primary),
                    title: Text(coupon['code'], style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    subtitle: Text(coupon['desc'], style: GoogleFonts.inter(fontSize: 12)),
                    trailing: TextButton(
                      child: const Text('Apply'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Coupon ${coupon['code']} applied successfully!', style: GoogleFonts.inter())),
                        );
                      },
                    ),
                  ),
                )),
                const SizedBox(height: 16),
                TextField(
                  controller: promoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Enter Promo Code',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.card_giftcard),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (promoCtrl.text.trim().isNotEmpty) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Promo code ${promoCtrl.text.trim().toUpperCase()} applied!', style: GoogleFonts.inter())),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Apply Promo Code'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLoyaltyPointsSheet(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loyalty Points & Tiers', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Text(
              'Your Balance: ${profile.points} Points',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text('Earn 1 point for every GHS 1 spent. Redeem points for immediate wallet cashback!', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: LinearProgressIndicator(
                value: (profile.points / 1000).clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text('${(1000 - profile.points).clamp(0, 1000)} points remaining for next loyalty tier.', style: GoogleFonts.inter(fontSize: 11)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: profile.points < 100
                    ? null
                    : () async {
                        final ok = await ref.read(userProfileProvider.notifier).redeemPoints(100);
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ok 
                              ? 'Redeemed 100 points for GHS 10.00 wallet credit!' 
                              : 'Failed to redeem points.', style: GoogleFonts.inter())),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Redeem 100 pts for GHS 10.00', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWalletDetailsSheet(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Wallet (SwiftBalance)', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF006C49), Color(0xFF10B981)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AVAILABLE BALANCE', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('GHS ${profile.walletBalance.toStringAsFixed(2)}', style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Quick Top-Up via MoMo', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [GHS10, GHS25, GHS50].map((amt) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        onPressed: () async {
                          final ok = await ref.read(userProfileProvider.notifier).topUp(amt);
                          if (ok) {
                            setSheetState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Topped up GHS ${amt.toStringAsFixed(2)} successfully!', style: GoogleFonts.inter())),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: Text('+ GHS $amt', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text('Recent Transactions', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._transactions.map((tx) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: tx['type'] == 'credit' ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                  child: Icon(tx['type'] == 'credit' ? Icons.arrow_upward : Icons.arrow_downward, color: tx['type'] == 'credit' ? Colors.green : Colors.red),
                ),
                title: Text(tx['title'], style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: Text(tx['date'], style: GoogleFonts.inter(fontSize: 11)),
                trailing: Text(tx['amount'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: tx['type'] == 'credit' ? Colors.green : Colors.red)),
              )),
            ],
          ),
        ),
      ),
    );
  }

  static const double GHS10 = 10.0;
  static const double GHS25 = 25.0;
  static const double GHS50 = 50.0;

  void _showReferralSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Refer a Friend & Earn!', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Share your referral code. When they place their first paid order, both of you earn GHS 10.00 cash directly into your SwiftBalance!', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_referralCode, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppColors.primary),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _referralCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Referral code copied to clipboard!', style: GoogleFonts.inter())),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showJoinRiderSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delivery_dining_rounded, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Drive for Doorush', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Earn premium weekly payouts, choose your own working hours, and get instant tips from customers. Complete simple KYC verification in the rider app and start delivering!', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/role-selection');
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Open Rider Portal', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOpenStoreSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_rounded, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Become a Doorush Merchant', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Sell food, drinks, cosmetics, or gas refill vouchers. Access thousands of local customers in Sunyani and track deliveries in real-time on our merchant dashboard.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/role-selection');
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Open Merchant Portal', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLiveChatSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Support Live Chat', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _chatMessages.length,
                    itemBuilder: (ctx, idx) {
                      final msg = _chatMessages[idx];
                      final isMe = msg['sender'] == 'me';
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.primary : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            msg['text'],
                            style: GoogleFonts.inter(color: isMe ? Colors.white : Colors.black87),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        decoration: const InputDecoration(hintText: 'Type your message...'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: AppColors.primary),
                      onPressed: () {
                        if (_chatController.text.trim().isNotEmpty) {
                          _chatMessages.add({
                            'sender': 'me',
                            'text': _chatController.text.trim(),
                            'time': 'Just now',
                          });
                          _chatController.clear();
                          setSheetState(() {});
                          Future.delayed(const Duration(seconds: 1), () {
                            if (mounted) {
                              _chatMessages.add({
                                'sender': 'support',
                                'text': 'Thanks for reaching out! A support representative will connect shortly.',
                                'time': 'Just now',
                              });
                              setSheetState(() {});
                            }
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpSupportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Frequently Asked Questions (FAQ)', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _faqs.length,
                itemBuilder: (ctx, idx) {
                  final faq = _faqs[idx];
                  return ExpansionTile(
                    title: Text(faq['q']!, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(faq['a']!, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700])),
                      )
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLegalDocSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Text(
              content,
              style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: Colors.grey[800]),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
