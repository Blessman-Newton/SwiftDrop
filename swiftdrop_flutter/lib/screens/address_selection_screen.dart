import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../services/tomtom_service.dart';
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
  final _mapController = MapController();
  final _tomtom = TomTomService();
  final _searchFocus = FocusNode();

  LatLng _center = TomTomService.defaultCenter;
  LatLng? _selectedPoint;
  String? _selectedAddress;
  String? _selectedLabel;
  List<TomTomSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _mapReady = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    if (widget.currentLat != null && widget.currentLng != null) {
      _center = LatLng(widget.currentLat!, widget.currentLng!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final point = LatLng(pos.latitude, pos.longitude);
      final result = await _tomtom.reverseGeocode(point);

      setState(() {
        _center = point;
        _selectedPoint = point;
        _selectedAddress = result?.address ?? '${pos.latitude}, ${pos.longitude}';
        _selectedLabel = 'Current Location';
        _searchController.text = _selectedAddress ?? '';
      });

      if (_mapReady) _mapController.move(point, 16);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.trim().length < 2) {
        setState(() => _searchResults = []);
        return;
      }
      setState(() => _isSearching = true);
      final results = await _tomtom.search(query, bias: _center);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectSearchResult(TomTomSearchResult result) {
    final point = LatLng(result.latitude, result.longitude);
    setState(() {
      _selectedPoint = point;
      _selectedAddress = result.address;
      _selectedLabel = result.name;
      _searchController.text = result.address;
      _searchResults = [];
      _center = point;
    });
    _searchFocus.unfocus();
    if (_mapReady) _mapController.move(point, 16);
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) async {
    setState(() {
      _selectedPoint = latLng;
      _selectedAddress = null;
      _selectedLabel = null;
      _searchResults = [];
    });
    final result = await _tomtom.reverseGeocode(latLng);
    if (mounted && result != null) {
      setState(() {
        _selectedAddress = result.address;
        _selectedLabel = result.name;
        _searchController.text = result.address;
      });
    }
  }

  void _confirmSelection() {
    if (_selectedPoint == null) return;
    Navigator.of(context).pop(AddressSelectionResult(
      address: _selectedAddress ?? '${_selectedPoint!.latitude}, ${_selectedPoint!.longitude}',
      lat: _selectedPoint!.latitude,
      lng: _selectedPoint!.longitude,
      label: _selectedLabel ?? 'Delivery Address',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildMap(),
          ],
        ),
      ),
      bottomNavigationBar: _selectedPoint != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _confirmSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Confirm Location',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Semantics(
            label: 'Go back',
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.arrow_back, color: Color(0xFF161D19), size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Select Address',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF161D19),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _useCurrentLocation,
            icon: const Icon(Icons.my_location, size: 18, color: AppColors.primary),
            label: Text(
              'GPS',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            onChanged: _onSearchChanged,
            onTap: () {},
            decoration: InputDecoration(
              hintText: 'Search address...',
              hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF006C49)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFBBCCBF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFBBCCBF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            style: GoogleFonts.inter(fontSize: 15),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
          if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final r = _searchResults[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                    title: Text(
                      r.name,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      r.address,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectSearchResult(r),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Expanded(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 14,
                maxZoom: 19,
                minZoom: 1,
                onTap: _onMapTap,
                onMapReady: () => _mapReady = true,
              ),
              children: [
                TileLayer(
                  urlTemplate: TomTomService.tileUrl,
                  userAgentPackageName: 'com.swiftdrop.app',
                ),
                if (_selectedPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedPoint!,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                            ],
                          ),
                          child: const Icon(Icons.location_on, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            // Zoom controls
            Positioned(
              right: 12,
              bottom: 24,
              child: Column(
                children: [
                  _mapZoomBtn(Icons.add, () {
                    if (_mapReady) {
                      final zoom = _mapController.camera.zoom + 1;
                      _mapController.move(_mapController.camera.center, zoom);
                    }
                  }),
                  const SizedBox(height: 4),
                  _mapZoomBtn(Icons.remove, () {
                    if (_mapReady) {
                      final zoom = _mapController.camera.zoom - 1;
                      _mapController.move(_mapController.camera.center, zoom);
                    }
                  }),
                ],
              ),
            ),
            // Selected address card
            if (_selectedAddress != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 24,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedLabel ?? 'Selected Location',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF161D19),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedAddress!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Tap hint
            if (_selectedPoint == null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 24,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Tap the map or search to select a location',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mapZoomBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF334155)),
      ),
    );
  }
}
