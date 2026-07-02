import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// lucide_icons removed - using Material Icons
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';

enum AuthMode { login, signup, otp }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  AuthMode _mode = AuthMode.login;
  bool _loading = false;
  String? _error;
  bool _agreedToTerms = false;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // OTP state (6 digits)
  final List<String> _otpDigits = ['', '', '', '', '', ''];
  int _otpIndex = 0;
  int _countdown = 59;
  Timer? _countdownTimer;
  Timer? _errorTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _countdownTimer?.cancel();
    _errorTimer?.cancel();
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

  void _showError(String message) {
    _errorTimer?.cancel();
    setState(() => _error = message);
    _errorTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _error = null);
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

  Future<void> _handleLogin() async {
    if (_phoneController.text.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final sent = await ref.read(currentUserProvider.notifier).sendOtp(
          _phoneController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (sent) {
      setState(() => _mode = AuthMode.otp);
      _startCountdown();
    } else {
      _showError('Failed to send OTP');
    }
  }

  Future<void> _handleSignup() async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }
    if (!_agreedToTerms) {
      _showError('Please agree to the Terms of Service');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final sent = await ref.read(currentUserProvider.notifier).sendOtp(
          _phoneController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (sent) {
      setState(() => _mode = AuthMode.otp);
      _startCountdown();
    } else {
      _showError('Failed to send OTP');
    }
  }

  // OTP verification for phone login/signup
  Future<void> _handleOtp() async {
    if (_otpCode.length < 6) {
      _showError('Please enter the full 6-digit code');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final role = ref.read(userRoleProvider) == UserRole.rider ? 'rider' : 'customer';
    final name = _nameController.text.trim();
    final valid = await ref.read(currentUserProvider.notifier).verifyOtp(
          _phoneController.text.trim(),
          _otpCode,
          name: name.isNotEmpty ? name : null,
          role: role,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (valid) {
      final userRole = ref.read(userRoleProvider);
      if (userRole == UserRole.rider) {
        context.go('/rider/dashboard');
      } else {
        context.go('/home');
      }
    } else {
      _showError('Invalid code');
    }
  }

  void _submit() {
    if (_mode == AuthMode.login || _mode == AuthMode.signup) {
      if (!_formKey.currentState!.validate()) return;
    }
    switch (_mode) {
      case AuthMode.login:
        _handleLogin();
        break;
      case AuthMode.signup:
        _handleSignup();
        break;
      case AuthMode.otp:
        _handleOtp();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            color: isDark ? const Color(0xFF131B2E) : const Color(0xFFF4FBF4),
          ),

          // Top-left green blob
          Positioned(
            top: -100,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  color: Color(0x336FFBBE),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Bottom-right orange blob
          Positioned(
            bottom: -120,
            right: -120,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                width: 350,
                height: 350,
                decoration: const BoxDecoration(
                  color: Color(0x33FFDBCA),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Error toast
          if (_error != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: AnimatedOpacity(
                  opacity: _error != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 14),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _error = null),
                          child: const Icon(Icons.close,
                              color: Colors.white70, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18233C) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _mode == AuthMode.otp
                    ? _buildOtpContent(isDark)
                    : _buildFormContent(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_mode == AuthMode.signup)
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => setState(() => _mode = AuthMode.login),
                child: Icon(Icons.arrow_back,
                    color: isDark ? Colors.white70 : Colors.black54, size: 22),
              ),
            ),

          if (_mode == AuthMode.signup) const SizedBox(height: 12),

          if (_mode != AuthMode.signup) ...[
            // Logo
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    '\u26A1',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'SwiftDrop',
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? const Color(0xFF6FFBBE)
                      : const Color(0xFF006C49),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Title
          Center(
            child: Text(
              _mode == AuthMode.login
                  ? 'Welcome Back'
                  : 'Create Account',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              _mode == AuthMode.login
                  ? 'Sign in to continue'
                  : 'Join SwiftDrop today',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Fields
          if (_mode == AuthMode.signup) ...[
            _buildField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
          ],
          if (_mode == AuthMode.login || _mode == AuthMode.signup) ...[
            _buildField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              isDark: isDark,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
          ],

          // Forgot password
          if (_mode == AuthMode.signup) const SizedBox(height: 4),

          const SizedBox(height: 20),

          // Terms checkbox for signup
          if (_mode == AuthMode.signup)
            GestureDetector(
              onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _agreedToTerms
                          ? const Color(0xFF10B981)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _agreedToTerms
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.white24 : Colors.grey.shade400),
                        width: 1.5,
                      ),
                    ),
                    child: _agreedToTerms
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'I agree to the Terms of Service and Privacy Policy',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_mode == AuthMode.signup) const SizedBox(height: 20),

          // Button
          GestureDetector(
            onTap: _loading ? null : _submit,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF006C49)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _mode == AuthMode.login ? 'Sign In' : 'Sign Up',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (_mode == AuthMode.signup) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward,
                                color: Colors.white, size: 18),
                          ],
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _mode == AuthMode.login
                    ? "Don't have an account? "
                    : 'Already have an account? ',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              if (_mode == AuthMode.login || _mode == AuthMode.signup)
                GestureDetector(
                  onTap: () => setState(() => _mode = _mode == AuthMode.login
                      ? AuthMode.signup
                      : AuthMode.login),
                  child: Text(
                    _mode == AuthMode.login ? 'Sign Up' : 'Sign In',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFF6FFBBE)
                          : const Color(0xFF006C49),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpContent(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Back arrow
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => setState(() => _mode = AuthMode.login),
            child: Icon(Icons.arrow_back,
                color: isDark ? Colors.white70 : Colors.black54, size: 22),
          ),
        ),
        const SizedBox(height: 16),

        // Icon
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.key, color: Color(0xFF10B981), size: 26),
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Center(
          child: Text(
            'Verify Phone',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            _phoneController.text.isNotEmpty
                ? _phoneController.text
                : '+1 (555) 000-0000',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ),
        const SizedBox(height: 28),

        // OTP boxes (6 digits)
        GestureDetector(
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              final isActive = i == _otpIndex;
              final isFilled = _otpDigits[i].isNotEmpty;
              return Container(
                width: 44,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF10B981)
                        : isFilled
                            ? (isDark
                                ? const Color(0xFF6FFBBE)
                                : const Color(0xFF006C49))
                            : (isDark ? Colors.white12 : Colors.grey.shade200),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _otpDigits[i],
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 16),

        // Countdown
        Text(
          _countdown > 0 ? 'Resend code in ${_countdown}s' : 'Resend code',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: _countdown > 0
                ? (isDark ? Colors.white38 : Colors.black38)
                : (isDark ? const Color(0xFF6FFBBE) : const Color(0xFF006C49)),
          ),
        ),
        if (_countdown <= 0)
          GestureDetector(
            onTap: () {
              _startCountdown();
            },
            child: Text(
              'Resend',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFF6FFBBE) : const Color(0xFF006C49),
              ),
            ),
          ),

        const SizedBox(height: 24),

        // Custom numeric keypad
        _buildKeypad(isDark),

        const SizedBox(height: 20),

        // Verify button
        GestureDetector(
          onTap: _loading ? null : _handleOtp,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF6FFBBE) : const Color(0xFF006C49),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isDark
                          ? const Color(0xFF6FFBBE)
                          : const Color(0xFF006C49))
                      .withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Verify & Proceed',
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.black87 : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Back to login
        GestureDetector(
          onTap: () => setState(() => _mode = AuthMode.login),
          child: Text(
            'Back to login',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF6FFBBE) : const Color(0xFF006C49),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeypad(bool isDark) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'DEL'],
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: 68, height: 52);
              }
              if (key == 'DEL') {
                return GestureDetector(
                  onTap: _onOtpDelete,
                  child: Container(
                    width: 68,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.backspace,
                        size: 20, color: Colors.redAccent),
                  ),
                );
              }
              return GestureDetector(
                onTap: () => _onOtpKeyPress(key),
                child: Container(
                  width: 68,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      key,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode:
          validator != null ? AutovalidateMode.onUserInteraction : null,
      style: GoogleFonts.poppins(
        fontSize: 15,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        prefixIcon: Icon(icon,
            size: 18, color: isDark ? Colors.white24 : Colors.black26),
        suffixIcon: suffix,
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
        ),
      ),
    );
  }
}
