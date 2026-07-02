import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_image.dart';
import '../providers/providers.dart';

class ParcelPackageDetailsScreen extends ConsumerStatefulWidget {
  const ParcelPackageDetailsScreen({super.key});

  @override
  ConsumerState<ParcelPackageDetailsScreen> createState() =>
      _ParcelPackageDetailsScreenState();
}

class _ParcelPackageDetailsScreenState
    extends ConsumerState<ParcelPackageDetailsScreen> {
  late String _selectedPackageType;
  late double _weight;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _lengthController;
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final booking = ref.read(parcelBookingProvider);
    _selectedPackageType = booking.packageType;
    _weight = booking.weight;
    _lengthController = TextEditingController(text: booking.lengthCm?.toString() ?? '');
    _widthController = TextEditingController(text: booking.widthCm?.toString() ?? '');
    _heightController = TextEditingController(text: booking.heightCm?.toString() ?? '');
    _notesController = TextEditingController(text: booking.riderNotes ?? '');
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _weightLabel {
    if (_weight >= 25) return '25kg+';
    return 'Up to ${_weight.toInt()}kg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4FBF4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF161D19)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Package Details',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF161D19),
          ),
        ),
        centerTitle: true,
        actions: const [SizedBox(width: 48)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Package Type
              Text(
                'PACKAGE TYPE',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3C4A42),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildPackageTypeCard(
                      'document', Icons.description, 'Document'),
                  _buildPackageTypeCard('box', Icons.inventory_2, 'Box'),
                  _buildPackageTypeCard(
                      'electronics', Icons.devices, 'Electronics'),
                  _buildPackageTypeCard('fragile', Icons.wine_bar, 'Fragile'),
                ],
              ),
              const SizedBox(height: 24),

              // Weight
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'APPROX. WEIGHT',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3C4A42),
                            letterSpacing: 1,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            _weightLabel,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF00422B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 6,
                        activeTrackColor: const Color(0xFF006C49),
                        inactiveTrackColor: const Color(0xFFE3EAE3),
                        thumbColor: const Color(0xFF006C49),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 12,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 20,
                        ),
                        overlayColor:
                            const Color(0xFF006C49).withValues(alpha: 0.1),
                      ),
                      child: Slider(
                        value: _weight,
                        min: 1,
                        max: 25,
                        onChanged: (val) => setState(() => _weight = val),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '1kg',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6C7A71),
                          ),
                        ),
                        Text(
                          '25kg+',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6C7A71),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Dimensions
              Text(
                'DIMENSIONS (CM) - OPTIONAL',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3C4A42),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDimensionField('Length', _lengthController),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDimensionField('Width', _widthController),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDimensionField('Height', _heightController),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Rider Notes
              Text(
                'RIDER NOTES',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3C4A42),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      "Add note for rider (e.g. 'Fragile, handle with care')",
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF6C7A71)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF161D19),
                ),
              ),
              const SizedBox(height: 24),

              // Package Photo
              Text(
                'PACKAGE PHOTO',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3C4A42),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 132,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3EAE3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFBBCABF),
                            width: 2,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_a_photo,
                              color: Color(0xFF6C7A71),
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Capture',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF3C4A42),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          AppImage(
                            url:
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuDgXK2pwJtBIDYz12WPHljgWYB8ZyBp6QHEVMUFdGkHn_JC6WpDjPWOc11UDpcM7Q2tdP2ocfUZEY_oXjVBNXiAdoteIYjelw5FmH3W_qL5s7IjEC7ZiF6fpY1Wdvnc52IaHepChOSJIBpVFzFi6MvfJhZ2fu_CiUbTYPF9QWFKb2y9Teb0bl5qauSLXzrcSg-tMwhr39-1A8LvECPwC4N1lG_rt2Su5hWGOzsAa-6KWL__4472wDr1eBTc_MRuR4zSRMdjH1q6uOY',
                            width: 132,
                            height: 132,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFBA1A1A)
                                      .withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Adding a photo helps ensure package security.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF6C7A71),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Color(0xFFF4FBF4),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 30,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          child: Semantics(
            label: 'Continue to service selection',
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final l = double.tryParse(_lengthController.text);
                    final w = double.tryParse(_widthController.text);
                    final h = double.tryParse(_heightController.text);
                    ref.read(parcelBookingProvider.notifier).updatePackage(
                          _selectedPackageType,
                          _weight,
                          l: l,
                          w: w,
                          h: h,
                          notes: _notesController.text.isEmpty ? null : _notesController.text,
                        );
                    context.push('/parcel/service');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006C49),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF006C49).withValues(alpha: 0.3),
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageTypeCard(String type, IconData icon, String label) {
    final isActive = _selectedPackageType == type;
    return Semantics(
      label: '$label package type${isActive ? ', selected' : ''}',
      child: GestureDetector(
        onTap: () => setState(() => _selectedPackageType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF10B981) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? const Color(0xFF10B981) : Colors.transparent,
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    const BoxShadow(
                      color: Color.fromRGBO(16, 185, 129, 0.2),
                      blurRadius: 25,
                      offset: Offset(0, 4),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.04),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: isActive
                    ? const Color(0xFF00422B)
                    : const Color(0xFF006C49),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? const Color(0xFF00422B)
                      : const Color(0xFF161D19),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDimensionField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF6C7A71),
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            final num = double.tryParse(value.trim());
            if (num == null || num <= 0) return 'Enter a valid number';
            return null;
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: GoogleFonts.inter(color: const Color(0xFF6C7A71)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF161D19),
          ),
        ),
      ],
    );
  }
}
