import 'package:flutter/material.dart';

// Keyword -> emoji, checked as substrings of the (lowercased) item name.
// First match wins, so put more specific keywords before generic ones.
const Map<String, String> kEmojiKeywords = {
  'toilet paper': '🧻', 'tissue': '🧻', 'paper towel': '🧻',
  'milk': '🥛', 'cheese': '🧀', 'butter': '🧈', 'yog': '🍦', 'cream': '🥛',
  'egg': '🥚',
  'carcass': '🦴', 'chicken': '🍗', 'beef': '🥩', 'steak': '🥩', 'meat': '🥩',
  'mince': '🥩', 'minced': '🥩',
  'bacon': '🥓', 'sausage': '🌭', 'ham': '🍖',
  'fish': '🐟', 'salmon': '🐟', 'shrimp': '🦐', 'prawn': '🦐',
  'pineapple': '🍍',
  'apple': '🍎', 'banana': '🍌', 'orange': '🍊', 'lemon': '🍋',
  'grape': '🍇', 'melon': '🍉', 'strawberr': '🍓', 'avocado': '🥑',
  'mango': '🥭', 'peach': '🍑', 'pear': '🍐',
  'sweet potato': '🍠', 'yam': '🍠',
  'tomato': '🍅', 'potato': '🥔', 'onion': '🧅', 'garlic': '🧄',
  'carrot': '🥕', 'pepper': '🌶️', 'cucumber': '🥒', 'mushroom': '🍄',
  'corn': '🌽', 'lettuce': '🥬', 'salad': '🥬', 'broccoli': '🥦',
  'pea': '🟢',
  'bread': '🍞', 'bun': '🍞', 'toast': '🍞', 'bagel': '🥯',
  'croissant': '🥐', 'cake': '🍰', 'cookie': '🍪', 'biscuit': '🍪',
  'donut': '🍩', 'pie': '🥧',
  'sushi': '🍣',
  'rice': '🍚', 'pasta': '🍝', 'noodle': '🍜', 'flour': '🌾',
  'tin foil': '🧻',
  'oil': '🫒', 'honey': '🍯', 'sugar': '🧂', 'salt': '🧂',
  'coffee': '☕', 'tea': '🍵', 'water': '💧', 'juice': '🧃',
  'soda': '🥤', 'cola': '🥤', 'wine': '🍷', 'beer': '🍺',
  'chip': '🍟', 'fries': '🍟', 'chocolate': '🍫', 'candy': '🍬',
  'popcorn': '🍿', 'ice cream': '🍦',
  'soap': '🧼', 'detergent': '🧴', 'shampoo': '🧴', 'sponge': '🧽',
  'trash bag': '🗑️', 'bin bag': '🗑️',
  'diaper': '👶', 'nappy': '👶',
  'pet food': '🐾', 'dog food': '🐾', 'cat food': '🐾',

  // Brands / restaurant-specific vocabulary.
  'shiitake': '🍄', '7up': '🥤', 'asahi': '🍺', 'kirin': '🍺',
  'sagres': '🍺', 'sapporo': '🍺', 'super bock': '🍺', 'coke': '🥤',
  'sumol': '🧃', 'soju': '🥃',
  'back fat': '🥓', 'pork belly': '🥓', 'bone': '🦴',
  'pork': '🥩', 'trotter': '🐷', 'pig': '🐷',
  'cow': '🐄', 'goat': '🐐', 'sheep': '🐑',
  'vinegar': '🍶',
  'cloth': '🧽', 'scouring': '🧽',
  'cleaner': '🧴', 'hand washing': '🧼', 'washing up': '🧼',
  'hand towel': '🧻', 'napkin': '🧻',
  'sandwich bag': '🛍️', 'cannister': '🛢️', 'canister': '🛢️',
  'gloves': '🧤',
  'chilli': '🌶️', 'gochujang': '🌶️', 'toban djan': '🌶️',
  'sichimi': '🌶️',
  'till roll': '🧾', 'spring roll': '🥟', 'roll': '🍞',
  'aubergine': '🍆', 'mochi': '🍡', 'string': '🧵', 'lime': '🍋',
  'mint': '🌿', 'coriander': '🌿', 'cabbage': '🥬', 'pak choi': '🥬',
  'leek': '🧅', 'beansprout': '🌱', 'takeaway': '🥡', 'tofu': '⬜',
  'wonton': '🥟', 'ginger': '🧄',
  'dashi': '🍲', 'miso': '🍲',
  'kombu': '🌊', 'nori': '🌊', 'wakame': '🌊',
  'mirin': '🍶', 'sake': '🍶', 'shoyu': '🍶',
  'sesame': '🌰', 'goma': '🌰',
  'msg': '🧂',
  'ice': '🧊',

  // Fast food / prepared meals
  'pizza': '🍕', 'burger': '🍔', 'hot dog': '🌭', 'taco': '🌮',
  'burrito': '🌯', 'sandwich': '🥪',

  // More bakery
  'pretzel': '🥨', 'baguette': '🥖', 'tortilla': '🫓', 'pita': '🫓',
  'waffle': '🧇',

  // More fruit
  'kiwi': '🥝', 'cherry': '🍒', 'blueberr': '🫐',

  // More produce
  'spinach': '🥬', 'kale': '🥬', 'zucchini': '🥒', 'pumpkin': '🎃',

  // More seafood
  'crab': '🦀', 'lobster': '🦞', 'squid': '🦑', 'calamari': '🦑',
  'octopus': '🐙', 'oyster': '🦪', 'clam': '🦪', 'mussel': '🦪',
  'tuna': '🐟',

  // More meat / poultry
  'turkey': '🦃', 'duck': '🦆', 'lamb': '🍖', 'veal': '🥩',

  // Grains / legumes
  'cereal': '🥣', 'oat': '🥣', 'lentil': '🫘', 'bean': '🫘',

  // More herbs
  'basil': '🌿', 'parsley': '🌿', 'rosemary': '🌿', 'thyme': '🌿',
  'oregano': '🌿',

  // Nuts
  'peanut': '🥜', 'cashew': '🥜', 'walnut': '🌰', 'almond': '🌰',
  'pistachio': '🌰', 'hazelnut': '🌰', 'coconut': '🥥',

  // Personal care / household extras
  'toothpaste': '🪥', 'toothbrush': '🪥', 'razor': '🪒',
  'candle': '🕯️', 'battery': '🔋', 'batteries': '🔋', 'bulb': '💡',
  'formula': '🍼',

  // Condiments
  'ketchup': '🍅', 'soy sauce': '🍶',

  // More Japanese
  'ramen': '🍜', 'udon': '🍜', 'soba': '🍜', 'onigiri': '🍙',
  'katsu': '🍱', 'bento': '🍱', 'tempura': '🍤', 'edamame': '🟢',
  'matcha': '🍵', 'takoyaki': '🐙', 'yakitori': '🍢', 'teriyaki': '🍢',
  'skewer': '🍢',

  // More Chinese / Korean
  'dumpling': '🥟', 'gyoza': '🥟', 'bok choy': '🥬', 'congee': '🥣',
  'kimchi': '🌶️', 'kimbap': '🍙',

  // Tableware
  'chopsticks': '🥢',

  // Bar / cocktails
  'cocktail': '🍸', 'martini': '🍸', 'vodka': '🍸', 'gin': '🍸',
  'margarita': '🍹', 'mojito': '🍹',
  'whisky': '🥃', 'whiskey': '🥃', 'rum': '🥃', 'tequila': '🥃',
  'champagne': '🍾', 'prosecco': '🍾', 'cider': '🍺',

  // More produce
  'chestnut': '🌰', 'celery': '🥬',

  // More seafood
  'sardine': '🐟', 'anchovy': '🐟', 'scallop': '🦪',

  // More desserts
  'custard': '🍮', 'flan': '🍮', 'pudding': '🍮',
  'muffin': '🧁', 'cupcake': '🧁',

  // More snacks
  'rice cracker': '🍘', 'cracker': '🍘',
  'granola': '🥣', 'trail mix': '🥜',

  // More beverages
  'energy drink': '🥤', 'smoothie': '🧃', 'kombucha': '🫙',
  'bubble tea': '🧋', 'boba': '🧋',

  // Canned / jarred pantry
  'canned': '🥫', 'tinned': '🥫',
  'jam': '🫙', 'marmalade': '🫙', 'pickle': '🫙', 'preserve': '🫙',
  'chutney': '🫙',
  'stock cube': '🧂', 'bouillon': '🧂',

  // More grains
  'quinoa': '🌾', 'couscous': '🌾',

  // More household / cleaning
  'dishwasher': '🧼', 'fabric softener': '🧴', 'bleach': '🧴',

  // More personal care
  'sunscreen': '🧴', 'deodorant': '🧴', 'shaving': '🪒', 'mouthwash': '🪥',

  // More baby
  'wet wipe': '🧻', 'baby wipe': '👶', 'pacifier': '👶', 'baby food': '👶',
};

