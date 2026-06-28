import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../data/restaurants.dart';
import '../theme/app_theme.dart';
import '../widgets/app_image.dart';

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
    final favorites = ref.watch(favoritesProvider);
    final searchQuery = _searchController.text.toLowerCase();

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
      'Burgers',
      'Sushi',
      'Pizza',
      'Healthy',
      'Desserts'
    ];

    return Container(
      height: double.infinity,
      color: const Color(0xFFF4FBF4),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white.withOpacity(0.8),
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
                          label: 'Promotion: Free delivery at The Pizza Place, order above twenty-five dollars',
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
                                        'Order above \$25',
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

                  // All Restaurants heading
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Restaurants',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
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
                  ...filteredRestaurants.map((restaurant) {
                    final isFav = favorites.contains(restaurant.id);
                    return Semantics(
                      label: '${restaurant.name}, ${restaurant.tags.join(', ')}, rating ${restaurant.rating}, delivery time ${restaurant.deliveryTime}',
                      child: GestureDetector(
                        onTap: () =>
                            context.push('/restaurant/${restaurant.id}'),
                        child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            Container(
                              height: (MediaQuery.of(context).size.height * 0.24).clamp(120.0, 176.0),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16)),
                                image: DecorationImage(
                                  image:
                                      NetworkImage(restaurant.imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Badges
                                  Positioned(
                                    top: 16,
                                    left: 16,
                                    child: Row(
                                      children: [
                                        if (restaurant.isPopular)
                                          _badge('Popular',
                                              AppColors.primary),
                                        if (restaurant.isNew)
                                          _badge('New', Colors.blue[600]!),
                                        if (restaurant.isTrending)
                                          _badge('Trending',
                                              const Color(0xFF9D4300)),
                                      ],
                                    ),
                                  ),
                                  // Heart
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withOpacity(0.8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.favorite,
                                        size: 16,
                                        color: isFav
                                            ? Colors.red
                                            : const Color(0xFF3C4A42)
                                                .withOpacity(0.8),
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
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          restaurant.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize:
                                              MainAxisSize.min,
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
                                                fontWeight:
                                                    FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    restaurant.tags.join(' \u2022 '),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF3C4A42)
                                          .withOpacity(0.6),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  // Bottom info
                                  Container(
                                    padding: const EdgeInsets.only(
                                        top: 12),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.grey[100]!,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            size: 14,
                                            color: Colors.grey[400]),
                                        const SizedBox(width: 4),
                                        Text(
                                          restaurant.deliveryTime,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(
                                                    0xFF3C4A42)
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.pedal_bike,
                                            size: 14,
                                            color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          restaurant.deliveryFee ==
                                                  'Free'
                                              ? 'Free delivery'
                                              : restaurant
                                                  .deliveryFee,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.w600,
                                            color:
                                                AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
