import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MoMoPaymentResult {
  final String provider;
  final String phoneNumber;
  final String displayName;

  const MoMoPaymentResult({
    required this.provider,
    required this.phoneNumber,
    required this.displayName,
  });
}

class MoMoProvider {
  final String id;
  final String name;
  final String code;
  final Color color;
  final IconData icon;

  const MoMoProvider({
    required this.id,
    required this.name,
    required this.code,
    required this.color,
    required this.icon,
  });
}

const List<MoMoProvider> momoProviders = [
  MoMoProvider(
    id: 'mtn',
    name: 'MTN MoMo',
    code: 'MTN',
    color: Color(0xFFFFCC00),
    icon: Icons.phone_android,
  ),
  MoMoProvider(
    id: 'telecel',
    name: 'Telecel Cash',
    code: 'Telecel',
    color: Color(0xFFE31937),
    icon: Icons.phone_android,
  ),
  MoMoProvider(
    id: 'airteltigo',
    name: 'AirtelTigo Money',
    code: 'AirtelTigo',
    color: Color(0xFFE4002B),
    icon: Icons.phone_android,
  ),
];

class MoMoPaymentScreen extends StatefulWidget {
  final MoMoPaymentResult? currentMethod;

  const MoMoPaymentScreen({super.key, this.currentMethod});

  @override
  State<MoMoPaymentScreen> createState() => _MoMoPaymentScreenState();
}

class _MoMoPaymentScreenState extends State<MoMoPaymentScreen> {
  MoMoProvider? _selectedProvider;
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  bool _saveForFuture = true;

  @override
  void initState() {
    super.initState();
    if (widget.currentMethod != null) {
      _selectedProvider = momoProviders.firstWhere(
        (p) => p.id == widget.currentMethod!.provider,
        orElse: () => momoProviders[0],
      );
      _phoneController.text = widget.currentMethod!.phoneNumber;
      _nameController.text = widget.currentMethod!.displayName;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _savePaymentMethod() {
    if (_selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a Mobile Money provider', style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid phone number', style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter account holder name', style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      MoMoPaymentResult(
        provider: _selectedProvider!.id,
        phoneNumber: phone,
        displayName: name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF161D19)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mobile Money',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF161D19),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProviderSelection(),
                  const SizedBox(height: 20),
                  if (_selectedProvider != null) ...[
                    _buildPhoneInput(),
                    const SizedBox(height: 16),
                    _buildNameInput(),
                    const SizedBox(height: 16),
                    _buildSaveOption(),
                  ],
                ],
              ),
            ),
          ),
          if (_selectedProvider != null) _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildProviderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Provider',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF161D19),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose your Mobile Money provider',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),
        ...momoProviders.map((provider) {
          final isSelected = _selectedProvider?.id == provider.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedProvider = provider),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEEF6EE) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: provider.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(provider.icon, color: provider.color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF161D19),
                          ),
                        ),
                        Text(
                          'Pay with ${provider.name}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF161D19),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter your ${_selectedProvider?.name ?? 'MoMo'} phone number',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF161D19)),
            decoration: InputDecoration(
              hintText: '024 000 0000',
              hintStyle: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF9CA3AF)),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+233',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 24,
                      color: const Color(0xFFE5E7EB),
                    ),
                  ],
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Holder Name',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF161D19),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF161D19)),
            decoration: InputDecoration(
              hintText: 'John Doe',
              hintStyle: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF9CA3AF)),
              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF9CA3AF), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveOption() {
    return GestureDetector(
      onTap: () => setState(() => _saveForFuture = !_saveForFuture),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _saveForFuture ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _saveForFuture ? AppColors.primary : const Color(0xFFD1D5DB),
                ),
              ),
              child: _saveForFuture
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Save for future purchases',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF161D19),
                    ),
                  ),
                  Text(
                    'Quick checkout next time',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF006C49), Color(0xFF10B981)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(0, 108, 73, 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _savePaymentMethod,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Save Payment Method',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
