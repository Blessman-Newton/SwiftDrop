import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../providers/auth_provider.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/app_image.dart';
import '../services/order_service.dart';
import '../services/api_client.dart';
import 'checkout_screen.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final String restaurantId;

  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends ConsumerState<RestaurantDetailScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _heroAnimController;
  late Animation<double> _heroFade;
  late Animation<double> _heroSlide;

  String _selectedCategory = 'Popular';
  bool _showCheckout = false;
  bool _showCartFeedback = false;
  String _cartFeedbackMsg = '';
  String? _appliedPromo;
  String _selectedAddress = 'Home: 123 Oak Street';
  String _selectedPayment = 'Apple Pay •••• 9821';

  final List<String> _addresses = [
    'Home: 123 Oak Street',
    'Work: 456 Tech Park Drive',
    'Add new address',
  ];

  final List<String> _payments = [
    'Apple Pay •••• 9821',
    'Visa •••• 4532',
    'Add new payment',
  ];

  final Map<String, double> _promoDiscounts = {
    'SWIFT15': 0.15,
    'WELCOME10': 0.10,
    'FREE5': 5.0,
    'HALFPRICE': 0.50,
  };

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _heroAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heroFade = CurvedAnimation(parent: _heroAnimController, curve: Curves.easeOut);
    _heroSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _heroAnimController, curve: Curves.easeOutCubic),
    );
    _heroAnimController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _heroAnimController.dispose();
    super.dispose();
  }

  Restaurant get _restaurant => ref.read(restaurantDetailProvider(widget.restaurantId)).value!;

  List<FoodItem> get _filteredItems {
    final cat = _selectedCategory;
    final menu = _restaurant.menu;
    if (cat == 'Popular') {
      return menu.where((i) => i.category == FoodCategory.popular).toList();
    } else if (cat == 'Combos') {
      return menu.where((i) => i.category == FoodCategory.combos).toList();
    } else if (cat == 'Burgers') {
      return menu.where((i) => i.category == FoodCategory.burgers).toList();
    } else if (cat == 'Sides') {
      return menu.where((i) => i.category == FoodCategory.sides).toList();
    } else if (cat == 'Drinks') {
      return menu.where((i) => i.category == FoodCategory.drinks).toList();
    }
    return menu;
  }

  List<FoodItem> get _drinkItems {
    return _restaurant.menu.where((i) => i.category == FoodCategory.drinks).toList();
  }

  double _computeSubtotal(List<CartItem> cart) {
    return cart.fold(0.0, (sum, ci) => sum + ci.foodItem.price * ci.quantity);
  }

  double _applyPromo(double subtotal) {
    if (_appliedPromo == null) return 0;
    final disc = _promoDiscounts[_appliedPromo!];
    if (disc == null) return 0;
    if (_appliedPromo == 'FREE5') return disc;
    if (subtotal >= 30 || _appliedPromo == 'WELCOME10') {
      return subtotal * disc;
    }
    return 0;
  }

  int get _cartItemCount {
    return ref.read(cartProvider).fold(0, (sum, ci) => sum + ci.quantity);
  }

  void _showFeedback(String msg) {
    setState(() {
      _showCartFeedback = true;
      _cartFeedbackMsg = msg;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showCartFeedback = false);
    });
  }

  void _showOrderConfirmation(double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF6EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF006C49), size: 40),
            ),
            const SizedBox(height: 16),
            Text('Order Placed!', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Your order from ${_restaurant.name} for GHS ${total.toStringAsFixed(2)} has been confirmed.',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6C7A71)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/orders');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006C49),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Track Order', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Continue Shopping', style: GoogleFonts.inter(color: const Color(0xFF6C7A71))),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = ref.watch(cartProvider);
    final restaurantAsync = ref.watch(restaurantDetailProvider(widget.restaurantId));

    if (restaurantAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final restaurant = restaurantAsync.value;
    if (restaurant == null) {
      return Scaffold(
        body: Center(
          child: Text('Restaurant not found', style: GoogleFonts.inter()),
        ),
      );
    }

    final subtotal = _computeSubtotal(cart);
    final discount = _applyPromo(subtotal);
    final deliveryFee = restaurant.deliveryFee == 'Free' ? 0.0 : 2.99;
    final tax = (subtotal - discount) * 0.08;
    final total = (subtotal - discount) + deliveryFee + tax;

    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtextColor = isDark ? Colors.grey[400]! : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildHero(isDark),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -32),
                  child: _buildInfoCard(surfaceColor, textColor, subtextColor, cart),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoryTabDelegate(
                  selected: _selectedCategory,
                  onSelect: (cat) => setState(() => _selectedCategory = cat),
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                ),
              ),
              if (_selectedCategory != 'Drinks') ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _buildFoodCard(_filteredItems[i], surfaceColor, textColor, subtextColor),
                      childCount: _filteredItems.length,
                    ),
                  ),
                ),
              ],
              if (_drinkItems.isNotEmpty && _selectedCategory != 'Drinks') ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.local_bar_rounded, color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Craft Drinks',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.95,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _buildDrinkCard(_drinkItems[i], surfaceColor, textColor, subtextColor),
                      childCount: _drinkItems.length,
                    ),
                  ),
                ),
              ],
              if (_selectedCategory == 'Drinks') ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.95,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _buildDrinkCard(_filteredItems[i], surfaceColor, textColor, subtextColor),
                      childCount: _filteredItems.length,
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
          if (cart.isNotEmpty && !_showCheckout)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _buildFloatingCart(cart, total, surfaceColor, textColor),
            ),
          if (_showCheckout) _buildCheckoutOverlay(cart, subtotal, discount, deliveryFee, tax, total, surfaceColor, textColor, subtextColor),
          if (_showCartFeedback) _buildCartToast(surfaceColor, textColor),
        ],
      ),
    );
  }

  Widget _buildHero(bool isDark) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _heroFade,
        child: AnimatedBuilder(
          animation: _heroSlide,
          builder: (ctx, child) {
            return Transform.translate(
              offset: Offset(0, _heroSlide.value),
              child: child,
            );
          },
          child: Stack(
            children: [
              Container(
                height: 300,
                width: double.infinity,
                child: AppImage(
                  url: _restaurant.imageUrl,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color.fromRGBO(0, 0, 0, 0.2),
                        const Color.fromRGBO(0, 0, 0, 0.0),
                        const Color.fromRGBO(0, 0, 0, 0.0),
                        const Color.fromRGBO(0, 0, 0, 0.6),
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                child: _HeroButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: Row(
                  children: [
                    _HeroButton(icon: Icons.share_rounded, onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Shared ${_restaurant.name}', style: GoogleFonts.inter()),
                          backgroundColor: const Color(0xFF006C49),
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    _HeroButton(
                      icon: isDark ? Icons.star_rounded : Icons.star_border_rounded,
                      onTap: () => ref.read(favoritesProvider.notifier).toggle(widget.restaurantId),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 40,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _restaurant.name,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: const [
                          Shadow(blurRadius: 8, color: Color.fromRGBO(0, 0, 0, 0.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: _restaurant.tags.map((tag) {
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(255, 255, 255, 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(Color surface, Color text, Color subtext, List<CartItem> cart) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _restaurant.name,
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: text),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      _restaurant.rating.toString(),
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: _restaurant.tags.map((t) => Text(t, style: GoogleFonts.inter(fontSize: 12, color: subtext))).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoStat(icon: Icons.access_time_rounded, value: _restaurant.deliveryTime, color: AppColors.primary),
              const SizedBox(width: 16),
              _InfoStat(
                icon: Icons.delivery_dining_rounded,
                value: _restaurant.deliveryFee,
                color: _restaurant.deliveryFee == 'Free' ? AppColors.primary : AppColors.accent,
              ),
              const SizedBox(width: 16),
              _InfoStat(icon: Icons.place_outlined, value: _restaurant.distance, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 126, 45, 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer_rounded, color: AppColors.accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '15% off orders over GHS 30 with code SWIFT15',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(FoodItem item, Color surface, Color text, Color subtext) {
    final cart = ref.watch(cartProvider);
    final qtyInCart = cart.where((ci) => ci.foodItem.id == item.id).fold(0, (s, ci) => s + ci.quantity);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AppImage(url: item.imageUrl, fit: BoxFit.cover),
                ),
                if (qtyInCart > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$qtyInCart in cart',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Text(
                      item.description,
                      style: GoogleFonts.inter(fontSize: 11, color: subtext, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GHS ${item.price.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                      if (qtyInCart == 0)
                        GestureDetector(
                          onTap: () {
                            ref.read(cartProvider.notifier).addItem(item, restaurantId: widget.restaurantId);
                            _showFeedback('Added ${item.name}');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                          ),
                        )
                      else
                        _CartQtyButton(
                          qty: qtyInCart,
                          onAdd: () {
                            ref.read(cartProvider.notifier).addItem(item, restaurantId: widget.restaurantId);
                          },
                          onRemove: () {
                            ref.read(cartProvider.notifier).removeItem(item.id);
                          },
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
  }

  Widget _buildDrinkCard(FoodItem item, Color surface, Color text, Color subtext) {
    final cart = ref.watch(cartProvider);
    final qtyInCart = cart.where((ci) => ci.foodItem.id == item.id).fold(0, (s, ci) => s + ci.quantity);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AppImage(url: item.imageUrl, width: double.infinity, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: text),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            item.description,
            style: GoogleFonts.inter(fontSize: 10, color: subtext),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GHS ${item.price.toStringAsFixed(2)}',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
              if (qtyInCart == 0)
                GestureDetector(
                  onTap: () {
                    ref.read(cartProvider.notifier).addItem(item, restaurantId: widget.restaurantId);
                    _showFeedback('Added ${item.name}');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 14),
                  ),
                )
              else
                _CartQtyButton(
                  qty: qtyInCart,
                  onAdd: () => ref.read(cartProvider.notifier).addItem(item, restaurantId: widget.restaurantId),
                  onRemove: () => ref.read(cartProvider.notifier).removeItem(item.id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCart(List<CartItem> cart, double total, Color surface, Color text) {
    final firstName = cart.first.foodItem.name;
    return GestureDetector(
      onTap: () => setState(() => _showCheckout = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 108, 73, 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Cart',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  Text(
                    '${_cartItemCount} Item \u2022 $firstName',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color.fromRGBO(255, 255, 255, 0.8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              'GHS ${total.toStringAsFixed(2)}',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutOverlay(
    List<CartItem> cart,
    double subtotal,
    double discount,
    double deliveryFeeVal,
    double tax,
    double total,
    Color surface,
    Color text,
    Color subtext,
  ) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => setState(() => _showCheckout = false),
            child: Container(color: const Color.fromRGBO(0, 0, 0, 0.5)),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: MediaQuery.of(context).size.height * 0.75,
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(128, 128, 128, 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Text(
                        'Your Order',
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: text),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _showCheckout = false),
                        child: Icon(Icons.close_rounded, color: subtext, size: 24),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      ...cart.map((ci) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(128, 128, 128, 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AppImage(url: ci.foodItem.imageUrl, width: 52, height: 52, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ci.foodItem.name,
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: text),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'GHS ${ci.foodItem.price.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(fontSize: 12, color: subtext),
                                  ),
                                ],
                              ),
                            ),
                            _CartQtyButton(
                              qty: ci.quantity,
                              onAdd: () => ref.read(cartProvider.notifier).addItem(ci.foodItem, restaurantId: widget.restaurantId),
                              onRemove: () => ref.read(cartProvider.notifier).removeItem(ci.foodItem.id),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 8),
                      _PromoInputRow(
                        appliedPromo: _appliedPromo,
                        onApply: (code) {
                          setState(() => _appliedPromo = code.toUpperCase());
                        },
                        onRemove: () => setState(() => _appliedPromo = null),
                        surface: surface,
                        textColor: text,
                        subtextColor: subtext,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: BoxDecoration(
                    color: surface,
                    border: Border(top: BorderSide(color: const Color.fromRGBO(128, 128, 128, 0.1))),
                  ),
                  child: Column(
                    children: [
                      _buildCheckoutSelector(
                        icon: Icons.location_on_outlined,
                        label: 'Deliver to',
                        value: _selectedAddress,
                        options: _addresses,
                        onChanged: (v) => setState(() => _selectedAddress = v),
                        surface: surface,
                        text: text,
                      ),
                      const SizedBox(height: 8),
                      _buildCheckoutSelector(
                        icon: Icons.payments_outlined,
                        label: 'Pay with',
                        value: _selectedPayment,
                        options: _payments,
                        onChanged: (v) => setState(() => _selectedPayment = v),
                        surface: surface,
                        text: text,
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      _CheckoutPriceRow(label: 'Subtotal', value: subtotal),
                      if (discount > 0)
                        _CheckoutPriceRow(label: 'Discount ($_appliedPromo)', value: -discount, isDiscount: true),
                      _CheckoutPriceRow(label: 'Delivery', value: deliveryFeeVal),
                      _CheckoutPriceRow(label: 'Tax', value: tax),
                      const Divider(height: 16),
                      _CheckoutPriceRow(label: 'Total', value: total, isBold: true),
                      const SizedBox(height: 12),
                        GestureDetector(
                        onTap: cart.isEmpty
                            ? null
                            : () async {
                                setState(() => _showCheckout = false);

                                final user = ref.read(currentUserProvider);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CheckoutScreen(
                                      restaurantId: widget.restaurantId,
                                      restaurantName: _restaurant.name,
                                      cartItems: cart,
                                      subtotal: subtotal,
                                      deliveryFee: deliveryFeeVal,
                                      tax: tax,
                                      discount: discount,
                                      total: total,
                                      deliveryAddress: _selectedAddress,
                                      promoCode: _appliedPromo,
                                      orderType: 'food',
                                      userEmail: user?.email ?? 'customer@test.com',
                                    ),
                                  ),
                                );
                              },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: cart.isEmpty ? const Color.fromRGBO(128, 128, 128, 0.3) : AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Place Order \u2022 GHS ${total.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: cart.isEmpty ? const Color.fromRGBO(128, 128, 128, 0.6) : Colors.white,
                              ),
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
      ],
    );
  }

  Widget _buildCheckoutSelector({
    required IconData icon,
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
    required Color surface,
    required Color text,
  }) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBBCABF),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(label, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                ...options.map((opt) => ListTile(
                  leading: Icon(opt == value ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: const Color(0xFF006C49)),
                  title: Text(opt, style: GoogleFonts.inter(fontSize: 16)),
                  onTap: () {
                    onChanged(opt);
                    Navigator.pop(ctx);
                  },
                )),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF006C49), size: 20),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6C7A71))),
            const SizedBox(width: 8),
            Expanded(
              child: Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: text), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6C7A71), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCartToast(Color surface, Color text) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        opacity: _showCartFeedback ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _cartFeedbackMsg,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── HELPER WIDGETS ───────────────────────

class _HeroButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeroButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(0, 0, 0, 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _InfoStat({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

class _CartQtyButton extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _CartQtyButton({required this.qty, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(Icons.remove_rounded, color: Colors.white, size: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$qty',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(Icons.add_rounded, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutPriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  final bool isDiscount;

  const _CheckoutPriceRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isDiscount ? AppColors.primary : null,
            ),
          ),
          Text(
            (isDiscount ? '-' : '') + 'GHS ${value.abs().toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: isBold ? 16 : 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isDiscount ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoInputRow extends StatefulWidget {
  final String? appliedPromo;
  final ValueChanged<String> onApply;
  final VoidCallback onRemove;
  final Color surface;
  final Color textColor;
  final Color subtextColor;

  const _PromoInputRow({
    required this.appliedPromo,
    required this.onApply,
    required this.onRemove,
    required this.surface,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  State<_PromoInputRow> createState() => _PromoInputRowState();
}

class _PromoInputRowState extends State<_PromoInputRow> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.appliedPromo != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(0, 108, 73, 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer_rounded, color: AppColors.primary, size: 16),
            const SizedBox(width: 8),
            Text(
              widget.appliedPromo!,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            const Spacer(),
            GestureDetector(
              onTap: widget.onRemove,
              child: const Icon(Icons.close_rounded, color: AppColors.primary, size: 18),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            style: GoogleFonts.inter(fontSize: 13, color: widget.textColor),
            decoration: InputDecoration(
              hintText: 'Enter promo code',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: widget.subtextColor),
              prefixIcon: Icon(Icons.local_offer_rounded, color: widget.subtextColor, size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color.fromRGBO(128, 128, 128, 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color.fromRGBO(128, 128, 128, 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            if (_ctrl.text.isNotEmpty) widget.onApply(_ctrl.text);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Apply',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────── CATEGORY TAB DELEGATE ───────────────────────

class _CategoryTabDelegate extends SliverPersistentHeaderDelegate {
  final String selected;
  final ValueChanged<String> onSelect;
  final Color surfaceColor;
  final Color textColor;

  _CategoryTabDelegate({
    required this.selected,
    required this.onSelect,
    required this.surfaceColor,
    required this.textColor,
  });

  static const _tabs = ['Popular', 'Combos', 'Burgers', 'Sides', 'Drinks'];

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final tab = _tabs[i];
          final isActive = tab == selected;
          return GestureDetector(
            onTap: () => onSelect(tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : const Color.fromRGBO(128, 128, 128, 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tab,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.white : textColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryTabDelegate oldDelegate) {
    return oldDelegate.selected != selected || oldDelegate.surfaceColor != surfaceColor;
  }
}
