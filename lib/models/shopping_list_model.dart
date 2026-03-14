import 'package:uuid/uuid.dart';

enum CartStatus { active, archived }

enum CartItemState { pending, bought, skipped, unavailable }

class ShoppingList {
  final String id;
  final String? note;
  final DateTime createdAt;
  final CartStatus status;
  // We don't store items directly here for flexibility,
  // but provider maintains the relationship.
  // However, for archiving, it might be good to strictly associate them?
  // For now, keeping as header info.

  ShoppingList({
    required this.id,
    this.note,
    required this.createdAt,
    this.status = CartStatus.active,
  });

  factory ShoppingList.create() {
    return ShoppingList(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      status: CartStatus.active,
    );
  }

  ShoppingList copyWith({String? note, CartStatus? status}) {
    return ShoppingList(
      id: id,
      note: note ?? this.note,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
    };
  }

  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'],
      note: map['note'],
      createdAt: DateTime.parse(map['createdAt']),
      status: CartStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CartStatus.active,
      ),
    );
  }
}

class CartItem {
  final String id;
  final String listId;
  final String itemId;
  final String name;
  final String? supplierId;
  final double quantityNeeded;
  final String unit;
  final CartItemState state;
  final String? note;

  CartItem({
    required this.id,
    required this.listId,
    required this.itemId,
    required this.name,
    this.supplierId,
    required this.quantityNeeded,
    required this.unit,
    this.state = CartItemState.pending,
    this.note,
  });

  factory CartItem.create({
    required String listId,
    required String itemId,
    required String name,
    String? supplierId,
    required double quantityNeeded,
    required String unit,
  }) {
    return CartItem(
      id: const Uuid().v4(),
      listId: listId,
      itemId: itemId,
      name: name,
      supplierId: supplierId,
      quantityNeeded: quantityNeeded,
      unit: unit,
      state: CartItemState.pending,
    );
  }

  CartItem copyWith({
    double? quantityNeeded,
    CartItemState? state,
    String? note,
    String? supplierId,
  }) {
    return CartItem(
      id: id,
      listId: listId,
      itemId: itemId,
      name: name,
      supplierId: supplierId ?? this.supplierId,
      quantityNeeded: quantityNeeded ?? this.quantityNeeded,
      unit: unit,
      state: state ?? this.state,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listId': listId,
      'itemId': itemId,
      'name': name,
      'supplierId': supplierId,
      'quantityNeeded': quantityNeeded,
      'unit': unit,
      'state': state.name,
      'note': note,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      listId: map['listId'],
      itemId: map['itemId'],
      name: map['name'],
      supplierId: map['supplierId'],
      quantityNeeded: (map['quantityNeeded'] as num).toDouble(),
      unit: map['unit'] ?? 'units',
      state: CartItemState.values.firstWhere(
        (e) => e.name == map['state'],
        orElse: () => map['isChecked'] == true
            ? CartItemState.bought
            : CartItemState.pending, // Migration for old 'isChecked'
      ),
      note: map['note'],
    );
  }
}
