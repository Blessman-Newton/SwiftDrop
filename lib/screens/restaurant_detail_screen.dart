import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
// lucide_icons removed - using Material Icons
import '../providers/providers.dart';
import '../data/restaurants.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_image.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen> {
  String _selectedCategory = 'Popular';
  bool _showCheckout = false;
  String _promoCodeInput = '';
  String _appliedPromoCode = '';
  double _promoDiscount = 0;
  bool _promoApplied = false;
  String? _promoError;
  String? _promoSuccessMessage;
  String? _addedAnimationId;
  _CartFeedback? _lastCartFeedback;

  static const _promoCodes = <String, Map<String, dynamic>>{
    'SWIFT15': {'type': 'percentage', 'value': 0.15, 'desc': '15% Off Your Entire Order'},
    'WELCOME10': {'type': 'percentage', 'value': 0.10, 'desc': '10% Welcome Discount'},
    'FREE5': {'type': 'flat', 'value': 5.0, 'desc': '\$5.00 Flat Off'},
    'HALFPRICE': {'type': 'percentage', 'value': 0.50, 'desc': 'Special 50% Megadeal Off'},
  };

  Restaurant get _restaurant =>
      restaurants.firstWhere((r) => r.id == widget.restaurantId);

  List<FoodItem> get _menuItems {
    if (_selectedCategory == 'Popular') {
      return _restaurant.menu
          .where((item) => item.category == FoodCategory.popular)
          .toList();
    }
    return _restaurant.menu
        .where((item) =>
            item.category.name.toLowerCase() ==
            _selectedCategory.toLowerCase())
        .toList();
  }

  List<String> get _categories {
    final cats = _restaurant.menu.map((e) => e.category.name).toSet().toList();
    cats.insert(0, 'Popular');
    return cats;
  }

  int _getQty(String foodItemId) {
    final cart = ref.read(cartProvider);
    return cart
        .where((ci) => ci.foodItem.id == foodItemId)
        .fold(0, (s, ci) => s + ci.quantity);
  }

  double get _totalCartPrice {
    final cart = ref.read(cartProvider);
    return cart.fold(0, (acc, c) => acc + (c.foodItem.price * c.quantity));
  }

  int get _totalCartCount {
    final cart = ref.read(cartProvider);
    return cart.fold<int>(0, (sum, c) => sum + c.quantity);
  }

  double get _parsedDeliveryFee {
    if (_restaurant.deliveryFee.toLowerCase() == 'free') return 0;
    return double.tryParse(
            _restaurant.deliveryFee.replaceAll(r'$', '')) ??
        0;
  }

  void _applyPromo(String code) {
    final upper = code.trim().toUpperCase();
    if (upper.isEmpty) {
      setState(() {
        _promoError = 'Please enter a promo code';
        _promoSuccessMessage = null;
      });
      return;
    }
    final promo = _promoCodes[upper];
    if (promo != null) {
      final type = promo['type'] as String;
      final value = promo['value'] as double;
      final desc = promo['desc'] as String;
      double discount;
      if (type == 'percentage') {
        discount = _totalCartPrice * value;
      } else {
        discount = _totalCartPrice < value ? _totalCartPrice : value;
      }
      setState(() {
        _appliedPromoCode = upper;
        _promoApplied = true;
        _promoDiscount = discount;
        _promoError = null;
        _promoSuccessMessage =
            'Promo code "$upper" applied successfully! ($desc)';
      });
    } else {
      setState(() {
        _appliedPromoCode = '';
        _promoApplied = false;
        _promoDiscount = 0;
        _promoError =
            'Invalid code. Try SWIFT15, WELCOME10, FREE5, or HALFPRICE';
        _promoSuccessMessage = null;
      });
    }
  }

  void _removePromo() {
    setState(() {
      _appliedPromoCode = '';
      _promoApplied = false;
      _promoDiscount = 0;
      _promoCodeInput = '';
      _promoError = null;
      _promoSuccessMessage = null;
    });
  }

  void _handleAddWithFeedback(FoodItem item) {
    ref.read(cartProvider.notifier).addItem(item);
    setState(() {
      _addedAnimationId = item.id;
      _lastCartFeedback = _CartFeedback(itemName: item.name, action: 'added', visible: true);
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _addedAnimationId = null);
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _lastCartFeedback = _lastCartFeedback?.copyWith(visible: false);
        });
      }
    });
  }

  void _handleRemoveWithFeedback(FoodItem item) {
    ref.read(cartProvider.notifier).removeItem(item.id);
    setState(() {
      _lastCartFeedback = _CartFeedback(itemName: item.name, action: 'removed', visible: true);
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _lastCartFeedback = _lastCartFeedback?.copyWith(visible: false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final favorites = ref.watch(favoritesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartCount = cartNotifier.itemCount;
    final subtotal = cartNotifier.subtotal;
    final autoDiscount = subtotal >= 30 ? subtotal * 0.15 : 0.0;

    double promoDiscount = 0;
    if (_promoApplied) {
      final promo = _promoCodes[_appliedPromoCode];
      if (promo != null) {
        final type = promo['type'] as String;
        final value = promo['value'] as double;
        if (type == 'percentage') {
          promoDiscount = subtotal * value;
        } else {
          promoDiscount = subtotal < value ? subtotal : value;
        }
      }
    }

    final finalTotal = (subtotal - autoDiscount - promoDiscount + _parsedDeliveryFee).clamp(0.0, double.infinity);

    final deliveryFeeDisplay = _restaurant.deliveryFee.toLowerCase() == 'free'
        ? 'Free'
        : '\$${_parsedDeliveryFee.toStringAsFixed(2)}';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            slivers: [
              // 1. HERO IMAGE
              SliverToBoxAdapter(
                child: SizedBox(
                  height: (MediaQuery.of(context).size.height * 0.3).clamp(180.0, 280.0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(
                        url: _restaurant.imageUrl,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                            stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                                      ),
                      // Top navigation buttons
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Semantics(
                              label: 'Go back',
                              child: _HeroButton(
                                icon: Icons.arrow_back,
                                onTap: () => context.go('/food-delivery'),
                                isDark: isDark,
                              ),
                            ),
                            Row(
                              children: [
                                Semantics(
                                  label: 'Share',
                                  child: _HeroButton(
                                    icon: Icons.share,
                                    onTap: () {},
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Semantics(
                                  label: '${favorites.contains(_restaurant.id) ? 'Remove from' : 'Add to'} favorites',
                                  child: _HeroButton(
                                    icon: Icons.favorite,
                                    onTap: () => ref
                                        .read(favoritesProvider.notifier)
                                        .toggle(_restaurant.id),
                                    isDark: isDark,
                                    iconColor: favorites.contains(_restaurant.id)
                                        ? Colors.red
                                        : (isDark ? Colors.white : const Color(0xFF2D3748)),
                                    iconFill: favorites.contains(_restaurant.id),
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

              // 2. INFO FLOATING BOX
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF18233c) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFF1F5F9),
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _restaurant.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : const Color(0xFF1A202C),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: _restaurant.tags.map((tag) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.grey.shade800
                                                : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            tag,
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.6)
                                                  : const Color(0xFF3c4a42).withValues(alpha: 0.8),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star,
                                        size: 14,
                                        color: Color(0xFFFF7E2D)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_restaurant.rating}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF1A202C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 1,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: isDark
                                      ? Colors.grey.shade800.withValues(alpha: 0.6)
                                      : const Color(0xFFF1F5F9),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _InfoStat(
                                  icon: Icons.access_time,
                                  text: _restaurant.deliveryTime,
                                  isDark: isDark,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: isDark
                                          ? Colors.grey.shade800.withValues(alpha: 0.6)
                                          : const Color(0xFFF1F5F9),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _InfoStat(
                                  icon: Icons.delivery_dining,
                                  text: _restaurant.deliveryFee,
                                  isDark: isDark,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: isDark
                                          ? Colors.grey.shade800.withValues(alpha: 0.6)
                                          : const Color(0xFFF1F5F9),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _InfoStat(
                                  icon: Icons.location_on,
                                  text: _restaurant.distance,
                                  isDark: isDark,
                                ),
                            ),
                          ],
                         ),
                        ],
                      ),
                    ),
                      ),
                                      ),
              ),

              // 3. PROMO BANNER
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF9D4300).withValues(alpha: 0.2)
                          : const Color(0xFFFFDBCA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.percent,
                            size: 20, color: Color(0xFFFF7E2D)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '15% off orders over \$30',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? const Color(0xFFFFDBCA)
                                      : const Color(0xFF783200),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Discount applied automatically at checkout',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: (isDark
                                          ? const Color(0xFFFFDBCA)
                                          : const Color(0xFF783200))
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. STICKY CATEGORY TABS
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoryTabDelegate(
                  categories: _categories,
                  selected: _selectedCategory,
                  onSelect: (c) => setState(() => _selectedCategory = c),
                  isDark: isDark,
                ),
              ),

              // 5. MENU ITEMS
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Text(
                    '$_selectedCategory Items',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF161D19),
                    ),
                  ),
                ),
              ),
              if (_menuItems.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No items listed in $_selectedCategory category. Try switching tabs!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final item = _menuItems[i];
                        final qty = _getQty(item.id);
                        final animateCheck = _addedAnimationId == item.id;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF18233c) : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left: name, description, price
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF1A202C),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.4)
                                              : const Color(0xFF3c4a42).withValues(alpha: 0.7),
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '\$${item.price.toStringAsFixed(2)}',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: isDark
                                                  ? const Color(0xFF6FFBBE)
                                                  : AppColors.primary,
                                            ),
                                          ),
                                          // Cart controls
                                           if (qty > 0)
                                             Semantics(
                                               label: '${item.name}, quantity $qty, adjust quantity',
                                               child: Container(
                                                 decoration: BoxDecoration(
                                                   color: isDark
                                                       ? AppColors.primaryLight
                                                       : AppColors.primary,
                                                   borderRadius:
                                                       BorderRadius.circular(24),
                                                   boxShadow: [
                                                     BoxShadow(
                                                       color: const Color(0xFF10B981)
                                                           .withValues(alpha: 0.1),
                                                       blurRadius: 6,
                                                       offset: const Offset(0, 4),
                                                     ),
                                                   ],
                                                 ),
                                                 padding: const EdgeInsets.all(4),
                                                 child: Row(
                                                   mainAxisSize: MainAxisSize.min,
                                                   children: [
                                                     _CartQtyButton(
                                                       icon: Icons.remove,
                                                       onTap: () => _handleRemoveWithFeedback(item),
                                                     ),
                                                     SizedBox(
                                                       width: 16,
                                                       child: Text(
                                                         '$qty',
                                                         textAlign: TextAlign.center,
                                                         style: GoogleFonts.inter(
                                                           fontSize: 12,
                                                           fontWeight: FontWeight.w700,
                                color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                      _CartQtyButton(
                                                       icon: Icons.add,
                                                       onTap: () => _handleAddWithFeedback(item),
                                                     ),
                                                   ],
                                                 ),
                                               ),
                                             )
                                           else
                                             Semantics(
                                               label: 'Add ${item.name} to cart',
                                               child: GestureDetector(
                                                 onTap: () => _handleAddWithFeedback(item),
                                                 child: AnimatedContainer(
                                                   duration: const Duration(milliseconds: 300),
                                                   width: 32,
                                                   height: 32,
                                                   decoration: BoxDecoration(
                                                     color: animateCheck
                                                         ? const Color(0xFF059669)
                                                         : AppColors.primaryLight
                                                             .withValues(alpha: 0.15),
                                                     shape: BoxShape.circle,
                                                     boxShadow: [
                                                       BoxShadow(
                                                         color: Colors.black
                                                             .withValues(alpha: 0.1),
                                                         blurRadius: 6,
                                                         offset: const Offset(0, 2),
                                                       ),
                                                     ],
                                                   ),
                                                   child: Icon(
                                                     animateCheck
                                                         ? Icons.check
                                                         : Icons.add,
                                                     size: 16,
                                                     color: animateCheck
                                                         ? Colors.white
                                                         : (isDark
                                                             ? const Color(0xFF6FFBBE)
                                                              : AppColors.primary),
                            ),
                           ),
                         ),
                       ),
                     ],
                                     ),
                                     ],
                                   ),
                                   ),
                                   const SizedBox(width: 16),
                                // Right: image
                                AppImage(
                                  url: item.imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _menuItems.length,
                    ),
                  ),
                ),

              // 6. SPACER for floating cart
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // 8. CART FEEDBACK TOAST
          if (_lastCartFeedback != null && _lastCartFeedback!.visible)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedSlide(
                  offset: _lastCartFeedback!.visible ? Offset.zero : const Offset(0, 1),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: _lastCartFeedback!.visible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _lastCartFeedback!.action == 'added'
                            ? const Color(0xFF10B981)
                            : const Color(0xFFBA1A1A),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (_lastCartFeedback!.action == 'added'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFBA1A1A))
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _lastCartFeedback!.action == 'added'
                                ? Icons.add_circle_outline
                                : Icons.remove_circle_outline,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_lastCartFeedback!.action == 'added' ? 'Added' : 'Removed'}: ${_lastCartFeedback!.itemName}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                               color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                ),
              ),
            ),

          // 6. FLOATING CART BUTTON
          if (cartCount > 0 && !_showCheckout)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      isDark ? AppColors.darkBackground : Colors.white,
                      (isDark ? AppColors.darkBackground : Colors.white)
                          .withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Semantics(
                  label: 'View cart, $cartCount item${cartCount > 1 ? 's' : ''} from ${_restaurant.name}, total \$${subtotal.toStringAsFixed(2)}',
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => _showCheckout = true),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.shopping_bag,
                                  size: 20, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'View Cart',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$cartCount item${cartCount > 1 ? 's' : ''} • ${_restaurant.name}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '\$${subtotal.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ),
            ),

          // 7. CHECKOUT DRAWER OVERLAY
          if (_showCheckout) ...[
            GestureDetector(
              onTap: () => setState(() => _showCheckout = false),
              child: Container(
                color: const Color(0xFF0F172A).withValues(alpha: 0.6),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18233c) : Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(36)),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF1F5F9),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 32,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drawer Handle
                      Container(
                        width: 48,
                        height: 6,
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade700.withValues(alpha: 0.6)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),

                      // Drawer Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.primaryLight.withValues(alpha: 0.1)
                                        : const Color(0xFFECFDF5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.shopping_bag,
                                      size: 16,
                                      color: isDark
                                          ? AppColors.primaryLight
                                          : AppColors.primary),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Review Your Cart',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : const Color(0xFF1A202C),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _restaurant.name.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade400,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _showCheckout = false),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade100,
                                ),
                                child: Icon(Icons.close,
                                    size: 20,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade500),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Scrollable body
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Items header
                              Text(
                                'ITEMS (${_totalCartCount})',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey.shade400,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Cart items list
                              ...cart.map((ci) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF131B2E).withValues(alpha: 0.3)
                                        : const Color(0xFFF8FAFC).withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : const Color(0xFFF1F5F9),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      AppImage(
                                        url: ci.foodItem.imageUrl,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ci.foodItem.name,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1A202C),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '\$${ci.foodItem.price.toStringAsFixed(2)} each',
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: Colors.grey.shade400,
                                              ),
                                            ),
                                          ],
                                        ),
                                        child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF18233c)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.grey.shade800
                                                : const Color(0xFFF1F5F9),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: () =>
                                                  _handleRemoveWithFeedback(ci.foodItem),
                                              child: Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isDark
                                                      ? Colors.grey.shade800
                                                      : Colors.grey.shade100,
                                                ),
                                                child: Icon(Icons.remove,
                                                    size: 12,
                                                    color: isDark
                                                        ? Colors.grey.shade400
                                                        : Colors.grey.shade600),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8),
                                              child: Text(
                                                '${ci.quantity}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF374151),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () =>
                                                  _handleAddWithFeedback(ci.foodItem),
                                              child: Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isDark
                                                      ? Colors.grey.shade800
                                                      : Colors.grey.shade100,
                                                ),
                                                child: Icon(Icons.add,
                                                    size: 12,
                                                    color: isDark
                                                        ? Colors.grey.shade400
                                                        : Colors.grey.shade600),
                                              ),
                                            ),
                                          ],
                                ),
                              ),
                              const SizedBox(width: 12),
                                      SizedBox(
                                        width: 56,
                                        child: Text(
                                          '\$${ci.totalPrice.toStringAsFixed(2)}',
                                          textAlign: TextAlign.end,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1A202C),
                                          ),
                                        ),
                                       ),
                                     ),
                                   ],
                                 ),
                               )),

                              const SizedBox(height: 20),

                              // Promo Code section
                              Row(
                                children: [
                                  Icon(Icons.local_offer,
                                      size: 16,
                                      color: AppColors.primaryLight),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Promo Code',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : const Color(0xFF374151),
                                            ),
                            ),
                               ],
                               ),
                               const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: TextEditingController(
                                          text: _promoCodeInput),
                                      onChanged: (v) {
                                        setState(() {
                                          _promoCodeInput = v;
                                          if (_promoError != null) _promoError = null;
                                        });
                                      },
                                      enabled: !_promoApplied,
                                      decoration: InputDecoration(
                                        hintText: 'Enter Promo Code (e.g., SWIFT15)',
                                        hintStyle: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.grey.shade400),
                                        suffixIcon: _promoApplied
                                            ? const Icon(Icons.check,
                                                size: 16,
                                                color: Color(0xFF10B981))
                                            : null,
                                        filled: true,
                                        fillColor: isDark
                                            ? Colors.grey.shade900
                                                .withValues(alpha: 0.6)
                                            : const Color(0xFFF8FAFC)
                                                .withValues(alpha: 0.55),
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? Colors.grey.shade800
                                                : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? Colors.grey.shade800
                                                : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                              color: AppColors.primaryLight),
                                        ),
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1,
                                        color: isDark ? Colors.grey.shade100 : const Color(0xFF1A202C),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                   if (_promoApplied)
                                     Semantics(
                                       label: 'Remove promo code',
                                       child: GestureDetector(
                                         onTap: _removePromo,
                                         child: Container(
                                           padding: const EdgeInsets.symmetric(
                                               horizontal: 16, vertical: 12),
                                           decoration: BoxDecoration(
                                             color: isDark
                                                 ? Colors.red.shade500.withValues(alpha: 0.1)
                                                 : Colors.red.shade100,
                                             borderRadius: BorderRadius.circular(16),
                                           ),
                                           child: Text(
                                             'Remove',
                                             style: GoogleFonts.inter(
                                               fontSize: 12,
                                               fontWeight: FontWeight.w900,
                                               color: isDark
                                                   ? Colors.red.shade400
                                                   : Colors.red.shade600,
                                             ),
                                           ),
                                         ),
                                       ),
                                     )
                                   else
                                     Semantics(
                                       label: 'Apply promo code',
                                       child: GestureDetector(
                                         onTap: () => _applyPromo(_promoCodeInput),
                                         child: Container(
                                           padding: const EdgeInsets.symmetric(
                                               horizontal: 20, vertical: 12),
                                           decoration: BoxDecoration(
                                             color: AppColors.primaryLight,
                                             borderRadius: BorderRadius.circular(16),
                                             boxShadow: [
                                               BoxShadow(
                                                 color: AppColors.primaryLight
                                                     .withValues(alpha: 0.1),
                                                 blurRadius: 4,
                                               ),
                                             ],
                                           ),
                                           child: Text(
                                             'Apply',
                                             style: GoogleFonts.inter(
                                               fontSize: 12,
                                               fontWeight: FontWeight.w900,
                                               color: Colors.white,
                                             ),
                                           ),
                                           ),
                             ),
                                ),

                               // Promo feedback
                              if (_promoError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _promoError!,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.red.shade500,
                                    ),
                                  ),
                                ),
                              if (_promoSuccessMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.auto_awesome,
                                          size: 14,
                                          color: AppColors.primaryLight),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _promoSuccessMessage!,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? AppColors.primaryLight
                                                : const Color(0xFF059669),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Promo suggestion chips
                              if (!_promoApplied) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'CLICK TO TEST AVAILABLE CODES:',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey.shade400,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: _promoCodes.entries.map((e) {
                                    final code = e.key;
                                    final promo = e.value;
                                    final type = promo['type'] as String;
                                    final value = promo['value'] as double;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() => _promoCodeInput = code);
                                        _applyPromo(code);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.grey.shade800.withValues(alpha: 0.8)
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.grey.shade800
                                                : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Text(
                                          '$code (${type == 'percentage' ? '${(value * 100).toInt()}%' : '\$${value.toStringAsFixed(0)}'})',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.8,
                                            color: isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],

                              const SizedBox(height: 20),
                              Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: isDark
                                          ? Colors.grey.shade800.withValues(alpha: 0.6)
                                          : const Color(0xFFF1F5F9),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Pricing Summary
                              _CheckoutPriceRow(
                                label: 'Subtotal',
                                value: '\$${subtotal.toStringAsFixed(2)}',
                                isDark: isDark,
                              ),
                              if (autoDiscount > 0)
                                _CheckoutPriceRow(
                                  label: 'Auto 15% Off (Subtotal >= \$30)',
                                  value: '-\$${autoDiscount.toStringAsFixed(2)}',
                                  color: const Color(0xFF059669),
                                  icon: Icons.percent,
                                  isDark: isDark,
                                ),
                              if (_promoApplied && promoDiscount > 0)
                                _CheckoutPriceRow(
                                  label: 'Promo Code ($_appliedPromoCode)',
                                  value: '-\$${promoDiscount.toStringAsFixed(2)}',
                                  color: const Color(0xFF059669),
                                  icon: Icons.label,
                                  isDark: isDark,
                                ),
                              _CheckoutPriceRow(
                                label: 'Delivery Fee',
                                value: deliveryFeeDisplay,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: isDark
                                          ? Colors.grey.shade800
                                          : const Color(0xFFE2E8F0),
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Amount',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : const Color(0xFF1A202C),
                                      ),
                                    ),
                                    Text(
                                      '\$${finalTotal.toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? const Color(0xFF6FFBBE)
                                            : const Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Footer buttons
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF131B2E).withValues(alpha: 0.3)
                              : const Color(0xFFF8FAFC).withValues(alpha: 0.5),
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade800.withValues(alpha: 0.6)
                                  : const Color(0xFFF1F5F9),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                label: 'Keep browsing',
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _showCheckout = false),
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Keep Browsing',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? Colors.grey.shade200
                                            : const Color(0xFF374151),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Semantics(
                                label: 'Place order for \$${finalTotal.toStringAsFixed(2)}',
                                child: GestureDetector(
                                onTap: () {
                                  ref.read(ordersProvider.notifier).placeOrder(
                                        _restaurant.id,
                                        _restaurant.name,
                                        cart,
                                        finalTotal,
                                      );
                                  ref.read(cartProvider.notifier).clearCart();
                                  setState(() => _showCheckout = false);
                                  context.go('/map');
                                },
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primary,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF059669)
                                            .withValues(alpha: 0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.shopping_bag,
                                          size: 16, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Place Order • \$${finalTotal.toStringAsFixed(2)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                               ),
                             ),
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
        ),
      ),
        ),
      ],
    ],
  ),
 );
  }
}

