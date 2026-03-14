import 'package:uuid/uuid.dart';

class GroceryItem {
  final String id;
  final String name;
  final List<String> categoryIds; // Changed from single categoryId
  final String? defaultSupplierId;
  final String unit; // kg, g, pcs, L
  final double parLevel;
  final double currentQuantity;
  final double sortOrder;
  final bool isActive;
  final DateTime lastUpdated;

  GroceryItem({
    required this.id,
    required this.name,
    required this.categoryIds,
    this.defaultSupplierId,
    required this.unit,
    required this.parLevel,
    required this.currentQuantity,
    this.sortOrder = 0.0,
    this.isActive = true,
    required this.lastUpdated,
  });

  factory GroceryItem.create({
    required String name,
    required List<String> categoryIds,
    String? defaultSupplierId,
    required String unit,
    required double parLevel,
    double sortOrder = 0.0,
  }) {
    return GroceryItem(
      id: const Uuid().v4(),
      name: name,
      categoryIds: categoryIds,
      defaultSupplierId: defaultSupplierId,
      unit: unit,
      parLevel: parLevel,
      currentQuantity: 0.0,
      sortOrder: sortOrder,
      isActive: true,
      lastUpdated: DateTime.now(),
    );
  }

  GroceryItem copyWith({
    String? name,
    List<String>? categoryIds,
    String? defaultSupplierId,
    String? unit,
    double? parLevel,
    double? currentQuantity,
    double? sortOrder,
    bool? isActive,
    DateTime? lastUpdated,
  }) {
    return GroceryItem(
      id: id,
      name: name ?? this.name,
      categoryIds: categoryIds ?? this.categoryIds,
      defaultSupplierId: defaultSupplierId ?? this.defaultSupplierId,
      unit: unit ?? this.unit,
      parLevel: parLevel ?? this.parLevel,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryIds': categoryIds,
      'defaultSupplierId': defaultSupplierId,
      'unit': unit,
      'parLevel': parLevel,
      'currentQuantity': currentQuantity,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory GroceryItem.fromMap(Map<String, dynamic> map) {
    // Migration Logic:
    List<String> cats = [];
    if (map['categoryIds'] != null) {
      cats = List<String>.from(map['categoryIds']);
    } else if (map['categoryId'] != null) {
      cats = [map['categoryId']];
    }

    return GroceryItem(
      id: map['id'],
      name: map['name'],
      categoryIds: cats,
      defaultSupplierId:
          map['defaultSupplierId'] ??
          map['supplierId'], // Check both for migration
      unit: map['unit'],
      parLevel: (map['parLevel'] as num).toDouble(),
      currentQuantity: (map['currentQuantity'] as num).toDouble(),
      sortOrder: (map['sortOrder'] as num?)?.toDouble() ?? 0.0,
      isActive: map['isActive'] ?? true,
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
}
