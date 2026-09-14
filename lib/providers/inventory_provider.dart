import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import '../models/grocery_item.dart';
import '../models/category_model.dart';
import '../models/supplier_model.dart';
import '../models/storage_type_model.dart';
import '../repositories/grocery_repository.dart';
import '../services/hive_service.dart';
import '../services/firestore_service.dart';
import '../services/bulk_import_service.dart';

class InventoryProvider extends ChangeNotifier {
  late GroceryRepository _repository;
  List<GroceryItem> _items = [];
  final List<Category> _categories = [];
  final List<Supplier> _suppliers = [];
  final List<StorageType> _storageTypes = [];

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<GroceryItem> get items => _items;
  List<Category> get categories => _categories;
  List<Supplier> get suppliers => _suppliers;
  List<StorageType> get storageTypes => _storageTypes;

  InventoryProvider() {
    // Initial dummy repository, updated via update() in ProxyProvider
    _repository = GroceryRepository(HiveService(), null);
  }

  // Called when Auth changes (ProxyProvider)
  void update(String? userId) {
    // Cancel old Firestore subscriptions before replacing the repository.
    // Without this, stale stream listeners pile up and fight each other.
    _repository.dispose();

    FirestoreService? firestoreService;
    if (userId != null) {
      firestoreService = FirestoreService(userId: userId);
    }

    _repository = GroceryRepository(
      HiveService(),
      firestoreService,
      onSyncUpdated: _fetchLocal,
    );

    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    await _repository.init();
    _fetchLocal();

    // Automatic seeding logic removed as requested by the user.

    _isLoading = false;
    notifyListeners();
  }

  void _fetchLocal() {
    _items = _repository.getItems();
    // Use stable sort
    _items.sort((a, b) {
      int cmp = a.sortOrder.compareTo(b.sortOrder);
      if (cmp == 0) return a.name.compareTo(b.name);
      return cmp;
    });

    _categories.clear();
    _categories.addAll(_repository.getCategories());
    // Sort categories by sortOrder
    _categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    _suppliers.clear();
    _suppliers.addAll(_repository.getSuppliers());

    _storageTypes.clear();
    _storageTypes.addAll(_repository.getStorageTypes());
    _storageTypes.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    notifyListeners();
  }

  Future<void> addItem(GroceryItem item) async {
    await _repository.addItem(item);
    _fetchLocal();
  }

  Future<void> addCategory(String name) async {
    final newCat = Category.create(
      name: name,
      color: '#FF9900',
      sortOrder: _categories.length,
    );
    await _repository.addCategory(newCat);
    _fetchLocal();
  }

  Future<void> updateCategory(Category category) async {
    await _repository.updateCategory(category);
    _fetchLocal();
  }

  Future<void> deleteCategory(String id) async {
    await _repository.deleteCategory(id);
    _fetchLocal();
  }

