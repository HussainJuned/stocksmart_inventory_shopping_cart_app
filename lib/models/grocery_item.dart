import 'package:uuid/uuid.dart';

// Sentinel for copyWith's nullable fields, so "clear this field" (pass
// null) can be told apart from "leave it unchanged" (omit the argument).
class _Unset {
  const _Unset();
}

const _unset = _Unset();

class GroceryItem {
  final String id;
  final String name;
  final List<String> categoryIds; // Changed from single categoryId
  final String? defaultSupplierId;
  final String? storageTypeId; // Link to StorageType (dry, fresh, drinks...)
  // User-picked override for the avatar icon (a key into the app's curated
  // icon set — see avatar_icons.dart). Null means auto-pick from the item
  // name (emoji keyword match, falling back to letter initials).
  final String? avatarIconName;
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
    this.storageTypeId,
    this.avatarIconName,
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
    String? storageTypeId,
    String? avatarIconName,
    required String unit,
    required double parLevel,
    double sortOrder = 0.0,
  }) {
    return GroceryItem(
      id: const Uuid().v4(),
      name: name,
      categoryIds: categoryIds,
      defaultSupplierId: defaultSupplierId,
      storageTypeId: storageTypeId,
      avatarIconName: avatarIconName,
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
    Object? defaultSupplierId = _unset,
    Object? storageTypeId = _unset,
    Object? avatarIconName = _unset,
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
      defaultSupplierId: identical(defaultSupplierId, _unset)
          ? this.defaultSupplierId
          : defaultSupplierId as String?,
      storageTypeId: identical(storageTypeId, _unset)
          ? this.storageTypeId
          : storageTypeId as String?,
      avatarIconName: identical(avatarIconName, _unset)
          ? this.avatarIconName
          : avatarIconName as String?,
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
      'storageTypeId': storageTypeId,
      'avatarIconName': avatarIconName,
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
      storageTypeId: map['storageTypeId'],
      avatarIconName: map['avatarIconName'],
      unit: map['unit'],
      parLevel: (map['parLevel'] as num).toDouble(),
      currentQuantity: (map['currentQuantity'] as num).toDouble(),
      sortOrder: (map['sortOrder'] as num?)?.toDouble() ?? 0.0,
      isActive: map['isActive'] ?? true,
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
}
