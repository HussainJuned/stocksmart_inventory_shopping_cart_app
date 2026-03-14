import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grocery_item.dart';
import '../models/category_model.dart';
import '../models/supplier_model.dart';
import '../models/shopping_list_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;

  FirestoreService({required this.userId});

  // --- Items ---
  Stream<List<GroceryItem>> getItemsStream() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('grocery_items')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroceryItem.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> saveItem(GroceryItem item) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('grocery_items')
        .doc(item.id)
        .set(item.toMap());
  }

  Future<void> deleteItem(String itemId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('grocery_items')
        .doc(itemId)
        .delete();
  }

  // --- Categories ---
  Stream<List<Category>> getCategoriesStream() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Category.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> saveCategory(Category category) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(category.id)
        .set(category.toMap());
  }

  Future<void> deleteCategory(String categoryId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }

  // --- Suppliers ---
  Stream<List<Supplier>> getSuppliersStream() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('suppliers')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Supplier.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> saveSupplier(Supplier supplier) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('suppliers')
        .doc(supplier.id)
        .set(supplier.toMap());
  }

  Future<void> deleteSupplier(String supplierId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('suppliers')
        .doc(supplierId)
        .delete();
  }

  // --- Shopping Lists ---
  Stream<List<ShoppingList>> getShoppingListsStream() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('shopping_lists')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ShoppingList.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> saveShoppingList(ShoppingList list) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('shopping_lists')
        .doc(list.id)
        .set(list.toMap());
  }

  Future<void> deleteShoppingList(String listId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('shopping_lists')
        .doc(listId)
        .delete();
  }

  // --- Cart Items ---
  Stream<List<CartItem>> getCartItemsStream() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('cart_items')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CartItem.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> saveCartItem(CartItem item) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('cart_items')
        .doc(item.id)
        .set(item.toMap());
  }

  Future<void> deleteCartItem(String itemId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('cart_items')
        .doc(itemId)
        .delete();
  }
}
