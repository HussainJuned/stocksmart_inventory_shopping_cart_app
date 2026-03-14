import 'package:uuid/uuid.dart';

class Supplier {
  final String id;
  final String name;
  final bool isActive;

  Supplier({required this.id, required this.name, this.isActive = true});

  factory Supplier.create({required String name}) {
    return Supplier(id: const Uuid().v4(), name: name);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'isActive': isActive};
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      isActive: map['isActive'] ?? true,
    );
  }

  Supplier copyWith({String? name, bool? isActive}) {
    return Supplier(
      id: id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }
}
