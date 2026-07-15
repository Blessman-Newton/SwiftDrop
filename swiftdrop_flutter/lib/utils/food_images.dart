/// Local food photos bundled in assets/images, used as graceful fallbacks when
/// a restaurant or menu item has no (or a broken) network image.
class FoodImages {
  static const String _base = 'assets/images/';

  /// Every bundled food photo.
  static const List<String> all = [
    'jollof.jpg',
    'jollof_2.jpg',
    'banku.jpg',
    'banku_tilapia.jpg',
    'shawarma.jpg',
    'shawarma_2.jpg',
    'chicken_chips.jpg',
    'fried_rice.jpg',
    'burger.jpg',
    'spaghetti.jpg',
    'food_1.jpg',
    'food_2.jpg',
    'food_3.jpg',
  ];

  /// Keyword → best-matching photo, so a "Jollof Rice" item shows jollof, etc.
  static const Map<String, String> _keywords = {
    'jollof': 'jollof.jpg',
    'waakye': 'jollof_2.jpg',
    'fried rice': 'fried_rice.jpg',
    'rice': 'fried_rice.jpg',
    'banku': 'banku.jpg',
    'tilapia': 'banku_tilapia.jpg',
    'tuo': 'banku.jpg',
    'fufu': 'banku.jpg',
    'fufuo': 'banku.jpg',
    'fish': 'banku_tilapia.jpg',
    'shawarma': 'shawarma.jpg',
    'shorma': 'shawarma_2.jpg',
    'wrap': 'shawarma.jpg',
    'chicken': 'chicken_chips.jpg',
    'chips': 'chicken_chips.jpg',
    'fries': 'chicken_chips.jpg',
    'wings': 'chicken_chips.jpg',
    'grill': 'chicken_chips.jpg',
    'burger': 'burger.jpg',
    'beef': 'shawarma_2.jpg',
    'spaghetti': 'spaghetti.jpg',
    'pasta': 'spaghetti.jpg',
    'noodle': 'spaghetti.jpg',
    'combo': 'food_1.jpg',
    'special': 'food_2.jpg',
    'local': 'jollof.jpg',
  };

  /// Pick a photo for the given name — keyword match first, then a stable
  /// hash-based choice so different items get different photos.
  static String forName(String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.isNotEmpty) {
      for (final entry in _keywords.entries) {
        if (n.contains(entry.key)) return _base + entry.value;
      }
    }
    return pick(name ?? '');
  }

  /// Deterministic pick from [all] based on a seed string.
  static String pick(String seed) {
    if (seed.isEmpty) return _base + all.first;
    final idx = seed.hashCode.abs() % all.length;
    return _base + all[idx];
  }
}