  Future<void> reorderCategory(int oldIndex, int newIndex) async {
    // ReorderableListView reports newIndex after removal, so adjust
    if (oldIndex < newIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final reordered = List<Category>.from(_categories);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    // Re-assign sequential sortOrder values
    for (int i = 0; i < reordered.length; i++) {
      final cat = reordered[i];
      if (cat.sortOrder != i) {
        final updated = Category(
          id: cat.id,
          name: cat.name,
          color: cat.color,
          sortOrder: i,
        );
        reordered[i] = updated;
        _repository.updateCategory(updated);
      }
    }

    _categories
      ..clear()
      ..addAll(reordered);

    notifyListeners();
  }

  Future<void> updateItemQuantity(String id, double newQty) async {
    final index = _items.indexWhere((i) => i.id == id);
    if (index != -1) {
      final item = _items[index].copyWith(currentQuantity: newQty);
      await _repository.updateItem(item);
      _fetchLocal();

      // Check Par Level Logic could go here (Trigger notification?)
    }
  }

  Future<void> updateItem(GroceryItem item) async {
    await _repository.updateItem(item);
    _fetchLocal();
  }

  Future<void> deleteItem(String id) async {
    await _repository.deleteItem(id);
    _fetchLocal();
  }

  Future<void> reorderItem(
    int oldIndex,
    int newIndex,
    String categoryId,
  ) async {
    final categoryItems = _items
        .where((i) => i.categoryIds.contains(categoryId))
        .toList();

    // Use stable sort to match UI exactly
    categoryItems.sort((a, b) {
      int cmp = a.sortOrder.compareTo(b.sortOrder);
      if (cmp == 0) return a.name.compareTo(b.name);
      return cmp;
    });

    if (oldIndex < 0 || oldIndex >= categoryItems.length) return;

    // Adjust newIndex according to ReorderableListView's quirk
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    if (oldIndex == newIndex) return;

    final itemToMove = categoryItems[oldIndex];
    categoryItems.removeAt(oldIndex);
    categoryItems.insert(newIndex, itemToMove);

    double newSortOrder;
    bool requiresMassUpdate = false;

    if (categoryItems.length == 1) {
      newSortOrder = 0.0;
    } else if (newIndex == 0) {
      // Moved to top
      newSortOrder = categoryItems[1].sortOrder - 1.0;
    } else if (newIndex == categoryItems.length - 1) {
      // Moved to bottom
      newSortOrder = categoryItems[categoryItems.length - 2].sortOrder + 1.0;
    } else {
      // Moved between two items
      final prevOrder = categoryItems[newIndex - 1].sortOrder;
      final nextOrder = categoryItems[newIndex + 1].sortOrder;

      // If the existing sort orders are identical or broken (e.g. freshly imported data),
      // we can't find a midpoint. We must re-index the entire category array.
      if (prevOrder >= nextOrder) {
        requiresMassUpdate = true;
        newSortOrder = 0.0; // arbitrary, will be overwritten
      } else {
        newSortOrder = (prevOrder + nextOrder) / 2.0;
      }
    }

    if (requiresMassUpdate) {
      // Re-normalize all items in this category so future fractions work perfectly
      for (int i = 0; i < categoryItems.length; i++) {
        final updated = categoryItems[i].copyWith(sortOrder: i * 1.0);
        final globalIndex = _items.indexWhere((it) => it.id == updated.id);
        if (globalIndex != -1) _items[globalIndex] = updated;

        // Fire and forget saves
        _repository.updateItem(updated);
      }
    } else {
      // Standard fast fractional update
      final updatedItem = itemToMove.copyWith(sortOrder: newSortOrder);
      final globalIndex = _items.indexWhere((i) => i.id == updatedItem.id);
      if (globalIndex != -1) _items[globalIndex] = updatedItem;

      _repository.updateItem(updatedItem);
    }

    // Re-sort master list and notify UI immediately
    _items.sort((a, b) {
      int cmp = a.sortOrder.compareTo(b.sortOrder);
      if (cmp == 0) return a.name.compareTo(b.name);
      return cmp;
    });

    notifyListeners();
  }

  Future<void> addSupplier(String name) async {
    final newSupplier = Supplier.create(name: name);
    await _repository.addSupplier(newSupplier);
    _fetchLocal();
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await _repository.updateSupplier(supplier);
    _fetchLocal();
  }

  Future<void> deleteSupplier(String id) async {
    await _repository.deleteSupplier(id);
    _fetchLocal();
  }

  Future<void> addStorageType(String name) async {
    final newType = StorageType.create(
      name: name,
      color: '#FF9900',
      sortOrder: _storageTypes.length,
    );
    await _repository.addStorageType(newType);
    _fetchLocal();
  }

  Future<void> updateStorageType(StorageType storageType) async {
    await _repository.updateStorageType(storageType);
    _fetchLocal();
  }

  Future<void> deleteStorageType(String id) async {
    await _repository.deleteStorageType(id);
    _fetchLocal();
  }

  Future<void> reorderStorageType(int oldIndex, int newIndex) async {
    // ReorderableListView reports newIndex after removal, so adjust
    if (oldIndex < newIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final reordered = List<StorageType>.from(_storageTypes);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    // Re-assign sequential sortOrder values
    for (int i = 0; i < reordered.length; i++) {
      final type = reordered[i];
      if (type.sortOrder != i) {
        final updated = StorageType(
          id: type.id,
          name: type.name,
          color: type.color,
          sortOrder: i,
        );
        reordered[i] = updated;
        _repository.updateStorageType(updated);
      }
    }

    _storageTypes
      ..clear()
      ..addAll(reordered);

    notifyListeners();
  }

  Future<void> importFromJson(String jsonString) async {
    final importService = BulkImportService(_repository);
    await importService.importFromJson(jsonString);
    _fetchLocal();
  }

  /// Exports all categories, suppliers, and items to a pretty-printed JSON
  /// string that is fully compatible with the import format.
  String exportToJson() {
    final categoryIdToName = {for (var c in _categories) c.id: c.name};
    final supplierIdToName = {for (var s in _suppliers) s.id: s.name};

    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': _categories
          .map((c) => {'name': c.name, 'color': c.color})
          .toList(),
      'suppliers': _suppliers.map((s) => {'name': s.name}).toList(),
      'items': _items
          .map(
            (item) => {
              'name': item.name,
              'categoryNames': item.categoryIds
                  .map((id) => categoryIdToName[id])
                  .whereType<String>()
                  .toList(),
              'supplierName': item.defaultSupplierId != null
                  ? supplierIdToName[item.defaultSupplierId]
                  : null,
              'unit': item.unit,
              'parLevel': item.parLevel,
              'currentQuantity': item.currentQuantity,
            },
          )
          .toList(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  Future<void> resetEverything() async {
    _isLoading = true;
    notifyListeners();

    await _repository.clearAllData();
    _fetchLocal();

    _isLoading = false;
    notifyListeners();
  }
}