/// Sentinel stored on [GroceryItem.avatarIconName] to explicitly force the
/// plain letter-initials avatar, overriding the emoji auto-match a name
/// would otherwise get. Lets a user opt out of a forced/wrong auto-icon.
const String kInitialsAvatarKey = '__initials__';

/// Emoji whose keyword matches a substring of [name] (case-insensitive), or
/// null if nothing matches.
String? emojiForItemName(String name) {
  final lower = name.toLowerCase();
  for (final entry in kEmojiKeywords.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return null;
}

/// Every distinct emoji from [kEmojiKeywords], in first-seen order, so the
/// icon picker can offer them as choices too — not just the Material icons.
final List<String> kAvatarEmojiChoices = kEmojiKeywords.values.toSet().toList();

/// Reverse of [kEmojiKeywords]: emoji -> every keyword that matches to it
/// (e.g. '🐷' -> ['trotter']). Lets the icon picker's search box find an
/// emoji by the grocery term for it, since the emoji character itself isn't
/// something a user can type.
final Map<String, List<String>> kKeywordsForEmoji = () {
  final map = <String, List<String>>{};
  for (final entry in kEmojiKeywords.entries) {
    map.putIfAbsent(entry.value, () => []).add(entry.key);
  }
  return map;
}();

/// First letter of the first two words (or the first two letters of a
/// single word) — e.g. "Toilet Tissue" -> "TT", "Milk" -> "MI".
String initialsForItemName(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) {
    final w = words.first;
    return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
  }
  return (words[0][0] + words[1][0]).toUpperCase();
}

