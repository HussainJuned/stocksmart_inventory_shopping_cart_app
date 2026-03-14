import 'package:uuid/uuid.dart';

class Category {
  final String id;
  final String name;
  final String color; // Hex string e.g. "#FF0000"
  final int sortOrder;

  Category({
    required this.id,
    required this.name,
    required this.color,
    required this.sortOrder,
  });

  factory Category.create({
    required String name,
    required String color,
    int sortOrder = 0,
  }) {
    return Category(
      id: const Uuid().v4(),
      name: name,
      color: color,
      sortOrder: sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'color': color, 'sortOrder': sortOrder};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      sortOrder: map['sortOrder'],
    );
  }
}
