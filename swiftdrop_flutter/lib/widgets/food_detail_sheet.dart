import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_image.dart';

List<Map<String, dynamic>> getExtrasForFood(String foodName) {
  final nameLower = foodName.toLowerCase();
  if (nameLower.contains('banku')) {
    return [
      {'name': 'Extra Goat', 'price': 40.0},
      {'name': 'Extra Chicken', 'price': 20.0},
      {'name': 'Extra banku', 'price': 5.0},
    ];
  } else if (nameLower.contains('jollof')) {
    return [
      {'name': 'Extra Chicken', 'price': 20.0},
      {'name': 'Extra Beef', 'price': 25.0},
      {'name': 'Extra Egg', 'price': 5.0},
      {'name': 'Extra Coleslaw', 'price': 4.0},
    ];
  } else if (nameLower.contains('fufu')) {
    return [
      {'name': 'Extra Goat Meat', 'price': 40.0},
      {'name': 'Extra Fish', 'price': 15.0},
      {'name': 'Extra Fufu', 'price': 10.0},
    ];
  } else if (nameLower.contains('burger') || nameLower.contains('sandwich')) {
    return [
      {'name': 'Extra Cheese', 'price': 8.0},
      {'name': 'Extra Beef Patty', 'price': 20.0},
      {'name': 'Extra Egg', 'price': 5.0},
    ];
  } else {
    return [
      {'name': 'Extra Chicken', 'price': 20.0},
      {'name': 'Extra Beef', 'price': 25.0},
      {'name': 'Extra Egg', 'price': 5.0},
    ];
  }
}

void showFoodDetailSheet({
  required BuildContext context,
  required WidgetRef ref,
  required FoodItem item,
  required Restaurant restaurant,
  required void Function(String message) onFeedback,
}) {
  final extrasList = getExtrasForFood(item.name);
  int mainQty = 1;
  final Map<String, int> selectedExtras = {
    for (var ext in extrasList) ext['name'] as String: 0
  };

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final cLowest = isDark ? AppColors.darkCard : Colors.white;
  final cLow = isDark ? const Color(0xFF1F2B44) : const Color(0xFFEEF6EE);
  final onSurface = isDark ? Colors.white : const Color(0xFF161D19);
  final onSurfaceVariant = isDark ? const Color(0xFF9FB0A4) : const Color(0xFF3C4A42);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final double extrasTotal = extrasList.fold(0.0, (sum, ext) {
            final name = ext['name'] as String;
            final price = ext['price'] as double;
            final qty = selectedExtras[name] ?? 0;
            return sum + (price * qty);
          });
          final double totalPrice = (item.price + extrasTotal) * mainQty;

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: cLowest,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          if (item.imageUrl.isNotEmpty)
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                  child: AppImage(
                                    url: item.imageUrl,
                                    height: 220,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(ctx),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: onSurface,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'from',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '₵${item.price.toStringAsFixed(0)}',
                                          style: GoogleFonts.inter(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    const Icon(Icons.storefront, color: Colors.orange, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      restaurant.name.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.orange, size: 18),
                                    const SizedBox(width: 6),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Location',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Tarkwa, Ghana',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: onSurface,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                Text(
                                  'Description',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.description.isNotEmpty ? item.description : 'No description provided.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                Text(
                                  'Menu',
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: onSurface,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cLow,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'MAIN',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade500,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '₵${item.price.toStringAsFixed(2)} each',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          _buildSheetCounter(
                                            onSurface: onSurface,
                                            value: mainQty,
                                            onDecrement: () {
                                              if (mainQty > 1) {
                                                setSheetState(() => mainQty--);
                                              }
                                            },
                                            onIncrement: () {
                                              setSheetState(() => mainQty++);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cLow,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SIDES',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade500,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: extrasList.length,
                                        separatorBuilder: (c, idx) => const Divider(height: 20),
                                        itemBuilder: (c, idx) {
                                          final ext = extrasList[idx];
                                          final name = ext['name'] as String;
                                          final price = ext['price'] as double;
                                          final currentQty = selectedExtras[name] ?? 0;

                                          return Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: onSurface,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '₵${price.toStringAsFixed(2)} each',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              _buildSheetCounter(
                                                onSurface: onSurface,
                                                value: currentQty,
                                                onDecrement: () {
                                                  if (currentQty > 0) {
                                                    setSheetState(() => selectedExtras[name] = currentQty - 1);
                                                  }
                                                },
                                                onIncrement: () {
                                                  setSheetState(() => selectedExtras[name] = currentQty + 1);
                                                },
                                              ),
                                            ],
                                          );
                                        },
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

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: cLowest,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final List<CartExtra> finalExtras = [];
                            selectedExtras.forEach((name, qty) {
                              if (qty > 0) {
                                final extConfig = extrasList.firstWhere((element) => element['name'] == name);
                                finalExtras.add(
                                  CartExtra(name: name, price: extConfig['price'] as double, quantity: qty),
                                );
                              }
                            });

                            ref.read(cartProvider.notifier).addCustomItem(
                              item,
                              finalExtras,
                              mainQty,
                              restaurantId: restaurant.id,
                            );

                            Navigator.pop(ctx);
                            onFeedback('Added ${item.name} to cart');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA500),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_cart, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Add to cart - ₵${totalPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

Widget _buildSheetCounter({
  required int value,
  required VoidCallback onDecrement,
  required VoidCallback onIncrement,
  required Color onSurface,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      GestureDetector(
        onTap: onDecrement,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.remove, size: 16, color: Colors.grey),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          '$value',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: onSurface,
          ),
        ),
      ),
      GestureDetector(
        onTap: onIncrement,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Color(0xFFFFA500),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, size: 16, color: Colors.white),
        ),
      ),
    ],
  );
}
