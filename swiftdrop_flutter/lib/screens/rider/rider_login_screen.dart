import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/merchant_providers.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';

class RiderLoginScreen extends ConsumerStatefulWidget {
  const RiderLoginScreen({super.key});

  @override
  ConsumerState<RiderLoginScreen> createState() => _RiderLoginScreenState();
}

class _RiderLoginScreenState extends ConsumerState<RiderLoginScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;

  // OTP state (6 digits)
  final List<String> _otpDigits = ['', '', '', '', '', ''];
  int _otpIndex = 0;
  int _countdown = 59;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 59;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0 && mounted) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _onOtpKeyPress(String key) {
    if (_otpIndex < 6) {
      setState(() {
        _otpDigits[_otpIndex] = key;
        _otpIndex++;
      });
    }
  }

  void _onOtpDelete() {
    if (_otpIndex > 0) {
      setState(() {
        _otpIndex--;
        _otpDigits[_otpIndex] = '';
      });
    }
  }

  String get _otpCode => _otpDigits.join();

  Future<void> _handleSendOtp() async {
    if (_phoneController.text.isEmpty) {
      ref.read(riderToastsProvider.notifier).add('Please enter your phone number', ToastType.error);
      return;
    }
    setState(() => _isLoading = true);
    ref.read(riderToastsProvider.notifier).add('Sending OTP...', ToastType.info);

    final sent = await ref.read(currentUserProvider.notifier).sendOtp(
          _phoneController.text.trim(),
        );
    if (mounted) {
      setState(() {
        _isLoading = false;
        _otpSent = sent;
      });
      if (sent) {
        _startCountdown();
        ref.read(riderToastsProvider.notifier).add('OTP sent successfully', ToastType.success);
      } else {
        ref.read(riderToastsProvider.notifier).add('Failed to send OTP. Please try again.', ToastType.error);
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpCode.length < 6) {
      ref.read(riderToastsProvider.notifier).add('Please enter the full 6-digit code', ToastType.error);
      return;
    }
    setState(() => _isLoading = true);
    ref.read(riderToastsProvider.notifier).add('Verifying...', ToastType.info);

    final valid = await ref.read(currentUserProvider.notifier).verifyOtp(
          _phoneController.text.trim(),
          _otpCode,
          name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
          role: 'rider',
        );
    if (mounted) {
      setState(() => _isLoading = false);
      if (valid) {
        final name = _nameController.text.trim().isEmpty ? 'Rider' : _nameController.text.trim();
        ref.read(riderToastsProvider.notifier).add('Welcome back, $name!', ToastType.success);
        context.go('/rider/dashboard');
      } else {
        ref.read(riderToastsProvider.notifier).add('Invalid OTP code', ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              _buildBrandHeader(),
              const SizedBox(height: 24),
              _buildLoginCard(),
              const SizedBox(height: 24),
              _buildWantToEarn(),
              const SizedBox(height: 24),
              _buildSecurityFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.login_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'SwiftDrop',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF059669),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: const Color(0xFFD1FAE5)),
            ),
            child: Text(
              'SECURE RIDER HUB',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rider Login',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _otpSent ? 'Enter the 6-digit code sent to your phone' : 'Secure access to your delivery dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          if (!_otpSent) ...[
            // Name Field
            _buildNameField(),
            const SizedBox(height: 16),
            // Phone Number Field
            _buildPhoneField(),
            const SizedBox(height: 16),
            // Send OTP Button
            _buildSendOtpButton(),
          ] else ...[
            // OTP Input
            _buildOtpSection(),
            const SizedBox(height: 16),
            // Verify Button
            _buildVerifyButton(),
            const SizedBox(height: 12),
            // Resend OTP
            _buildResendOtp(),
          ],
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Full Name',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Icon(
                Icons.person_outline,
                color: const Color(0xFF94A3B8),
                size: 18,
              ),
            ),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'John Doe',
                hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Icon(
                Icons.phone_outlined,
                color: const Color(0xFF94A3B8),
                size: 18,
              ),
            ),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              decoration: InputDecoration(
                hintText: '+233XXXXXXXXX',
                hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSendOtpButton() {
    return Semantics(
      label: 'Send OTP',
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSendOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: const Color(0x26059669),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Send OTP',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOtpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VERIFICATION CODE',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        // OTP digit boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            final hasValue = _otpDigits[index].isNotEmpty;
            return Container(
              width: 48,
              height: 56,
              decoration: BoxDecoration(
                color: hasValue ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasValue ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                  width: hasValue ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  _otpDigits[index],
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        // Custom keypad
        _buildOtpKeypad(),
      ],
    );
  }

  Widget _buildOtpKeypad() {
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'del'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: row.map((key) {
                if (key.isEmpty) return const Expanded(child: SizedBox(height: 48));
                if (key == 'del') {
                  return Expanded(
                    child: GestureDetector(
                      onTap: _onOtpDelete,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.backspace_outlined,
                          size: 20,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  );
                }
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onOtpKeyPress(key),
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Text(
                          key,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return Semantics(
      label: 'Verify OTP',
      child: ElevatedButton(
        onPressed: (_isLoading || _otpCode.length < 6) ? null : _handleVerifyOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: const Color(0x26059669),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Verify & Sign In',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildResendOtp() {
    return Center(
      child: GestureDetector(
        onTap: _countdown > 0 ? null : _handleSendOtp,
        child: Text(
          _countdown > 0 ? 'Resend OTP in ${_countdown}s' : 'Resend OTP',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _countdown > 0 ? const Color(0xFF94A3B8) : const Color(0xFF059669),
          ),
        ),
      ),
    );
  }

  Widget _buildWantToEarn() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromRGBO(226, 232, 240, 0.4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Want to earn with us? ',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Text(
              'Join the Fleet',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF059669),
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.open_in_new_rounded, size: 12, color: Color(0xFF059669)),
        ],
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shield_rounded, color: Color(0xFF94A3B8), size: 14),
        const SizedBox(width: 6),
        Text(
          '256-bit Encrypted',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(width: 24),
        const Icon(Icons.check_circle_rounded, color: Color(0xFF94A3B8), size: 14),
        const SizedBox(width: 6),
        Text(
          'Secure Identity',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
