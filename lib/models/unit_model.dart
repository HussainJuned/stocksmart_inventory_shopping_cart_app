import 'package:uuid/uuid.dart';

/// A unit of measure an item can be tracked/ordered in (e.g. kg, box, can).
/// [name] is the exact string stored on [GroceryItem.unit], so items keep
/// showing their unit text even if the unit is later removed from this list.
class Unit {
  final String id;
  final String name;
  final int sortOrder;

  Unit({required this.id, required this.name, required this.sortOrder});

  factory Unit.create({required String name, int sortOrder = 0}) {
    return Unit(id: const Uuid().v4(), name: name, sortOrder: sortOrder);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'sortOrder': sortOrder};
  }

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'],
      name: map['name'],
      sortOrder: map['sortOrder'],
    );
  }
}
