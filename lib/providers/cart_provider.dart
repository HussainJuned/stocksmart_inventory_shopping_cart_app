import 'dart:async';
import 'package:flutter/material.dart';
import '../models/shopping_list_model.dart';
import '../providers/inventory_provider.dart';
import '../services/hive_service.dart';
import '../services/firestore_service.dart';

class CartProvider extends ChangeNotifier {
  InventoryProvider _inventory;
  final HiveService _hiveService = HiveService();
  FirestoreService? _firestoreService;
  final List<StreamSubscription> _subscriptions = [];
  String? _currentUserId;

  final List<ShoppingList> _lists = [];
  final Map<String, List<CartItem>> _listItems = {}; // listId -> items

  CartProvider(this._inventory) {
    _loadFromHive();
  }

  // Load cart data from Hive
  Future<void> _loadFromHive() async {
    _lists.clear();
    _listItems.clear();

    final allLists = _hiveService.getShoppingLists();
    _lists.addAll(allLists);

    final allCartItems = _hiveService.getCartItems();
    for (var item in allCartItems) {
      if (!_listItems.containsKey(item.listId)) {
        _listItems[item.listId] = [];
      }
      _listItems[item.listId]!.add(item);
    }

    notifyListeners();
  }

  void updateAuth(String? userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;

    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    if (userId != null) {
      _firestoreService = FirestoreService(userId: userId);
      _syncFromRemote();
    } else {
      _firestoreService = null;
    }
  }

  void _syncFromRemote() {
    if (_firestoreService == null) return;

    _subscriptions.add(_firestoreService!.getShoppingListsStream().listen(
      (remoteLists) async {
        final localLists = _hiveService.getShoppingLists();
        final remoteIds = remoteLists.map((l) => l.id).toSet();

        for (final localList in localLists) {
          if (!remoteIds.contains(localList.id)) {
            await _hiveService.deleteShoppingList(localList.id);
          }
        }
        for (var list in remoteLists) {
          await _hiveService.saveShoppingList(list);
        }
        _loadFromHive();
      },
      onError: (e) => debugPrint('CartProvider: shopping lists stream error: $e'),
    ));

    _subscriptions.add(_firestoreService!.getCartItemsStream().listen(
      (remoteItems) async {
        final localItems = _hiveService.getCartItems();
        final remoteIds = remoteItems.map((i) => i.id).toSet();

        for (final localItem in localItems) {
          if (!remoteIds.contains(localItem.id)) {
            await _hiveService.deleteCartItem(localItem.id);
          }
        }
        for (var item in remoteItems) {
          await _hiveService.saveCartItem(item);
        }
        _loadFromHive();
      },
      onError: (e) => debugPrint('CartProvider: cart items stream error: $e'),
    ));
  }

