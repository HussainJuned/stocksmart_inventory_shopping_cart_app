import 'package:hive_flutter/hive_flutter.dart';
import '../models/grocery_item.dart';
import '../models/category_model.dart';
import '../models/supplier_model.dart';
import '../models/storage_type_model.dart';
import '../models/unit_model.dart';
import '../models/shopping_list_model.dart';

class HiveService {
  static const String boxItems = 'grocery_items';
  static const String boxCategories = 'categories';
  static const String boxSuppliers = 'suppliers';
  static const String boxStorageTypes = 'storage_types';
  static const String boxUnits = 'units';
  static const String boxShoppingLists = 'shopping_lists';
  static const String boxCartItems = 'cart_items';
  static const String boxPreferences = 'preferences';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(boxItems);
    await Hive.openBox<Map>(boxCategories);
    await Hive.openBox<Map>(boxSuppliers);
    await Hive.openBox<Map>(boxStorageTypes);
    await Hive.openBox<Map>(boxUnits);
    await Hive.openBox<Map>(boxShoppingLists);
    await Hive.openBox<Map>(boxCartItems);
    if (!Hive.isBoxOpen(boxPreferences)) {
      await Hive.openBox(boxPreferences);
    }
  }

  Future<void> clearAll() async {
    await Hive.box<Map>(boxItems).clear();
    await Hive.box<Map>(boxCategories).clear();
    await Hive.box<Map>(boxSuppliers).clear();
    await Hive.box<Map>(boxStorageTypes).clear();
    await Hive.box<Map>(boxUnits).clear();
    await Hive.box<Map>(boxShoppingLists).clear();
    await Hive.box<Map>(boxCartItems).clear();
    // Preferences are intentionally not cleared on logout — they are device-level settings.
  }

  // --- Preferences ---
  dynamic getPreference(String key, {dynamic defaultValue}) {
    return Hive.box(boxPreferences).get(key, defaultValue: defaultValue);
  }

  Future<void> setPreference(String key, dynamic value) async {
    await Hive.box(boxPreferences).put(key, value);
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

  // --- Storage Types ---
  List<StorageType> getStorageTypes() {
    final box = Hive.box<Map>(boxStorageTypes);
    return box.values
        .map((e) => StorageType.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveStorageType(StorageType storageType) async {
    final box = Hive.box<Map>(boxStorageTypes);
    await box.put(storageType.id, storageType.toMap());
  }

  Future<void> deleteStorageType(String id) async {
    final box = Hive.box<Map>(boxStorageTypes);
    await box.delete(id);
  }

  // --- Units ---
  List<Unit> getUnits() {
    final box = Hive.box<Map>(boxUnits);
    return box.values
        .map((e) => Unit.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveUnit(Unit unit) async {
    final box = Hive.box<Map>(boxUnits);
    await box.put(unit.id, unit.toMap());
  }

  Future<void> deleteUnit(String id) async {
    final box = Hive.box<Map>(boxUnits);
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
