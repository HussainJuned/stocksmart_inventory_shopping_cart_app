import 'dart:async';
import '../models/grocery_item.dart';
import '../models/category_model.dart';
import '../models/supplier_model.dart';
import '../services/firestore_service.dart';
import '../services/hive_service.dart';

class GroceryRepository {
  final HiveService _hiveService;
  final FirestoreService? _firestoreService; // Null if offline/not logged in
  final List<StreamSubscription> _subscriptions = [];
  final void Function()? onSyncUpdated;

  GroceryRepository(this._hiveService, this._firestoreService, {this.onSyncUpdated});

  // Initialize
  Future<void> init() async {
    await _hiveService.init();
    // If online, start syncing
    if (_firestoreService != null) {
      _syncFromRemote();
    }
  }

  // --- Read (Local First) ---
  List<GroceryItem> getItems() {
    return _hiveService.getItems();
  }

  // --- Write (Local + Remote) ---
  Future<void> addItem(GroceryItem item) async {
    // 1. Save Local
    await _hiveService.saveItem(item);
    // 2. Sync Remote (Fire & Forget or Await based on need)
    _firestoreService?.saveItem(item);
  }

  Future<void> updateItem(GroceryItem item) async {
    final updated = item.copyWith(lastUpdated: DateTime.now());
    await _hiveService.saveItem(updated);
    _firestoreService?.saveItem(updated);
  }

  Future<void> deleteItem(String id) async {
    await _hiveService.deleteItem(id);
    _firestoreService?.deleteItem(id);
  }

  // --- Sync Logic ---
  void _syncFromRemote() {
    final service = _firestoreService;
    if (service == null) return;

    _subscriptions.add(service.getItemsStream().listen((remoteItems) async {
      final localItems = _hiveService.getItems();
      final remoteIds = remoteItems.map((i) => i.id).toSet();
      
      // 1. Delete local items that are no longer in remote
      for (final localItem in localItems) {
        if (!remoteIds.contains(localItem.id)) {
          await _hiveService.deleteItem(localItem.id);
        }
      }
      // 2. Save/Update remote items
      for (var remoteItem in remoteItems) {
        await _hiveService.saveItem(remoteItem);
      }
      onSyncUpdated?.call();
    }));

    _subscriptions.add(service.getCategoriesStream().listen((remoteCats) async {
      final localCats = _hiveService.getCategories();
      final remoteIds = remoteCats.map((c) => c.id).toSet();

      for (final localCat in localCats) {
        if (!remoteIds.contains(localCat.id)) {
          await _hiveService.deleteCategory(localCat.id);
        }
      }
      for (var remoteCat in remoteCats) {
        await _hiveService.saveCategory(remoteCat);
      }
      onSyncUpdated?.call();
    }));

    _subscriptions.add(service.getSuppliersStream().listen((remoteSups) async {
      final localSups = _hiveService.getSuppliers();
      final remoteIds = remoteSups.map((s) => s.id).toSet();

      for (final localSup in localSups) {
        if (!remoteIds.contains(localSup.id)) {
          await _hiveService.deleteSupplier(localSup.id);
        }
      }
      for (var remoteSup in remoteSups) {
        await _hiveService.saveSupplier(remoteSup);
      }
      onSyncUpdated?.call();
    }));
  }

  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
  }

  // --- Categories ---
  List<Category> getCategories() {
    return _hiveService.getCategories();
  }

  Future<void> addCategory(Category category) async {
    await _hiveService.saveCategory(category);
    _firestoreService?.saveCategory(category);
  }

  Future<void> updateCategory(Category category) async {
    await _hiveService.saveCategory(category);
    _firestoreService?.saveCategory(category);
  }

  Future<void> deleteCategory(String id) async {
    await _hiveService.deleteCategory(id);
    _firestoreService?.deleteCategory(id);
  }

  // --- Suppliers ---
  List<Supplier> getSuppliers() {
    return _hiveService.getSuppliers();
  }

  Future<void> addSupplier(Supplier supplier) async {
    await _hiveService.saveSupplier(supplier);
    _firestoreService?.saveSupplier(supplier);
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await _hiveService.saveSupplier(supplier);
    _firestoreService?.saveSupplier(supplier);
  }

  Future<void> deleteSupplier(String id) async {
    await _hiveService.deleteSupplier(id);
    _firestoreService?.deleteSupplier(id);
  }

  Future<void> clearAllData() async {
    await _hiveService.clearAll();
    await _firestoreService?.clearAllData();
  }
}
