import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../providers/providers.dart';
import '../providers/restaurant_provider.dart';
import '../services/tomtom_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_image.dart';
import '../models/models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _selectedLocation = 'Sunyani, Ghana';
  final TomTomService _tomtom = TomTomService();

  // Popular foods near you (images resolve via FoodImages keyword match).
  static const List<Map<String, String>> _popularFoods = [
    {'name': 'Jollof Rice', 'price': 'GHS 80'},
    {'name': 'Waakye', 'price': 'GHS 35'},
    {'name': 'Banku & Tilapia', 'price': 'GHS 60'},
    {'name': 'Fried Rice & Chicken', 'price': 'GHS 70'},
    {'name': 'Shawarma', 'price': 'GHS 45'},
    {'name': 'Chicken & Chips', 'price': 'GHS 55'},
  ];

  late PageController _pageController;
  int _currentBannerPage = 0;

  final List<Map<String, dynamic>> _banners = [
    {
      'tag': 'LIMITED TIME',
      'title': '20% OFF Your First Order',
      'subtitle': 'Use code SWIFT20 at checkout',
      'button': 'Claim Offer',
      'route': '/food-delivery',
      'imageUrl': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600',
      'colors': [const Color(0xE6064E3B), const Color(0xCC065F46)],
    },
    {
      'tag': 'GAS SERVICES',
      'title': 'Book us to refill your gas now',
      'subtitle': 'Schedule refills, safe, reliable & fast delivery',
      'button': 'Book a Refill',
      'route': '/parcel-delivery',
      'imageUrl': 'https://images.unsplash.com/photo-1628102428189-6c4538be649f?w=600',
      'colors': [const Color(0xE61E3A8A), const Color(0xCC3B82F6)],
    },
    {
      'tag': 'HEALTHCARE',
      'title': 'Medicine Pharmacy Delivery',
      'subtitle': 'Prescriptions & OTC drugs safely delivered',
      'button': 'Buy Medicine',
      'route': '/parcel-delivery',
      'imageUrl': 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=600',
      'colors': [const Color(0xE64C1D95), const Color(0xCC8B5CF6)],
    },
    {
      'tag': 'PARCEL EXPRESS',
      'title': 'Send Parcels City-Wide',
      'subtitle': 'Fast and secure courier dispatch',
      'button': 'Send Package',
      'route': '/parcel-delivery',
      'imageUrl': 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=600',
      'colors': [const Color(0xE60F766E), const Color(0xCC14B8A6)],
    },
  ];

  static const List<Map<String, dynamic>> _cosmetics = [
    {
      'id': 'cos_1',
      'name': 'Cocoa Butter Lotion',
      'price': 45.0,
      'image': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400',
      'desc': 'Rich nourishing body cream for smooth skin.',
    },
    {
      'id': 'cos_2',
      'name': 'Shea Moisture Hair Oil',
      'price': 60.0,
      'image': 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?w=400',
      'desc': 'Pure Ghanaian raw shea butter infusion.',
    },
    {
      'id': 'cos_3',
      'name': 'Matte Lipstick (Ruby)',
      'price': 35.0,
      'image': 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=400',
      'desc': 'Long-lasting vibrant matte lip color.',
    },
    {
      'id': 'cos_4',
      'name': 'Aloe Vera Facial Gel',
      'price': 25.0,
      'image': 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400',
      'desc': 'Soothes and hydrates skin naturally.',
    },
    {
      'id': 'cos_5',
      'name': 'Coconut Oil Lip Balm',
      'price': 12.0,
      'image': 'https://images.unsplash.com/photo-1617897903246-719242758050?w=400',
      'desc': 'Protects lips against dryness and wind.',
    },
  ];

  void _addCosmeticToCart(Map<String, dynamic> c) {
    final foodItem = FoodItem(
      id: c['id'] as String,
      name: c['name'] as String,
      price: c['price'] as double,
      description: c['desc'] as String,
      imageUrl: c['image'] as String,
      category: FoodCategory.sides,
    );
    ref.read(cartProvider.notifier).addItem(
      foodItem,
      restaurantId: 'cosmetics_store',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${c['name']} to cart'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildCircularNavRow(bool isDark) {
    final items = [
      {
        'label': 'Food',
        'icon': Icons.fastfood_rounded,
        'color': const Color(0xFF10B981),
        'onTap': () => context.push('/food-delivery'),
      },
      {
        'label': 'Pickup',
        'icon': Icons.delivery_dining_rounded,
        'color': const Color(0xFF6366F1),
        'onTap': () => context.push('/parcel/booking'),
      },
      {
        'label': 'Gas Refill',
        'icon': Icons.gas_meter_rounded,
        'color': const Color(0xFFF59E0B),
        'onTap': () => context.push('/gas-booking'),
      },
      {
        'label': 'Cosmetics',
        'icon': Icons.face_retouching_natural_rounded,
        'color': const Color(0xFFEC4899),
        'onTap': () => context.push('/cosmetics-list'),
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((item) {
        final Color color = item['color'] as Color;
        return GestureDetector(
          onTap: item['onTap'] as VoidCallback,
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    item['icon'] as IconData,
                    color: color,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['label'] as String,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _scrollController = ScrollController();
    _initializeCurrentLocation();
  }

  Future<void> _initializeCurrentLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;

      // Use medium accuracy + timeout to avoid hanging on high-precision GPS
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        ).timeout(const Duration(seconds: 15));
      } catch (_) {
        // Fallback: use last known position if fresh fix times out
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos == null || !mounted) return;
      final result = await _tomtom.reverseGeocode(
          LatLng(pos.latitude, pos.longitude));
      if (mounted) {
        setState(() {
          _selectedLocation = result?.address ??
              '${pos!.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favorites = ref.watch(favoritesProvider);
    final searchQuery = _searchController.text.toLowerCase();
    final selectedCuisines = ref.watch(selectedCuisinesProvider);
    final maxPrice = ref.watch(maxPriceLevelProvider);
    final sortOption = ref.watch(sortOptionProvider);
    final restaurantsAsync = ref.watch(restaurantsProvider);

    final restaurants = restaurantsAsync.value ?? [];

    // Cuisine chips derived from real restaurant tags, Ghana-first ordering.
    const ghanaCuisines = [
      'Local', 'Jollof', 'Waakye', 'Banku', 'Grill', 'Fast Food',
      'Pizza', 'Chinese', 'Continental', 'Healthy', 'Snacks', 'Drinks',
    ];
    final availableTags = <String>{for (final r in restaurants) ...r.tags};
    final derivedChips = [
      ...ghanaCuisines.where(availableTags.contains),
      ...availableTags.where((t) => !ghanaCuisines.contains(t)),
    ].take(10).toList();
    final cuisineChips =
        derivedChips.isNotEmpty ? derivedChips : ghanaCuisines.take(8).toList();

    var filteredRestaurants = restaurants.where((r) {
      final matchesSearch = r.name.toLowerCase().contains(searchQuery) ||
          r.tags.any((t) => t.toLowerCase().contains(searchQuery));
      final matchesCuisine = selectedCuisines.isEmpty ||
          r.tags.any((t) => selectedCuisines.contains(t));
      final matchesPrice = r.priceLevel <= maxPrice;
      return matchesSearch && matchesCuisine && matchesPrice;
    }).toList();

    switch (sortOption) {
      case SortOption.rating:
        filteredRestaurants.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.distance:
        filteredRestaurants.sort(
            (a, b) => a.distanceMiles.compareTo(b.distanceMiles));
        break;
      case SortOption.deliveryTime:
        filteredRestaurants.sort((a, b) => a.deliveryTime
            .compareTo(b.deliveryTime));
        break;
      case SortOption.priceLow:
        filteredRestaurants.sort(
            (a, b) => a.priceLevel.compareTo(b.priceLevel));
        break;
    }

    return Container(
      height: double.infinity,
      color: AppColors.background(isDark),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {},
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              // Sticky header
              Container(
                color: isDark
                    ? AppColors.darkBackground.withOpacity(0.8)
                    : Colors.white.withOpacity(0.8),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Location
                  GestureDetector(
                    onTap: () {
                      final searchCtrl = TextEditingController();
                      List<TomTomSearchResult> results = [];
                      bool isSearching = false;

                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (ctx) => StatefulBuilder(
                          builder: (ctx, setSheetState) => Padding(
                            padding: EdgeInsets.fromLTRB(
                              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Location',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: const Icon(Icons.my_location, color: AppColors.primary),
                                  title: Text('Use Current Location',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    try {
                                      LocationPermission perm = await Geolocator.checkPermission();
                                      if (perm == LocationPermission.denied) {
                                        perm = await Geolocator.requestPermission();
                                      }
                                      if (perm == LocationPermission.denied ||
                                          perm == LocationPermission.deniedForever) return;
                                      final pos = await Geolocator.getCurrentPosition(
                                        locationSettings: const LocationSettings(
                                            accuracy: LocationAccuracy.high));
                                      final result = await _tomtom.reverseGeocode(
                                        LatLng(pos.latitude, pos.longitude));
                                      if (mounted) {
                                        setState(() {
                                          _selectedLocation = result?.address ??
                                              '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
                                        });
                                      }
                                    } catch (_) {}
                                  },
                                ),
                                const Divider(),
                                TextField(
                                  controller: searchCtrl,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: 'Search city or address...',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onChanged: (q) async {
                                    if (q.trim().length < 2) {
                                      setSheetState(() => results = []);
                                      return;
                                    }
                                    setSheetState(() => isSearching = true);
                                    final r = await _tomtom.search(q);
                                    setSheetState(() {
                                      results = r;
                                      isSearching = false;
                                    });
                                  },
                                ),
                                if (isSearching) const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: LinearProgressIndicator(),
                                ),
                                if (results.isNotEmpty)
                                  Container(
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: results.length,
                                      itemBuilder: (ctx, i) => ListTile(
                                        dense: true,
                                        leading: const Icon(Icons.location_on,
                                            color: AppColors.primary, size: 20),
                                        title: Text(results[i].name,
                                            style: GoogleFonts.inter(fontSize: 14)),
                                        subtitle: Text(results[i].address,
                                            style: GoogleFonts.inter(fontSize: 11,
                                                color: Colors.grey[600]),
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          setState(() => _selectedLocation =
                                              results[i].address.isNotEmpty
                                                  ? results[i].address
                                                  : results[i].name);
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Location',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[400],
                                letterSpacing: 0.5,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  _selectedLocation,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary(isDark),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '▼',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  Semantics(
                    label: 'Search restaurants',
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child:
                                Icon(Icons.search, color: Colors.grey, size: 18),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: 'Search food, groceries, or parcels...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _showFilterSheet,
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.tune,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildCircularNavRow(isDark),
                  const SizedBox(height: 20),
                  Container(
                      height: (MediaQuery.of(context).size.height * 0.22).clamp(144.0, 172.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              onPageChanged: (int index) {
                                setState(() {
                                  _currentBannerPage = index;
                                });
                              },
                              itemCount: _banners.length,
                              itemBuilder: (context, index) {
                                final b = _banners[index];
                                final gradientColors = b['colors'] as List<Color>;

                                return GestureDetector(
                                  onTap: () => context.push(b['route'] as String),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      AppImage(
                                        url: b['imageUrl'] as String,
                                        fit: BoxFit.cover,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              gradientColors[0],
                                              gradientColors[1],
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(99),
                                                border: Border.all(
                                                  color: Colors.white.withOpacity(0.15),
                                                ),
                                              ),
                                              child: Text(
                                                b['tag'] as String,
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              b['title'] as String,
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                height: 1.2,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              b['subtitle'] as String,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.white.withOpacity(0.9),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(99),
                                              ),
                                              child: Text(
                                                b['button'] as String,
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: gradientColors[0],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            // Indicators
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  _banners.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: _currentBannerPage == index ? 16 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _currentBannerPage == index ? Colors.white : Colors.white54,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                     // Quick Actions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QUICK ACTIONS',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400],
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _quickAction(
                              icon: Icons.local_shipping,
                              label: 'Track',
                              onTap: () => context.push('/map'),
                            ),
                            _quickAction(
                              icon: Icons.replay,
                              label: 'History',
                              onTap: () => context.push('/booking-history'),
                            ),
                            _quickAction(
                              icon: Icons.account_balance_wallet,
                              label: 'Wallet',
                              onTap: () => context.push('/profile'),
                            ),
                            _quickAction(
                              icon: Icons.headset_mic,
                              label: 'Support',
                              onTap: () => context.push('/profile'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Popular Foods
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Popular Foods',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(isDark),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/food-delivery'),
                        child: Text(
                          'See All',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 170,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _popularFoods.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final food = _popularFoods[index];
                        return GestureDetector(
                          onTap: () => context.push('/food-delivery'),
                          child: Container(
                            width: 150,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              color: AppColors.surface(isDark),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(isDark ? 0.2 : 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 100,
                                  width: double.infinity,
                                  child: AppImage(
                                    url: '',
                                    fit: BoxFit.cover,
                                    fallbackSeed: food['name'],
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 8, 10, 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        food['name']!,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              AppColors.textPrimary(isDark),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        food['price']!,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                     const SizedBox(height: 24),


                  if (false) Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Popular Near You',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(isDark),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/food-delivery'),
                        child: Semantics(
                          label: 'See all restaurants',
                           child: Text(
                           'See All',
                           style: GoogleFonts.inter(
                             fontSize: 12,
                             fontWeight: FontWeight.bold,
                             color: AppColors.primary,
                           ),
                         ),
                       ),
                       ),
                     ],
                  ),
                  // Popular Cosmetics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Popular Cosmetics',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(isDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _cosmetics.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final cos = _cosmetics[index];
                        return Container(
                          width: 170,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Image
                              Container(
                                height: 110,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    AppImage(
                                      url: cos['image'] as String,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Beauty',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple.shade700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Product details
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cos['name'] as String,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            cos['desc'] as String,
                                            style: GoogleFonts.inter(
                                              fontSize: 9,
                                              color: Colors.grey.shade500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '₵${cos['price'].toStringAsFixed(2)}',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _addCosmeticToCart(cos),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.add,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
      ),
    );
  }

  void _toggleCuisine(String cuisine) {
    final current = ref.read(selectedCuisinesProvider);
    final updated = Set<String>.from(current);
    if (updated.contains(cuisine)) {
      updated.remove(cuisine);
    } else {
      updated.add(cuisine);
    }
    ref.read(selectedCuisinesProvider.notifier).state = updated;
  }

  void _showFilterSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer(
        builder: (ctx, sheetRef, _) {
          final sort = sheetRef.watch(sortOptionProvider);
          final maxPrice = sheetRef.watch(maxPriceLevelProvider);
          const sorts = {
            SortOption.rating: 'Top Rated',
            SortOption.distance: 'Nearest First',
            SortOption.deliveryTime: 'Fastest Delivery',
            SortOption.priceLow: 'Price: Low to High',
          };
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, 20 + MediaQuery.of(ctx).padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border(isDark),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Filter & Sort', style: AppText.heading(isDark)),
                const SizedBox(height: 16),
                Text('SORT BY', style: AppText.label(isDark)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sorts.entries.map((e) {
                    final active = sort == e.key;
                    return GestureDetector(
                      onTap: () => sheetRef
                          .read(sortOptionProvider.notifier)
                          .state = e.key,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          e.value,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text('MAX PRICE', style: AppText.label(isDark)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(3, (i) {
                    final level = i + 1;
                    final active = maxPrice >= level;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => sheetRef
                            .read(maxPriceLevelProvider.notifier)
                            .state = level,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '\$' * level,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: active ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Show results',
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCuisineChip(String label, bool selected, VoidCallback onTap) {
    return Semantics(
      label: '$label cuisine${selected ? ', selected' : ''}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
