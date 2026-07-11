import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AddressSelectionResult {
  final String address;
  final double? lat;
  final double? lng;
  final String label;

  const AddressSelectionResult({
    required this.address,
    this.lat,
    this.lng,
    this.label = 'Delivery Address',
  });
}

class AddressSelectionScreen extends StatefulWidget {
  final String? currentAddress;
  final double? currentLat;
  final double? currentLng;

  const AddressSelectionScreen({
    super.key,
    this.currentAddress,
    this.currentLat,
    this.currentLng,
  });

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  final _searchController = TextEditingController();
  final _addressController = TextEditingController();
  final _labelController = TextEditingController();
  bool _useManualEntry = false;
  bool _useCurrentLocation = false;
  String _selectedLabel = 'Home';
  double? _selectedLat;
  double? _selectedLng;

  // Simulated Ghana locations for suggestions
  final List<Map<String, dynamic>> _savedAddresses = [
    {'label': 'Home', 'address': '123 Oxford Street, Osu, Accra', 'lat': 5.5600, 'lng': -0.1870},
    {'label': 'Work', 'address': '45 Independence Ave, Ridge, Accra', 'lat': 5.5560, 'lng': -0.1969},
  ];

  final List<Map<String, String>> _searchSuggestions = [
    {'address': 'Oxford Street, Osu, Accra', 'area': 'Osu'},
    {'address': 'Independence Ave, Ridge, Accra', 'area': 'Ridge'},
    {'address': 'Lincoln Avenue, Cantonments, Accra', 'area': 'Cantonments'},
    {'address': '14th Lane, Labone, Accra', 'area': 'Labone'},
    {'address': 'Nkrumah Ave, Kumasi', 'area': 'Kumasi'},
    {'address': 'Tema Station Road, Tema', 'area': 'Tema'},
    {'address': 'Spintex Road, Accra', 'area': 'Spintex'},
    {'address': 'East Legon Road, Accra', 'area': 'East Legon'},
    {'address': 'Haatso Extension, Accra', 'area': 'Haatso'},
    {'address': 'Madina Zongo Junction, Accra', 'area': 'Madina'},
  ];