/// Curated Material icons a user can pick to override an item's
/// auto-assigned avatar (emoji keyword match / letter initials).
/// Keys are what gets persisted on [GroceryItem.avatarIconName].
const Map<String, IconData> kAvatarIconChoices = {
  // General / grocery
  'shopping_basket': Icons.shopping_basket,
  'shopping_cart': Icons.shopping_cart,
  'local_grocery_store': Icons.local_grocery_store,
  'inventory_2': Icons.inventory_2,
  'category': Icons.category,
  'kitchen': Icons.kitchen,
  'restaurant': Icons.restaurant,
  'restaurant_menu': Icons.restaurant_menu,
  'dining': Icons.dining,

  // Produce
  'eco': Icons.eco,
  'grass': Icons.grass,
  'spa': Icons.spa,
  'nature': Icons.nature,

  // Meat / seafood
  'set_meal': Icons.set_meal,
  'egg': Icons.egg,
  'egg_alt': Icons.egg_alt,

  // Bakery / grains
  'bakery_dining': Icons.bakery_dining,
  'breakfast_dining': Icons.breakfast_dining,
  'rice_bowl': Icons.rice_bowl,
  'ramen_dining': Icons.ramen_dining,
  'lunch_dining': Icons.lunch_dining,
  'cake': Icons.cake,
  'icecream': Icons.icecream,
  'cookie': Icons.cookie,

  // Beverages
  'local_cafe': Icons.local_cafe,
  'local_bar': Icons.local_bar,
  'local_drink': Icons.local_drink,
  'liquor': Icons.liquor,
  'water_drop': Icons.water_drop,
  'emoji_food_beverage': Icons.emoji_food_beverage,
  'coffee': Icons.coffee,
  'wine_bar': Icons.wine_bar,
  'sports_bar': Icons.sports_bar,

  // Snacks / other food
  'local_pizza': Icons.local_pizza,
  'tapas': Icons.tapas,
  'soup_kitchen': Icons.soup_kitchen,
  'grain': Icons.grain,
  'ac_unit': Icons.ac_unit, // frozen

  // Household / cleaning
  'cleaning_services': Icons.cleaning_services,
  'soap': Icons.soap,
  'countertops': Icons.countertops,
  'wash': Icons.wash,
  'dry_cleaning': Icons.dry_cleaning,
  'sanitizer': Icons.sanitizer,
  'delete_outline': Icons.delete_outline,
  'auto_awesome': Icons.auto_awesome,

  // Paper / packaging
  'receipt_long': Icons.receipt_long,
  'inventory': Icons.inventory,
  'archive': Icons.archive,

  // Baby / pets
  'child_care': Icons.child_care,
  'pets': Icons.pets,

  // Misc
  'star': Icons.star,
  'label_important': Icons.label_important,
  'favorite': Icons.favorite,

  // More food (closest available to the manually-added emoji keywords —
  // Material Icons has no literal sushi/mochi/wonton/ginger glyph, so these
  // are the nearest fit).
  'fastfood': Icons.fastfood,
  'local_dining': Icons.local_dining,
  'food_bank': Icons.food_bank,
  'dinner_dining': Icons.dinner_dining,
  'brunch_dining': Icons.brunch_dining,
  'kebab_dining': Icons.kebab_dining, // skewered/grilled (yakitori-ish)
  'takeout_dining': Icons.takeout_dining, // takeaway pots
  'whatshot': Icons.whatshot, // spicy — chilli, gochujang, sichimi
  'local_fire_department': Icons.local_fire_department,
  'phishing': Icons.phishing, // fishing hook — fish/seafood

  // More beverages
  'coffee_maker': Icons.coffee_maker,

  // More produce / nature
  'local_florist': Icons.local_florist, // herbs — mint, coriander
  'park': Icons.park,
  'forest': Icons.forest,
  'yard': Icons.yard,
  'agriculture': Icons.agriculture,

  // Hardware / supplies (gas cannisters, string, tools)
  'construction': Icons.construction,
  'build': Icons.build,
  'handyman': Icons.handyman,
  'hardware': Icons.hardware,
  'plumbing': Icons.plumbing,
  'propane_tank': Icons.propane_tank, // gas cannisters
  'electrical_services': Icons.electrical_services,

  // More cleaning / household
  'local_laundry_service': Icons.local_laundry_service,
  'iron': Icons.iron,
  'delete_sweep': Icons.delete_sweep,

  // More paper / packaging
  'receipt': Icons.receipt,
  'description': Icons.description,
  'article': Icons.article,
  'sticky_note_2': Icons.sticky_note_2,
  'all_inbox': Icons.all_inbox,

  // Weight / measure (meat, bones, produce sold by kg)
  'scale': Icons.scale,
  'monitor_weight': Icons.monitor_weight,

  // Kitchen equipment
  'microwave': Icons.microwave,
  'blender': Icons.blender,
  'local_shipping': Icons.local_shipping,

  // Baby
  'stroller': Icons.stroller,

  // Generic shapes / symbols (flexible fallback labeling)
  'circle': Icons.circle,
  'square': Icons.square,
  'hexagon': Icons.hexagon,
  'bolt': Icons.bolt,
  'label': Icons.label,
  'bookmark': Icons.bookmark,
  'push_pin': Icons.push_pin,

  // Time / schedule (best-before, delivery day, par-level tracking)
  'schedule': Icons.schedule,
  'access_time': Icons.access_time,
  'event': Icons.event,
  'today': Icons.today,
  'history': Icons.history,
  'update': Icons.update,
  'hourglass_empty': Icons.hourglass_empty,
  'timer': Icons.timer,

  // Finance / shopping
  'attach_money': Icons.attach_money,
  'local_offer': Icons.local_offer,
  'sell': Icons.sell,
  'price_check': Icons.price_check,
  'payments': Icons.payments,
  'point_of_sale': Icons.point_of_sale,

  // Delivery / supplier
  'delivery_dining': Icons.delivery_dining,
  'storefront': Icons.storefront,
  'store': Icons.store,
  'warehouse': Icons.warehouse,

  // Weather / temperature
  'wb_sunny': Icons.wb_sunny,
  'thermostat': Icons.thermostat,
  'opacity': Icons.opacity,

  // Office / tracking
  'folder': Icons.folder,
  'folder_open': Icons.folder_open,
  'qr_code': Icons.qr_code,
  'qr_code_scanner': Icons.qr_code_scanner,
  'qr_code_2': Icons.qr_code_2,

  // Warnings / allergens / out of stock
  'warning': Icons.warning,
  'warning_amber': Icons.warning_amber,
  'report_problem': Icons.report_problem,
  'no_food': Icons.no_food,
  'dangerous': Icons.dangerous,

  // Health / safety
  'medical_services': Icons.medical_services,
  'healing': Icons.healing,
  'local_pharmacy': Icons.local_pharmacy,
  'masks': Icons.masks,
  'health_and_safety': Icons.health_and_safety,

  // More dining / storage
  'flatware': Icons.flatware,
  'storage': Icons.storage,
  'outdoor_grill': Icons.outdoor_grill,

  // More symbols / badges
  'diamond': Icons.diamond,
  'grade': Icons.grade,
  'new_releases': Icons.new_releases,
  'verified': Icons.verified,
  'numbers': Icons.numbers,

  // Hygiene / personal care
  'clean_hands': Icons.clean_hands,
  'wc': Icons.wc,
  'bathroom': Icons.bathroom,
  'bathtub': Icons.bathtub,
  'shower': Icons.shower,
  'brush': Icons.brush,
  'dry': Icons.dry, // hand dryer
  'baby_changing_station': Icons.baby_changing_station,
  'recycling': Icons.recycling, // bin bags / waste
  'face': Icons.face,
  'local_hospital': Icons.local_hospital,
};
