import 'package:hive_flutter/hive_flutter.dart';
import '../models/grocery_item.dart';
import '../models/category_model.dart';
import '../models/supplier_model.dart';
import '../models/shopping_list_model.dart';

class HiveService {
  static const String boxItems = 'grocery_items';
  static const String boxCategories = 'categories';
  static const String boxSuppliers = 'suppliers';
  static const String boxShoppingLists = 'shopping_lists';
  static const String boxCartItems = 'cart_items';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(boxItems);
    await Hive.openBox<Map>(boxCategories);
    await Hive.openBox<Map>(boxSuppliers);
    await Hive.openBox<Map>(boxShoppingLists);
    await Hive.openBox<Map>(boxCartItems);
  }

  Future<void> clearAll() async {
    await Hive.box<Map>(boxItems).clear();
    await Hive.box<Map>(boxCategories).clear();
    await Hive.box<Map>(boxSuppliers).clear();
    await Hive.box<Map>(boxShoppingLists).clear();
    await Hive.box<Map>(boxCartItems).clear();
  }

  // --- Items ---
  List<GroceryItem> getItems() {
    final box = Hive.box<Map>(boxItems);
    return box.values
        .map((e) => GroceryItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveItem(GroceryItem item) async {
    final box = Hive.box<Map>(boxItems);
    await box.put(item.id, item.toMap());
  }

  Future<void> deleteItem(String id) async {
    final box = Hive.box<Map>(boxItems);
    await box.delete(id);
  }

  // --- Categories ---
  List<Category> getCategories() {
    final box = Hive.box<Map>(boxCategories);
    return box.values
        .map((e) => Category.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveCategory(Category category) async {
    final box = Hive.box<Map>(boxCategories);
    await box.put(category.id, category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    final box = Hive.box<Map>(boxCategories);
    await box.delete(id);
  }

  // --- Suppliers ---
  List<Supplier> getSuppliers() {
    final box = Hive.box<Map>(boxSuppliers);
    return box.values
        .map((e) => Supplier.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveSupplier(Supplier supplier) async {
    final box = Hive.box<Map>(boxSuppliers);
    await box.put(supplier.id, supplier.toMap());
  }

  Future<void> deleteSupplier(String id) async {
    final box = Hive.box<Map>(boxSuppliers);
    await box.delete(id);
  }

  // --- Shopping Lists (Carts) ---
  List<ShoppingList> getShoppingLists() {
    final box = Hive.box<Map>(boxShoppingLists);
    return box.values
        .map((e) => ShoppingList.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveShoppingList(ShoppingList list) async {
    final box = Hive.box<Map>(boxShoppingLists);
    await box.put(list.id, list.toMap());
  }

  Future<void> deleteShoppingList(String id) async {
    final box = Hive.box<Map>(boxShoppingLists);
    await box.delete(id);
  }

  // --- Cart Items ---
  List<CartItem> getCartItems() {
    final box = Hive.box<Map>(boxCartItems);
    return box.values
        .map((e) => CartItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveCartItem(CartItem item) async {
    final box = Hive.box<Map>(boxCartItems);
    await box.put(item.id, item.toMap());
  }

  Future<void> deleteCartItem(String id) async {
    final box = Hive.box<Map>(boxCartItems);
    await box.delete(id);
  }

  Future<void> deleteCartItemsByListId(String listId) async {
    final box = Hive.box<Map>(boxCartItems);
    final items = getCartItems().where((item) => item.listId == listId);
    for (var item in items) {
      await box.delete(item.id);
    }
  }
}
