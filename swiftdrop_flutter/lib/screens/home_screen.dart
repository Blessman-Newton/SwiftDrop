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

  @override
  void dispose() {
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
                  const SizedBox(height: 16),

                  // Active order banner
                  Consumer(builder: (context, ref, _) {
                    final activeOrder = ref.watch(activeOrderProvider);
                    if (activeOrder == null) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () => context.push('/map'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.local_shipping,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Active Order',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Track your ${activeOrder.restaurantName} order',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white.withOpacity(0.7),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

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

                  const SizedBox(height: 12),

                  // Cuisine filter chips
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCuisineChip('All', selectedCuisines.isEmpty, () {
                          ref.read(selectedCuisinesProvider.notifier).state =
                              {};
                        }),
                        for (final cuisine in cuisineChips)
                          _buildCuisineChip(
                            cuisine,
                            selectedCuisines.contains(cuisine),
                            () => _toggleCuisine(cuisine),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                   Container(
                     height: (MediaQuery.of(context).size.height * 0.22).clamp(100.0, 164.0),
                     decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF064E3B).withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AppImage(
                              url: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDNBK_IsWI0V2kfET0GK3y2sPZBDmkxXB29o74YLS45LCunvNzGHrNrsLuBTH3xqRjc4Z3Idv0zkCS6Uz1Dx3mzWEvnFRbiFVGqExzAzhhl-QriMTepUQMKCJBqJuZfdHTcdb2W9g3dqCqpm34avYn9lQdDUnDCrg20RBs8r1SqcRZCyjFLKqSGFnJ4p8KQEPTiGyfWKCpiN20M9e9ZSMB-ROms4qmZrs24i2pkZF2xu94XtafTcdudN30ZHc8vULn_8xJ6A6rsqjw',
                              fit: BoxFit.cover,
                            ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  const Color(0xE6064E3B),
                                  const Color(0xCC065F46),
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
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Text(
                                    'LIMITED TIME',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '20% OFF Your First Order',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text.rich(
                                  TextSpan(
                                    text: 'Use code ',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'SWIFT20',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF6FFBBE),
                                        ),
                                      ),
                                      const TextSpan(
                                          text: ' at checkout'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () => context.push('/food-delivery'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      'Order Now',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
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
                     ),

                     const SizedBox(height: 24),

                   // Bento grid
                  Row(
                    children: [
                      // Food Delivery
                      Expanded(
                        child: Semantics(
                          label: 'Food Delivery',
                          child: GestureDetector(
                            onTap: () => context.push('/food-delivery'),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.restaurant,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Food Delivery',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'From local gems',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  right: -8,
                                  bottom: -8,
                                  child: Icon(
                                    Icons.restaurant,
                                    size: 80,
                                    color: Colors.grey[100],
                                  ),
                                ),
                               ],
                             ),
                           ),
                         ),
                       ),
                       ),
                      const SizedBox(width: 16),
                      // Parcel Courier
                      Expanded(
                        child: Semantics(
                          label: 'Parcel Courier',
                          child: GestureDetector(
                            onTap: () => context.push('/parcel/booking'),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2,
                                        color: Colors.indigo,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Parcel Courier',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Safe and prompt',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  right: -8,
                                  bottom: -8,
                                  child: Icon(
                                    Icons.inventory_2,
                                    size: 80,
                                    color: Colors.grey[100],
                                  ),
                                ),
                               ],
                             ),
                           ),
                         ),
                       ),
                       ),
                       ],
                     ),

                     const SizedBox(height: 24),
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

                    // Popular Near You
                  Row(
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
                  const SizedBox(height: 16),

                  SizedBox(
                    height: (MediaQuery.of(context).size.height * 0.32).clamp(180.0, 240.0),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredRestaurants.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final restaurant = filteredRestaurants[index];
                        final isFav = favorites.contains(restaurant.id);
                        return Semantics(
                          label: '${restaurant.name}, ${restaurant.tags.join(', ')}, rating ${restaurant.rating}, delivery time ${restaurant.deliveryTime}, ${restaurant.deliveryFee == 'Free' ? 'free delivery' : restaurant.deliveryFee + ' delivery fee'}, ${restaurant.distance}',
                          child: GestureDetector(
                            onTap: () =>
                                context.push('/restaurant/${restaurant.id}'),
                            child: Container(
                            width: 256,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image
                                Container(
                                  height: (MediaQuery.of(context).size.height * 0.19).clamp(100.0, 140.0),
                                  clipBehavior: Clip.antiAlias,
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(24)),
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: AppImage(
                                          url: restaurant.imageUrl,
                                          fit: BoxFit.cover,
                                          fallbackSeed: restaurant.name,
                                        ),
                                      ),
                                      // Heart
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: GestureDetector(
                                          onTap: () => ref.read(favoritesProvider.notifier).toggle(restaurant.id),
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.9),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.favorite,
                                              size: 16,
                                              color: isFav
                                                  ? Colors.red
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Rating
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            borderRadius:
                                                BorderRadius.circular(99),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                size: 12,
                                                color: AppColors.accent,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${restaurant.rating}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Delivery time
                                      Positioned(
                                        bottom: 12,
                                        left: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.9),
                                            borderRadius:
                                                BorderRadius.circular(99),
                                          ),
                                          child: Text(
                                            restaurant.deliveryTime,
                                            style: GoogleFonts.inter(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Info
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        restaurant.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        restaurant.tags.join(' • '),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: const Color(0xFF3C4A42)
                                              .withOpacity(0.6),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            restaurant.deliveryFee == 'Free'
                                                ? 'Free delivery'
                                                : '${restaurant.deliveryFee} delivery',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '•',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: Colors.grey[300],
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            restaurant.distance,
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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