  void updateInventory(InventoryProvider newInventory) {
    _inventory = newInventory;

    // Auto-Sync Suppliers for Active Cart
    if (activeCart != null) {
      final items = _listItems[activeCart!.id];
      if (items != null) {
        for (int i = 0; i < items.length; i++) {
          final cartItem = items[i];
          try {
            final inventoryItem = _inventory.items.firstWhere(
              (item) => item.id == cartItem.itemId,
            );
            if (inventoryItem.defaultSupplierId != cartItem.supplierId) {
              items[i] = cartItem.copyWith(
                supplierId: inventoryItem.defaultSupplierId,
              );
              _hiveService.saveCartItem(items[i]); // Persist local
              _firestoreService?.saveCartItem(items[i]); // Persist remote
            }
          } catch (e) {
            // Item might have been deleted from inventory, ignore.
          }
        }
      }
    }
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  List<ShoppingList> get lists => _lists;

  ShoppingList? get activeCart {
    try {
      return _lists.firstWhere((l) => l.status == CartStatus.active);
    } catch (e) {
      return null;
    }
  }

  List<ShoppingList> get archivedLists {
    return _lists.where((l) => l.status == CartStatus.archived).toList();
  }

  List<CartItem> getItemsForList(String listId) {
    return _listItems[listId] ?? [];
  }

  // Create New Cart (Archives old one)
  Future<void> createNewCart() async {
    // 1. Archive current active cart if exists
    if (activeCart != null) {
      await archiveCart(activeCart!.id);
    }

    // 2. Create new active cart
    final newCart = ShoppingList.create();
    _lists.insert(0, newCart);
    _listItems[newCart.id] = [];

    // Save to Hive
    await _hiveService.saveShoppingList(newCart);
    _firestoreService?.saveShoppingList(newCart).catchError(
      (e) => debugPrint('CartProvider: saveShoppingList error: $e'),
    );

    await _loadFromHive();
  }

  Future<void> archiveCart(String cartId) async {
    final index = _lists.indexWhere((l) => l.id == cartId);
    if (index != -1) {
      _lists[index] = _lists[index].copyWith(status: CartStatus.archived);
      await _hiveService.saveShoppingList(_lists[index]);
      _firestoreService?.saveShoppingList(_lists[index]);
      notifyListeners();
    }
  }

  // Manual Add to Cart (Ensures active cart exists)
  Future<void> addItemToCart(String itemId, double quantity) async {
    // 1. Ensure Active Cart
    if (activeCart == null) {
      await createNewCart();
    }

    final cart = activeCart!;
    final item = _inventory.items.firstWhere((i) => i.id == itemId);

    // 2. Ensure the list entry exists (createNewCart or _loadFromHive may have cleared it)
    if (!_listItems.containsKey(cart.id)) {
      _listItems[cart.id] = [];
    }

    final index = _listItems[cart.id]!.indexWhere((i) => i.itemId == itemId);
    if (index != -1) {
      // Update quantity
      final old = _listItems[cart.id]![index];
      _listItems[cart.id]![index] = old.copyWith(
        quantityNeeded: old.quantityNeeded + quantity,
        state: CartItemState.pending,
      );
      await _hiveService.saveCartItem(_listItems[cart.id]![index]);
      _firestoreService?.saveCartItem(_listItems[cart.id]![index]).catchError(
        (e) => debugPrint('CartProvider: saveCartItem error: $e'),
      );
    } else {
      // Add new
      final newCartItem = CartItem.create(
        listId: cart.id,
        itemId: item.id,
        name: item.name,
        supplierId: item.defaultSupplierId,
        quantityNeeded: quantity,
        unit: item.unit,
      );
      await _hiveService.saveCartItem(newCartItem);
      _firestoreService?.saveCartItem(newCartItem).catchError(
        (e) => debugPrint('CartProvider: saveCartItem error: $e'),
      );
    }
    // Reload from Hive so _listItems always reflects persisted state,
    // regardless of any _loadFromHive() calls triggered by stream callbacks
    // that may have run during the awaits above.
    await _loadFromHive();
  }

  void updateItemState(
    String listId,
    String itemId,
    CartItemState newState,
  ) async {
    final items = _listItems[listId];
    if (items != null) {
      final index = items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        items[index] = items[index].copyWith(state: newState);
        await _hiveService.saveCartItem(items[index]);
        _firestoreService?.saveCartItem(items[index]);
        notifyListeners();
      }
    }
  }

  void updateItemQuantity(String listId, String itemId, double newQty) async {
    final items = _listItems[listId];
    if (items != null) {
      final index = items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        items[index] = items[index].copyWith(quantityNeeded: newQty);
        await _hiveService.saveCartItem(items[index]);
        _firestoreService?.saveCartItem(items[index]);
        notifyListeners();
      }
    }
  }

  void removeItemFromCart(String listId, String itemId) async {
    final items = _listItems[listId];
    if (items != null) {
      final removedItem = items.firstWhere((i) => i.id == itemId);
      items.removeWhere((i) => i.id == itemId);
      await _hiveService.deleteCartItem(removedItem.id);
      _firestoreService?.deleteCartItem(removedItem.id);
      notifyListeners();
    }
  }

  Future<void> deleteShoppingList(String listId) async {
    // 1. Remove from local memory
    _lists.removeWhere((l) => l.id == listId);
    final items = _listItems.remove(listId) ?? [];

    // 2. Remove from Hive
    await _hiveService.deleteShoppingList(listId);
    for (var item in items) {
      await _hiveService.deleteCartItem(item.id);
    }

    // 3. Remove from Firestore
    await _firestoreService?.deleteShoppingList(listId);
    for (var item in items) {
      await _firestoreService?.deleteCartItem(item.id);
    }

    notifyListeners();
  }

  Future<void> resetData() async {
    _lists.clear();
    _listItems.clear();
    notifyListeners();
  }
}
