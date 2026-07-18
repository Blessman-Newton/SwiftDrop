import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/app_image.dart';
import '../utils/validators.dart';
import '../providers/providers.dart';
import '../services/tomtom_service.dart';
import 'address_selection_screen.dart';

class ParcelBookingScreen extends ConsumerStatefulWidget {
  final String pickupType;
  const ParcelBookingScreen({super.key, this.pickupType = 'package'});

  @override
  ConsumerState<ParcelBookingScreen> createState() => _ParcelBookingScreenState();
}

class _ParcelBookingScreenState extends ConsumerState<ParcelBookingScreen> {
  late final TextEditingController _pickupController;
  late final TextEditingController _deliveryController;
  late final TextEditingController _vendorNameController;
  late final TextEditingController _foodDetailsController;
  late final TextEditingController _packageNameController;
  late final TextEditingController _otherInstructionsController;
  final _formKey = GlobalKey<FormState>();

  final MapController _mapController = MapController();
  bool _mapReady = false;

  double? _lastPickupLat;
  double? _lastPickupLng;
  double? _lastDeliveryLat;
  double? _lastDeliveryLng;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    final booking = ref.read(parcelBookingProvider);
    _pickupController = TextEditingController(
      text: booking.pickupLocation.isNotEmpty ? booking.pickupLocation : 'Current Location (123 Urban St)',
    );
    _deliveryController = TextEditingController(
      text: booking.deliveryLocation,
    );
    _vendorNameController = TextEditingController();
    _foodDetailsController = TextEditingController();
    _packageNameController = TextEditingController();
    _otherInstructionsController = TextEditingController();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _deliveryController.dispose();
    _vendorNameController.dispose();
    _foodDetailsController.dispose();
    _packageNameController.dispose();
    _otherInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _updateRoute(LatLng origin, LatLng destination) async {
    try {
      final route = await TomTomService().calculateRoute(origin, destination);
      if (route != null && mounted) {
        setState(() {
          _routePoints = route.points;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(parcelBookingProvider);

    if (booking.pickupLat != _lastPickupLat ||
        booking.pickupLng != _lastPickupLng ||
        booking.deliveryLat != _lastDeliveryLat ||
        booking.deliveryLng != _lastDeliveryLng) {
      _lastPickupLat = booking.pickupLat;
      _lastPickupLng = booking.pickupLng;
      _lastDeliveryLat = booking.deliveryLat;
      _lastDeliveryLng = booking.deliveryLng;

      if (booking.pickupLat != null && booking.pickupLng != null &&
          booking.deliveryLat != null && booking.deliveryLng != null) {
        _updateRoute(
          LatLng(booking.pickupLat!, booking.pickupLng!),
          LatLng(booking.deliveryLat!, booking.deliveryLng!),
        );
      } else {
        _routePoints = [];
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mapReady) {
          if (booking.pickupLat != null && booking.pickupLng != null &&
              booking.deliveryLat != null && booking.deliveryLng != null) {
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: LatLngBounds.fromPoints([
                  LatLng(booking.pickupLat!, booking.pickupLng!),
                  LatLng(booking.deliveryLat!, booking.deliveryLng!),
                ]),
                padding: const EdgeInsets.only(top: 180, bottom: 280, left: 50, right: 50),
              ),
            );
          } else if (booking.pickupLat != null && booking.pickupLng != null) {
            _mapController.move(LatLng(booking.pickupLat!, booking.pickupLng!), 14);
          } else if (booking.deliveryLat != null && booking.deliveryLng != null) {
            _mapController.move(LatLng(booking.deliveryLat!, booking.deliveryLng!), 14);
          }
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF4),
      body: Stack(
        children: [
          // Map background
          Positioned.fill(
            child: ClipRect(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: TomTomService.defaultCenter,
                  initialZoom: 13,
                  maxZoom: 19,
                  minZoom: 1,
                  onMapReady: () {
                    _mapReady = true;
                    if (booking.pickupLat != null && booking.pickupLng != null &&
                        booking.deliveryLat != null && booking.deliveryLng != null) {
                      _mapController.fitCamera(
                        CameraFit.bounds(
                          bounds: LatLngBounds.fromPoints([
                            LatLng(booking.pickupLat!, booking.pickupLng!),
                            LatLng(booking.deliveryLat!, booking.deliveryLng!),
                          ]),
                          padding: const EdgeInsets.only(top: 180, bottom: 280, left: 50, right: 50),
                        ),
                      );
                    } else if (booking.pickupLat != null && booking.pickupLng != null) {
                      _mapController.move(LatLng(booking.pickupLat!, booking.pickupLng!), 14);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: TomTomService.tileUrl,
                    userAgentPackageName: 'com.swiftdrop.app',
                  ),
                  if (_routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          color: const Color(0xFF10B981),
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (booking.pickupLat != null && booking.pickupLng != null)
                        Marker(
                          point: LatLng(booking.pickupLat!, booking.pickupLng!),
                          width: 36,
                          height: 36,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF006C49),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: const Icon(Icons.location_on, color: Colors.white, size: 18),
                          ),
                        ),
                      if (booking.deliveryLat != null && booking.deliveryLng != null)
                        Marker(
                          point: LatLng(booking.deliveryLat!, booking.deliveryLng!),
                          width: 36,
                          height: 36,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7E2D),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: const Icon(Icons.location_on, color: Colors.white, size: 18),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF4FBF4),
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xFFF4FBF4),
                  ],
                  stops: [0.0, 0.15, 0.85, 1.0],
                ),
              ),
            ),
          ),
          // Top App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFF4FBF4),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Semantics(
                      label: 'Go back',
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: const Icon(Icons.arrow_back, size: 24, color: Color(0xFF161D19)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'SwiftDrop',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF006C49),
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      label: 'Help',
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Support center coming soon')),
                          );
                        },
                        child: const Icon(Icons.help_outline, size: 24, color: Color(0xFF161D19)),
                        ),
                      ),
                    ],
                ),
              ),
            ),
          ),
          // Content
          // Content - Top Booking Card
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 20,
            right: 20,
            child: Form(
              key: _formKey,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.48,
                ),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.1),
                      blurRadius: 25,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: const Color.fromRGBO(187, 202, 191, 0.2),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress indicator
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFF006C49),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 2,
                            height: widget.pickupType == 'package'
                                ? 210
                                : widget.pickupType == 'food'
                                    ? 240
                                    : 140,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: const DashedLinePainter(),
                          ),
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFFFF7E2D),
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Input fields
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.pickupType == 'food'
                                  ? 'FOOD PICKUP DETAILS'
                                  : widget.pickupType == 'other'
                                      ? 'OTHER PICKUP DETAILS'
                                      : 'PACKAGE PICKUP DETAILS',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF006C49),
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Dynamic Fields
                            if (widget.pickupType == 'food') ...[
                              _buildTextField(
                                label: 'VENDOR / RESTAURANT NAME',
                                controller: _vendorNameController,
                                hintText: 'e.g. Amina\'s Kitchen',
                                prefixIcon: Icons.restaurant,
                                validator: (val) => val == null || val.trim().isEmpty ? 'Vendor name required' : null,
                              ),
                              const SizedBox(height: 12),
                              _buildLocationField(
                                label: 'VENDOR ADDRESS (PICKUP)',
                                controller: _pickupController,
                                hintText: 'Where to collect food?',
                                onMapTap: () async {
                                  final result = await context.push<AddressSelectionResult>('/address-selection');
                                  if (result != null) {
                                    _pickupController.text = result.address;
                                    ref.read(parcelBookingProvider.notifier).updatePickup(
                                      result.address, lat: result.lat, lng: result.lng);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                label: 'ORDER INFO (ORDER #, PHONE, DETAILS)',
                                controller: _foodDetailsController,
                                hintText: 'e.g. Order #593, Call Kwame at 055...',
                                prefixIcon: Icons.info_outline,
                                maxLines: 2,
                                validator: (val) => val == null || val.trim().isEmpty ? 'Order details required' : null,
                              ),
                            ] else if (widget.pickupType == 'other') ...[
                              _buildTextField(
                                label: 'DESCRIPTION & INSTRUCTIONS',
                                controller: _otherInstructionsController,
                                hintText: 'e.g. Pick up my blue laundry bag, instructions...',
                                prefixIcon: Icons.description_outlined,
                                maxLines: 2,
                                validator: (val) => val == null || val.trim().isEmpty ? 'Instructions required' : null,
                              ),
                              const SizedBox(height: 12),
                              _buildLocationField(
                                label: 'PICKUP ADDRESS',
                                controller: _pickupController,
                                hintText: 'Where are we picking up from?',
                                onMapTap: () async {
                                  final result = await context.push<AddressSelectionResult>('/address-selection');
                                  if (result != null) {
                                    _pickupController.text = result.address;
                                    ref.read(parcelBookingProvider.notifier).updatePickup(
                                      result.address, lat: result.lat, lng: result.lng);
                                  }
                                },
                              ),
                            ] else ...[
                              _buildTextField(
                                label: 'PACKAGE NAME / TYPE',
                                controller: _packageNameController,
                                hintText: 'e.g. Documents, Laptop, Gift Box',
                                prefixIcon: Icons.shopping_bag_outlined,
                                validator: (val) => val == null || val.trim().isEmpty ? 'Package name required' : null,
                              ),
                              const SizedBox(height: 12),
                              _buildLocationField(
                                label: 'LOCATION OF PACKAGE (PICKUP)',
                                controller: _pickupController,
                                hintText: 'Where to collect package?',
                                onMapTap: () async {
                                  final result = await context.push<AddressSelectionResult>('/address-selection');
                                  if (result != null) {
                                    _pickupController.text = result.address;
                                    ref.read(parcelBookingProvider.notifier).updatePickup(
                                      result.address, lat: result.lat, lng: result.lng);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                label: 'NOTES & INSTRUCTIONS FOR RIDER',
                                controller: _otherInstructionsController,
                                hintText: 'e.g. Leave with security, call upon arrival',
                                prefixIcon: Icons.chat_bubble_outline,
                                maxLines: 2,
                              ),
                            ],
                            
                            Container(
                              height: 1,
                              color: Colors.grey[200],
                              margin: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            
                            _buildLocationField(
                              label: 'DELIVERY DESTINATION',
                              controller: _deliveryController,
                              hintText: 'Where is it going?',
                              onMapTap: () async {
                                final result = await context.push<AddressSelectionResult>('/address-selection');
                                if (result != null) {
                                  _deliveryController.text = result.address;
                                  ref.read(parcelBookingProvider.notifier).updateDelivery(
                                    result.address, lat: result.lat, lng: result.lng);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Content - Bottom Panel
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Actions (Saved Addresses)
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCurrentLocationButton(),
                      const SizedBox(width: 16),
                      _buildSavedAddress(
                        icon: Icons.home,
                        label: 'Home',
                        address: '242 Oak Avenue',
                      ),
                      const SizedBox(width: 16),
                      _buildSavedAddress(
                        icon: Icons.work,
                        label: 'Work',
                        address: 'Innovation Plaza',
                      ),
                      const SizedBox(width: 16),
                      Semantics(
                        label: 'Add new address',
                        child: GestureDetector(
                          onTap: () async {
                            final result = await context.push<AddressSelectionResult>('/address-selection');
                            if (result != null) {
                              _pickupController.text = result.address;
                              ref.read(parcelBookingProvider.notifier).updatePickup(
                                result.address, lat: result.lat, lng: result.lng);
                            }
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3EAE3).withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.05),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Color(0xFF161D19),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Bottom Action Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final notifier = ref.read(parcelBookingProvider.notifier);
                        notifier.updatePickup(_pickupController.text);
                        notifier.updateDelivery(_deliveryController.text);

                        if (widget.pickupType == 'food') {
                          notifier.updatePackage(
                            'document',
                            1.0,
                            notes: 'Vendor Name: ${_vendorNameController.text}\nOrder details & Instructions: ${_foodDetailsController.text}',
                          );
                          context.push('/parcel/service');
                        } else if (widget.pickupType == 'other') {
                          notifier.updatePackage(
                            'box',
                            2.0,
                            notes: 'Special Instructions: ${_otherInstructionsController.text}',
                          );
                          context.push('/parcel/service');
                        } else {
                          notifier.updatePackage(
                            'box',
                            5.0,
                            notes: 'Package: ${_packageNameController.text}\nInstructions: ${_otherInstructionsController.text}',
                          );
                          context.push('/parcel/details');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: const Color(0xFF00422B),
                      elevation: 8,
                      shadowColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          (widget.pickupType == 'food' || widget.pickupType == 'other')
                              ? 'Continue to Service Options'
                              : 'Continue to Package Details',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
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

  Widget _buildLocationField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    VoidCallback? onMapTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3C4A42),
                letterSpacing: 0.5,
              ),
            ),
            Semantics(
              label: 'Choose $label on map',
              child: GestureDetector(
                onTap: onMapTap,
                child: Row(
                children: [
                  const Icon(Icons.map, size: 16, color: Color(0xFF006C49)),
                  const SizedBox(width: 4),
                  Text(
                    'Set on map',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF006C49),
                    ),
                  ),
                ],
              ),
            ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: (value) => Validators.required(value, fieldName: label),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(color: const Color(0xFF6C7A71)),
            filled: true,
            fillColor: const Color(0xFFE8F0E9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF161D19),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentLocationButton() {
    return GestureDetector(
      onTap: () async {
        try {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.deniedForever ||
              permission == LocationPermission.denied) return;

          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          );
          final tomtom = TomTomService();
          final result = await tomtom.reverseGeocode(
            LatLng(pos.latitude, pos.longitude),
          );
          if (mounted) {
            final addr = result?.address ??
                '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
            _pickupController.text = addr;
            ref.read(parcelBookingProvider.notifier).updatePickup(
              addr, lat: pos.latitude, lng: pos.longitude);
          }
        } catch (_) {}
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF006C49).withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF006C49), width: 1.5),
        ),
        child: const Icon(
          Icons.my_location,
          color: Color(0xFF006C49),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSavedAddress({
    required IconData icon,
    required String label,
    required String address,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3EAE3).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(9999),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF006C49), size: 16),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF161D19),
                ),
              ),
              Text(
                address,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: const Color(0xFF3C4A42),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 16, color: const Color(0xFF006C49)) : null,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[100]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF006C49)),
            ),
          ),
        ),
      ],
    );
  }
}

class DashedLinePainter extends StatelessWidget {
  const DashedLinePainter({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedLinePainter(),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBBCABF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
