import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../providers/restaurant_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_image.dart';
import '../widgets/food_detail_sheet.dart';

class FoodDeliveryScreen extends ConsumerStatefulWidget {
  const FoodDeliveryScreen({super.key});

  @override
  ConsumerState<FoodDeliveryScreen> createState() =>
      _FoodDeliveryScreenState();
}

class _FoodDeliveryScreenState extends ConsumerState<FoodDeliveryScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

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
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final restaurants = restaurantsAsync.value ?? [];

    final filteredRestaurants = restaurants.where((r) {
      final matchesSearch = r.name.toLowerCase().contains(searchQuery) ||
          r.tags
              .any((t) => t.toLowerCase().contains(searchQuery));
      final matchesCategory = _selectedCategory == 'All' ||
          r.tags
              .any((t) => t.toLowerCase() == _selectedCategory.toLowerCase());
      return matchesSearch && matchesCategory;
    }).toList();

    const categories = [
      'All',
      'Local',
      'Jollof',
      'Grill',
      'Fast Food',
      'Pizza',
      'Healthy',
      'Continental',
    ];

    return SafeArea(
      child: Container(
      height: double.infinity,
      color: AppColors.background(isDark),
      child: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            // Header
            Container(
              color: isDark
                  ? AppColors.darkBackground.withOpacity(0.8)
                  : Colors.white.withOpacity(0.8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Semantics(
                        label: 'Go back',
                        child: GestureDetector(
                          onTap: () => context.pop(),
                          child: const Icon(Icons.arrow_back,
                              color: AppColors.primary, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Food Delivery',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.tune,
                          color: Colors.grey, size: 18),
                      const SizedBox(width: 12),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryLight,
                            width: 1,
                          ),
                        ),
                        child: ClipOval(
                          child: AppImage(
                            url: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCa0wEAA2MJgGoOs4FJq2TrfbpALLldPBRttiucQHGSfiHmNc_LtUpt79HbwLmU2LEsXaaQoa6vJASaOKlXPRSyIxPpXkrMUw1UQhJMonTc2GR2FgI6S_kz-pHXkvv0EVYXKB6waNwa3zx9H_3nl062qaKpx9EdouXfAEe8_Ro7Zd6wA2I9Y_ILsGwFzWbITxaTeorZwc9mLQ0p86-S113bHO3gyD2mNjkbZouGTYSLjR0Ef-UTIEYRHDfbQ_I_UuxoaiN7Ix0HLoc',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
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

                  // Search bar
                  Semantics(
                    label: 'Search for restaurants or dishes',
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F1),
                        borderRadius: BorderRadius.circular(16),
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
                            decoration: InputDecoration(
                              hintText:
                                  'Search for restaurants or dishes',
                              hintStyle: GoogleFonts.inter(
                                  color: Colors.grey[400], fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category chips
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isActive = _selectedCategory == cat;
                        return Semantics(
                          label: '$cat category${isActive ? ', selected' : ''}',
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary
                                  : const Color(0xFFF1F5F1),
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              cat,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? Colors.white
                                    : const Color(0xFF3C4A42)
                                        .withOpacity(0.8),
                              ),
                            ),
                          ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Promo sliders
                  SizedBox(
                    height: (MediaQuery.of(context).size.height * 0.2).clamp(100.0, 144.0),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Promo 1
                        Semantics(
                          label: 'Promotion: Free delivery at The Pizza Place, order above GHS 25',
                          child: Container(
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'PROMOTION',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Free delivery at The Pizza Place',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Order above GHS 25',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: Colors.white
                                              .withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Claim Offer',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                right: -24,
                                bottom: -24,
                                child: Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ),
                        ),

                        // Promo 2
                        Semantics(
                          label: 'Promotion: 50% Off Sushi Zen, valid for new users only',
                          child: Container(
                            width: 280,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xFF9D4300),
                                Color(0xFFFF7E2D),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9D4300)
                                    .withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'LIMITED TIME',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '50% Off Sushi Zen',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Valid for New Users only',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: Colors.white
                                              .withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Redeem Now',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF9D4300),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                right: -24,
                                bottom: -24,
                                child: Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Restaurant rails
                  _buildRail(
                      'Popular Restaurants', _popular(restaurants), isDark),
                  ref.watch(recommendedFoodProvider).when(
                        data: (foods) => _buildRecommendedFoodSection(foods.take(6).toList(), isDark),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, stack) => const SizedBox.shrink(),
                      ),
                  _buildMenuOptions(isDark),

                  // All Restaurants heading
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Restaurants',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(isDark),
                        ),
                      ),
                      Semantics(
                        label: 'See map',
                        child: GestureDetector(
                          onTap: () => context.push('/map'),
                          child: Row(
                            children: [
                              Text(
                                'See map',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.map,
                                size: 14, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Restaurant grid
                  if (filteredRestaurants.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No restaurants found',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try adjusting your search or filters',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: filteredRestaurants
                          .map((restaurant) => _buildRestaurantGridCard(
                                restaurant,
                                favorites.contains(restaurant.id),
                                isDark,
                              ))
                          .toList(),
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

  /// Restaurant grid card (QuickBite layout, SwiftDrop green palette):
  /// image with heart, a bottom overlay showing delivery time + fee and a
  /// rating pill, then name + cuisine below.
  Widget _buildRestaurantGridCard(
      Restaurant restaurant, bool isFav, bool isDark) {
    final cardWidth = (MediaQuery.of(context).size.width - 56) / 2;
    final fee = restaurant.deliveryFee.isEmpty ? 'Free' : restaurant.deliveryFee;
    final time = restaurant.deliveryTime.isEmpty
        ? '20-30 min'
        : restaurant.deliveryTime;

    return GestureDetector(
      onTap: () => context.push('/restaurant/${restaurant.id}'),
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 156 / 192,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(
                      url: restaurant.imageUrl,
                      fit: BoxFit.cover,
                      fallbackSeed: restaurant.name,
                    ),
                    // Heart
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => ref
                            .read(favoritesProvider.notifier)
                            .toggle(restaurant.id),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 22,
                          color: isFav ? Colors.red : Colors.white,
                          shadows: const [
                            Shadow(
                                blurRadius: 4,
                                color: Color.fromRGBO(0, 0, 0, 0.4)),
                          ],
                        ),
                      ),
                    ),
                    // Bottom overlay: delivery info + rating
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x00000000),
                              Color(0x99000000),
                            ],
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _overlayInfo(Icons.schedule, time,
                                      FontWeight.w600),
                                  const SizedBox(height: 2),
                                  _overlayInfo(Icons.pedal_bike, fee,
                                      FontWeight.w500),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star,
                                      size: 12, color: Color(0xFFFFCB11)),
                                  const SizedBox(width: 3),
                                  Text(
                                    restaurant.rating.toStringAsFixed(1),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              restaurant.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color: AppColors.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              restaurant.tags.take(2).join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color: const Color(0xFF868686),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlayInfo(IconData icon, String text, FontWeight weight) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: weight,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  List<Restaurant> _popular(List<Restaurant> all) {
    final flagged = all.where((r) => r.isPopular).toList();
    return flagged.isNotEmpty ? flagged : all.take(8).toList();
  }

  List<Restaurant> _mostPopular(List<Restaurant> all) {
    final sorted = [...all]..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(8).toList();
  }

  // ── Horizontal restaurant rail (Popular / Recommended / Most Popular) ──
  Widget _buildRail(String title, List<Restaurant> items, bool isDark) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _buildRailCard(items[i], isDark),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRailCard(Restaurant restaurant, bool isDark) {
    final fee = restaurant.deliveryFee.isEmpty ? 'Free' : restaurant.deliveryFee;
    final time =
        restaurant.deliveryTime.isEmpty ? '20-30 min' : restaurant.deliveryTime;
    return GestureDetector(
      onTap: () => context.push('/restaurant/${restaurant.id}'),
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 11,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(
                      url: restaurant.imageUrl,
                      fit: BoxFit.cover,
                      fallbackSeed: restaurant.name,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 11, color: Color(0xFFFFCB11)),
                            const SizedBox(width: 2),
                            Text(
                              restaurant.rating.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              restaurant.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$time • $fee',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF868686)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Menu Options (food categories) ──
  Widget _buildMenuOptions(bool isDark) {
    const opts = [
      {'label': 'Jollof', 'seed': 'Jollof Rice'},
      {'label': 'Grills', 'seed': 'Chicken'},
      {'label': 'Local', 'seed': 'Banku'},
      {'label': 'Rice', 'seed': 'Fried Rice'},
      {'label': 'Fast Food', 'seed': 'Burger'},
      {'label': 'Pasta', 'seed': 'Spaghetti'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu Options',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: opts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, i) {
              final o = opts[i];
              return Column(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: AppImage(
                        url: '',
                        fit: BoxFit.cover,
                        fallbackSeed: o['seed'],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    o['label']!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(isDark),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRecommendedFoodSection(List<Map<String, dynamic>> items, bool isDark) {
    if (items.isEmpty) return const SizedBox.shrink();
    final cardWidth = (MediaQuery.of(context).size.width - 52) / 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended for you',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((data) {
            final FoodItem item = data['foodItem'] as FoodItem;
            final Restaurant restaurant = data['restaurant'] as Restaurant;

            return GestureDetector(
              onTap: () {
                showFoodDetailSheet(
                  context: context,
                  ref: ref,
                  item: item,
                  restaurant: restaurant,
                  onFeedback: (msg) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                );
              },
              child: Container(
                width: cardWidth,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 11,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: AppImage(
                          url: item.imageUrl,
                          fit: BoxFit.cover,
                          fallbackSeed: item.name,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF161D19),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            restaurant.name,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'GHS ${item.price.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 14,
                                  color: Color(0xFF00422B),
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
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