  List<Map<String, String>> get _filteredSuggestions {
    if (_searchController.text.isEmpty) return [];
    final query = _searchController.text.toLowerCase();
    return _searchSuggestions
        .where((s) =>
            s['address']!.toLowerCase().contains(query) ||
            s['area']!.toLowerCase().contains(query))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addressController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _selectSavedAddress(Map<String, dynamic> addr) {
    setState(() {
      _selectedLabel = addr['label'];
      _addressController.text = addr['address'];
      _selectedLat = addr['lat'];
      _selectedLng = addr['lng'];
      _useManualEntry = false;
      _useCurrentLocation = false;
    });
  }

  void _selectSearchResult(Map<String, String> result) {
    setState(() {
      _addressController.text = result['address']!;
      _searchController.clear();
      _useManualEntry = true;
      _useCurrentLocation = false;
    });
  }

  void _useCurrentLoc() {
    setState(() {
      _useCurrentLocation = true;
      _useManualEntry = false;
      _addressController.text = 'Detecting current location...';
      _selectedLat = 5.5600;
      _selectedLng = -0.1870;
    });
    // Simulate GPS detection
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _addressController.text = 'Near Osu Oxford Street, Accra';
        });
      }
    });
  }

  void _saveAddress() {
    final address = _addressController.text.trim();
    if (address.isEmpty || address == 'Detecting current location...') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter or select an address', style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      AddressSelectionResult(
        address: address,
        lat: _selectedLat ?? 5.5600,
        lng: _selectedLng ?? -0.1870,
        label: _selectedLabel,
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
          'Delivery Address',
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
                  // Map Preview (Simulated)
                  _buildMapPreview(),
                  const SizedBox(height: 16),

                  // Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: 16),

                  // Saved Addresses
                  _buildSavedAddresses(),
                  const SizedBox(height: 16),

                  // Search Address
                  _buildSearchBar(),
                  const SizedBox(height: 8),

                  // Search Suggestions
                  if (_filteredSuggestions.isNotEmpty)
                    _buildSearchSuggestions(),

                  // Manual Entry
                  if (_useManualEntry || _addressController.text.isEmpty)
                    ...[
                      const SizedBox(height: 16),
                      _buildManualEntry(),
                    ],

                  // Address Label
                  if (_addressController.text.isNotEmpty &&
                      _addressController.text != 'Detecting current location...')
                    ...[
                      const SizedBox(height: 16),
                      _buildLabelSelector(),
                    ],
                ],
              ),
            ),
          ),

          // Save Button
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBCABF)),
      ),
      child: Stack(
        children: [
          // Simulated map grid
          CustomPaint(
            size: const Size(double.infinity, 180),
            painter: _MapGridPainter(),
          ),
          // Pin
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(0, 108, 73, 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _useCurrentLocation ? 'Current Location' : 'Delivery Pin',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 40,
                ),
              ],
            ),
          ),
          // Map controls
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              children: [
                _mapControlButton(Icons.add, () {}),
                const SizedBox(height: 4),
                _mapControlButton(Icons.remove, () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapControlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.08),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF3C4A42), size: 20),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.my_location,
            title: 'Use Current Location',
            subtitle: 'Auto-detect GPS',
            isSelected: _useCurrentLocation,
            onTap: _useCurrentLoc,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.edit_location_alt,
            title: 'Enter Manually',
            subtitle: 'Type your address',
            isSelected: _useManualEntry,
            onTap: () => setState(() {
              _useManualEntry = true;
              _useCurrentLocation = false;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF6EE) : Colors.white,
          borderRadius: BorderRadius.circular(12),
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
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF161D19),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedAddresses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Addresses',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF161D19),
          ),
        ),
        const SizedBox(height: 8),
        ..._savedAddresses.map((addr) => GestureDetector(
              onTap: () => _selectSavedAddress(addr),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedLabel == addr['label']
                        ? AppColors.primary
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedLabel == addr['label']
                            ? const Color(0xFFEEF6EE)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        addr['label'] == 'Home'
                            ? Icons.home_rounded
                            : Icons.work_rounded,
                        color: _selectedLabel == addr['label']
                            ? AppColors.primary
                            : const Color(0xFF6B7280),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            addr['label'],
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF161D19),
                            ),
                          ),
                          Text(
                            addr['address'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (_selectedLabel == addr['label'])
                      const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF161D19)),
        decoration: InputDecoration(
          hintText: 'Search address...',
          hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      ),
      child: Column(
        children: _filteredSuggestions.take(5).map((s) {
          return ListTile(
            dense: true,
            leading: const Icon(Icons.location_on_outlined, color: Color(0xFF9CA3AF), size: 20),
            title: Text(
              s['address']!,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF161D19)),
            ),
            subtitle: Text(
              s['area']!,
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF)),
            ),
            onTap: () => _selectSearchResult(s),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildManualEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Address',
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
            controller: _addressController,
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF161D19)),
            decoration: InputDecoration(
              hintText: 'Enter your full delivery address...',
              hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9CA3AF)),
              prefixIcon: const Icon(Icons.edit_location_alt, color: Color(0xFF9CA3AF), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabelSelector() {
    final labels = ['Home', 'Work', 'Other'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Label this address',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF161D19),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: labels.map((label) {
            final isSelected = _selectedLabel == label;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedLabel = label),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
              onPressed: _saveAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Save Address',
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

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC8E6C9)
      ..strokeWidth = 0.5;

    // Horizontal lines
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical lines
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Roads
    final roadPaint = Paint()
      ..color = const Color(0xFFA5D6A7)
      ..strokeWidth = 3;

    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.6),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.5, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
