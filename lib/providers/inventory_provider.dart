import 'package:flutter/foundation.dart' hide Category;
import '../models/grocery_item.dart';
import '../models/category_model.dart';
import '../models/supplier_model.dart';
import '../repositories/grocery_repository.dart';
import '../services/hive_service.dart';
import '../services/firestore_service.dart';
import '../services/bulk_import_service.dart';

class InventoryProvider extends ChangeNotifier {
  late GroceryRepository _repository;
  List<GroceryItem> _items = [];
  final List<Category> _categories = [];
  final List<Supplier> _suppliers = [];

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<GroceryItem> get items => _items;
  List<Category> get categories => _categories;
  List<Supplier> get suppliers => _suppliers;

  InventoryProvider() {
    // Initial dummy repository, updated via update() in ProxyProvider
    _repository = GroceryRepository(HiveService(), null);
  }

  // Called when Auth changes (ProxyProvider)
  void update(String? userId) {
    // If we have a user, we attach Firestore
    FirestoreService? firestoreService;
    if (userId != null) {
      firestoreService = FirestoreService(userId: userId);
    }

    // Create new repo with correct auth context
    _repository = GroceryRepository(
      HiveService(), 
      firestoreService,
      onSyncUpdated: _fetchLocal,
    );

    // Init and fetch
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners(); // Might not be needed to notify here if we want silence
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

  Future<void> reorderItem(int oldIndex, int newIndex, String categoryId) async {
    final categoryItems = _items.where((i) => i.categoryIds.contains(categoryId)).toList();
    
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

  Future<void> importFromJson(String jsonString) async {
    final importService = BulkImportService(_repository);
    await importService.importFromJson(jsonString);
    _fetchLocal();
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
