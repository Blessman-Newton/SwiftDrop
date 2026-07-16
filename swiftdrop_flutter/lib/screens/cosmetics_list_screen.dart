import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:swiftdrop/models/models.dart';
import 'package:swiftdrop/providers/providers.dart';
import 'package:swiftdrop/services/customer_service.dart';
import 'package:swiftdrop/theme/app_theme.dart';

class CosmeticsListScreen extends ConsumerStatefulWidget {
  const CosmeticsListScreen({super.key});

  @override
  ConsumerState<CosmeticsListScreen> createState() => _CosmeticsListScreenState();
}

class _CosmeticsListScreenState extends ConsumerState<CosmeticsListScreen> {
  final CustomerService _customerService = CustomerService();
  List<Map<String, dynamic>> _cosmetics = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCosmetics();
  }

  Future<void> _loadCosmetics() async {
    setState(() => _isLoading = true);
    final data = await _customerService.getCosmetics();
    if (mounted) {
      setState(() {
        _cosmetics = data ?? [];
        _isLoading = false;
      });
    }
  }

  void _addCosmeticToCart(Map<String, dynamic> c) {
    final foodItem = FoodItem(
      id: c['id'] as String,
      name: c['name'] as String,
      price: c['price'] as double,
      description: c['description'] as String? ?? '',
      imageUrl: c['image_url'] as String? ?? '',
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final filteredCosmetics = _cosmetics.where((c) {
      final name = (c['name'] as String).toLowerCase();
      final desc = (c['description'] as String? ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || desc.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Cosmetics Catalog',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search organic skin creams, oils...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filteredCosmetics.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.face_retouching_off_rounded, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No Cosmetics Available',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: filteredCosmetics.length,
                        itemBuilder: (context, index) {
                          final item = filteredCosmetics[index];
                          final price = item['price'] as double;
                          final imageUrl = item['image_url'] as String?;

                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image Header
                                Expanded(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: imageUrl != null && imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                                            child: const Center(
                                              child: Icon(Icons.image_outlined, color: Colors.grey),
                                            ),
                                          ),
                                  ),
                                ),
                                
                                // Product Description Body
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] as String,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['description'] as String? ?? 'Organic wellness skincare',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: isDark ? Colors.white60 : Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '₵${price.toStringAsFixed(2)}',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _addCosmeticToCart(item),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFEC4899), // Premium pink theme for cosmetics
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.add,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
