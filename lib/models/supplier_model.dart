import 'package:uuid/uuid.dart';

class Supplier {
  final String id;
  final String name;
  final bool isActive;
  final int sortOrder;

  Supplier({
    required this.id,
    required this.name,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory Supplier.create({required String name, int sortOrder = 0}) {
    return Supplier(id: const Uuid().v4(), name: name, sortOrder: sortOrder);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      isActive: map['isActive'] ?? true,
      // Older records predate sortOrder — default to 0 so they still sort
      // deterministically (by name-insertion order) instead of crashing.
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Supplier copyWith({String? name, bool? isActive, int? sortOrder}) {
    return Supplier(
      id: id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
