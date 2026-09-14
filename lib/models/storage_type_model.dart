import 'package:uuid/uuid.dart';

/// Describes where/how an item is stored (e.g. Dry Food, Fresh Food, Drinks,
/// Cleaning). Used to group cart items for shopping/put-away, similar to how
/// Category and Supplier group items elsewhere in the app.
class StorageType {
  final String id;
  final String name;
  final String color; // Hex string e.g. "#FF0000"
  final int sortOrder;

  StorageType({
    required this.id,
    required this.name,
    required this.color,
    required this.sortOrder,
  });

  factory StorageType.create({
    required String name,
    required String color,
    int sortOrder = 0,
  }) {
    return StorageType(
      id: const Uuid().v4(),
      name: name,
      color: color,
      sortOrder: sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'color': color, 'sortOrder': sortOrder};
  }

  factory StorageType.fromMap(Map<String, dynamic> map) {
    return StorageType(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      sortOrder: map['sortOrder'],
    );
  }
}