class _HeroButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final Color? iconColor;
  final bool iconFill;

  const _HeroButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.iconColor,
    this.iconFill = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0F172A).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 16,
          color: iconColor ??
              (isDark ? Colors.white : const Color(0xFF2D3748)),
          fill: iconFill ? 1.0 : 0.0,
        ),
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _InfoStat({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon,
            size: 16,
            color: isDark ? const Color(0xFF6FFBBE) : AppColors.primary),
        const SizedBox(height: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : const Color(0xFF3c4a42).withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _CartQtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CartQtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}

class _CheckoutPriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final IconData? icon;
  final bool isDark;

  const _CheckoutPriceRow({
    required this.label,
    required this.value,
    this.color,
    this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color ?? Colors.grey.shade600),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color ?? Colors.grey.shade600,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color ??
                  (isDark ? Colors.white : const Color(0xFF1A202C)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTabDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;
  final bool isDark;

  _CategoryTabDelegate({
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.isDark,
  });

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark
          ? const Color(0xFF131B2E).withValues(alpha: 0.8)
          : const Color(0xFFF4FBF4).withValues(alpha: 0.8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isActive = cat == selected;
          return Semantics(
            label: '$cat category${isActive ? ', selected' : ''}',
            child: GestureDetector(
              onTap: () => onSelect(cat),
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? (isDark ? AppColors.primaryLight : AppColors.primary)
                    : (isDark ? const Color(0xFF18233c) : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(24),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? Colors.white
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                ),
              ),
            ),
          ),
          );
          },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryTabDelegate old) =>
      old.selected != selected || old.isDark != isDark;
}

class _CartFeedback {
  final String itemName;
  final String action;
  final bool visible;

  const _CartFeedback({
    required this.itemName,
    required this.action,
    required this.visible,
  });

  _CartFeedback copyWith({bool? visible}) {
    return _CartFeedback(
      itemName: itemName,
      action: action,
      visible: visible ?? this.visible,
    );
  }
}
