import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/merchant_providers.dart';
import '../../models/models.dart';
import '../../data/riders.dart';

class RiderEarningsScreen extends ConsumerStatefulWidget {
  const RiderEarningsScreen({super.key});

  @override
  ConsumerState<RiderEarningsScreen> createState() =>
      _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends ConsumerState<RiderEarningsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _chartController;
  late Animation<double> _chartAnimation;

  double _balance = 1482.50;
  bool _showWithdrawModal = false;
  String _withdrawAmount = '';
  bool _isWithdrawing = false;
  bool _withdrawSuccess = false;

  final double _maxWithdraw = 1482.50;

  static const List<double> _barHeights = [0.40, 0.65, 0.55, 0.85, 0.95, 0.30, 0.20];
  static const List<String> _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeOutCubic,
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _chartController.forward();
    });
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  void _handleWithdraw() {
    final amount = double.tryParse(_withdrawAmount);
    if (amount == null || amount <= 0 || amount > _maxWithdraw) return;

    setState(() => _isWithdrawing = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isWithdrawing = false;
          _withdrawSuccess = true;
          _balance -= amount;
        });
        ref.read(riderToastsProvider.notifier).add(
          'Successfully withdrew \$${amount.toStringAsFixed(2)}',
          ToastType.success,
        );
      }
    });
  }

  void _resetWithdrawModal() {
    setState(() {
      _showWithdrawModal = false;
      _withdrawAmount = '';
      _isWithdrawing = false;
      _withdrawSuccess = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF4),
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    children: [
                      _buildBalanceCard(),
                      const SizedBox(height: 20),
                      _buildWeeklyRevenueCard(),
                      const SizedBox(height: 20),
                      _buildDetailedBreakdown(),
                      const SizedBox(height: 20),
                      _buildPerformanceMetrics(),
                      const SizedBox(height: 20),
                      _buildRecentTransactions(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showWithdrawModal) _buildWithdrawModal(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            'SwiftDrop',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF10B981),
            ),
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 20, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF065F46), Color(0xFF0D9488)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(6, 95, 70, 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: Icon(
              Icons.account_balance_wallet,
              size: 128,
              color: const Color.fromRGBO(255, 255, 255, 0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AVAILABLE BALANCE',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFA7F3D0),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${_balance.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.10)),
                ),
                child: Text(
                  '+12% this week',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFA7F3D0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => setState(() => _showWithdrawModal = true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(0, 0, 0, 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFF1F5F9),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.credit_card, size: 16, color: Color(0xFF065F46)),
                      const SizedBox(width: 8),
                      Text(
                        'Withdraw Funds',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyRevenueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Revenue',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Row(
                children: [
                  Text(
                    'May 14 - May 20',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.calendar_today, size: 14, color: Color(0xFF94A3B8)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    final fraction = _barHeights[index];
                    final isActive = index == 4;
                    final barHeight = 140.0 * fraction * _chartAnimation.value;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Container(
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFF059669)
                                      : const Color.fromRGBO(16, 185, 129, 0.15),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: const Color.fromRGBO(5, 150, 105, 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _dayLabels[index],
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                                color: isActive
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFF1F5F9)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Text(
                          'AVG. DAILY',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$211.70',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: const Color(0xFFF1F5F9),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Text(
                          'TOTAL TRIPS',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '124',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF059669),
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

  Widget _buildDetailedBreakdown() {
    final items = [
      _BreakdownItem(
        icon: Icons.receipt_long,
        label: 'Base Fare',
        amount: '+\$940.00',
        iconBg: const Color(0xFFF8FAFC),
        iconColor: const Color(0xFF94A3B8),
        valueColor: const Color(0xFF1E293B),
      ),
      _BreakdownItem(
        icon: Icons.add_circle_outline,
        label: 'Tips',
        amount: '+\$325.50',
        iconBg: const Color(0xFFF8FAFC),
        iconColor: const Color(0xFF94A3B8),
        valueColor: const Color(0xFF059669),
      ),
      _BreakdownItem(
        icon: Icons.star_outline,
        label: 'Bonuses',
        amount: '+\$280.00',
        iconBg: const Color(0xFFF8FAFC),
        iconColor: const Color(0xFF94A3B8),
        valueColor: const Color(0xFF059669),
      ),
      _BreakdownItem(
        icon: Icons.remove_circle_outline,
        label: 'Fees',
        amount: '-\$63.00',
        iconBg: const Color(0xFFF8FAFC),
        iconColor: const Color(0xFF94A3B8),
        valueColor: const Color(0xFFF43F5E),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Breakdown',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: item.iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, size: 16, color: item.iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                Text(
                  item.amount,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: item.valueColor,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.star,
            iconColor: const Color(0xFFF59E0B),
            value: '4.92',
            label: 'Rating',
            filled: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.check_circle,
            iconColor: const Color(0xFF059669),
            value: '98%',
            label: 'Acceptance',
            filled: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.shield,
            iconColor: const Color(0xFFF43F5E),
            value: '0.8%',
            label: 'Canceled',
            filled: false,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required bool filled,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          filled
              ? Icon(icon, color: iconColor, size: 20)
              : Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            Text(
              'View All',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF059669),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...riderTransactions.take(3).map((tx) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color.fromRGBO(241, 245, 249, 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tx.timestamp,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '+\$${tx.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildWithdrawModal() {
    return GestureDetector(
      onTap: _resetWithdrawModal,
      child: Container(
        color: const Color.fromRGBO(15, 23, 42, 0.80),
        child: GestureDetector(
          onTap: () {},
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                border: Border(
                  top: BorderSide(color: Color(0xFFF1F5F9)),
                ),
              ),
              child: _withdrawSuccess
                  ? _buildWithdrawSuccess()
                  : _buildWithdrawForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWithdrawForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Withdraw Funds',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Available: \$${_balance.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _resetWithdrawModal,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'AMOUNT',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                '\$',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFCBD5E1),
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => setState(() => _withdrawAmount = val),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.credit_card, color: Color(0xFF94A3B8), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chase Bank Business (---- 9812)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Instant transfer (under 2 minutes)',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: (_withdrawAmount.isNotEmpty &&
                    double.tryParse(_withdrawAmount) != null &&
                    double.parse(_withdrawAmount) > 0 &&
                    double.parse(_withdrawAmount) <= _balance &&
                    !_isWithdrawing)
                ? _handleWithdraw
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFCBD5E1),
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isWithdrawing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Confirm Withdrawal',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildWithdrawSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFFA7F3D0),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Color(0xFF059669), size: 28),
        ),
        const SizedBox(height: 20),
        Text(
          'Withdrawal Successful!',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your funds will arrive in your Chase Bank\naccount within 2 minutes.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _resetWithdrawModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Done',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BreakdownItem {
  final IconData icon;
  final String label;
  final String amount;
  final Color iconBg;
  final Color iconColor;
  final Color valueColor;

  _BreakdownItem({
    required this.icon,
    required this.label,
    required this.amount,
    required this.iconBg,
    required this.iconColor,
    required this.valueColor,
  });
}
