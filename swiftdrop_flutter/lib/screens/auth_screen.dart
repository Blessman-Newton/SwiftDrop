import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../utils/user_friendly_error.dart';

enum AuthMode { login, signup }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  AuthMode _mode = AuthMode.login;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  UserRole get _selectedRole => ref.watch(userRoleProvider) == UserRole.rider
      ? UserRole.rider
      : UserRole.customer;

  void _showError(String message) => setState(() => _error = message);

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_mode == AuthMode.signup &&
        _passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notifier = ref.read(currentUserProvider.notifier);
      final user = _mode == AuthMode.login
          ? await notifier.loginWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            )
          : await notifier.signUp(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              phone: _phoneController.text.trim(),
              name: _nameController.text.trim(),
              role: _selectedRole == UserRole.rider ? 'rider' : 'customer',
            );
      if (!mounted) return;
      if (user == null) {
        _showError('Authentication failed. Please try again.');
        return;
      }
      final expectedRole =
          _selectedRole == UserRole.rider ? 'rider' : 'customer';
      if (user.role != expectedRole) {
        await notifier.signOut();
        _showError(
          'This account is registered as ${user.role == 'rider' ? 'a Rider' : 'a User'}. '
          'Choose the matching account type to continue.',
        );
        return;
      }
      await ref.read(userRoleProvider.notifier).setRole(_selectedRole);
      if (mounted) {
        context.go(expectedRole == 'rider' ? '/rider/dashboard' : '/home');
      }
    } catch (e) {
      if (mounted) _showError(userFriendlyError(e, action: 'complete authentication'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showForgotPassword() async {
    final controller = TextEditingController(text: _emailController.text);
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email address'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || email.isEmpty || !mounted) return;
    try {
      await ref
          .read(currentUserProvider.notifier)
          .sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent.')),
        );
      }
    } catch (e) {
      if (mounted) _showError(userFriendlyError(e, action: 'send the password reset email'));
    }
  }

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primaryLight;
    final isRider = _selectedRole == UserRole.rider;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Doorush',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Text(
                        _mode == AuthMode.login
                            ? 'Welcome back'
                            : 'Create your account',
                        textAlign: TextAlign.center,
                        style: AppText.heading(false)),
                    const SizedBox(height: 28),
                    _roleSwitch(color, isRider),
                    const SizedBox(height: 28),
                    if (_error != null) ...[
                      _message(_error!, Colors.red.shade700),
                      const SizedBox(height: 16),
                    ],
                    if (_mode == AuthMode.signup) ...[
                      _field(_nameController, 'Full name', Icons.person_outline,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter your name'
                              : null),
                      const SizedBox(height: 14),
                      _field(_phoneController, 'Phone number',
                          Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter your phone number'
                              : null),
                      const SizedBox(height: 14),
                    ],
                    _field(
                        _emailController, 'Email address', Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email),
                    const SizedBox(height: 14),
                    _field(_passwordController, 'Password', Icons.lock_outline,
                        obscureText: _obscurePassword,
                        validator: _passwordValidator,
                        suffix: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword))),
                    if (_mode == AuthMode.signup) ...[
                      const SizedBox(height: 14),
                      _field(_confirmPasswordController, 'Confirm password',
                          Icons.lock_outline,
                          obscureText: _obscurePassword,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Confirm your password'
                              : null),
                    ],
                    if (_mode == AuthMode.login)
                      Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              onPressed: _showForgotPassword,
                              child: Text('Forgot password?',
                                  style: TextStyle(color: color)))),
                    const SizedBox(height: 12),
                    SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                              backgroundColor: color,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(_mode == AuthMode.login
                                  ? 'Sign In'
                                  : 'Create account'),
                        )),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() {
                                _mode = _mode == AuthMode.login
                                    ? AuthMode.signup
                                    : AuthMode.login;
                                _error = null;
                              }),
                      child: Text(
                          _mode == AuthMode.login
                              ? 'New to Doorush? Create an account'
                              : 'Already have an account? Sign in',
                          style: TextStyle(color: color)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleSwitch(Color color, bool isRider) => Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: const Color(0xFFF1F5F3),
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          _roleButton('Rider', UserRole.rider, isRider, color),
          _roleButton('User', UserRole.customer, !isRider, color),
        ]),
      );

  Widget _roleButton(String label, UserRole role, bool selected, Color color) =>
      Expanded(
        child: GestureDetector(
          onTap: () async => ref.read(userRoleProvider.notifier).setRole(role),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(6)),
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color:
                        selected ? AppColors.primary : Colors.grey.shade600)),
          ),
        ),
      );

  Widget _field(TextEditingController controller, String label, IconData icon,
          {TextInputType? keyboardType,
          bool obscureText = false,
          String? Function(String?)? validator,
          Widget? suffix}) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: AppColors.primaryLight),
            suffixIcon: suffix),
      );

  String? _passwordValidator(String? value) {
    final error = Validators.password(value);
    if (error != null) return error;
    if (_mode == AuthMode.signup && value!.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  Widget _message(String message, Color color) => Container(
        padding: const EdgeInsets.all(12),
        color: color.withValues(alpha: .08),
        child: Text(message, style: TextStyle(color: color)),
      );
}
