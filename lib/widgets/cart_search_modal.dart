import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/grocery_item.dart';
import '../providers/cart_provider.dart';
import '../providers/inventory_provider.dart';

class CartSearchModal extends StatefulWidget {
  final String listId;
  const CartSearchModal({super.key, required this.listId});

  @override
  State<CartSearchModal> createState() => _CartSearchModalState();
}

class _CartSearchModalState extends State<CartSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final targetListId = cartProvider.activeCart?.id ?? widget.listId;

    // 1. Filter Logic
    final allItems = inventoryProvider.items.where((i) => i.isActive).toList();
    final cartItems = cartProvider.getItemsForList(targetListId);
    final cartItemIds = cartItems.map((c) => c.itemId).toSet();

    // Suggestions: Low Stock
    final lowStockItems = allItems.where((i) {
      return i.currentQuantity < i.parLevel;
    }).toList();

    // Search Results: Match Name
    final searchResults = allItems.where((i) {
      return i.name.toLowerCase().contains(_searchQuery);
    }).toList();

    // Decide what to show
    final List<GroceryItem> displayList = _searchQuery.isEmpty
        ? lowStockItems
        : searchResults;

    final String title = _searchQuery.isEmpty
        ? 'Low Stock Suggestions'
        : 'All Items';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                if (_searchQuery.isEmpty && lowStockItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text('(None)', style: TextStyle(color: Colors.grey)),
                  ),
              ],
            ),
          ),

          // List Items
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 8,
              ),
              itemCount: displayList.length,
              separatorBuilder: (ctx, i) =>
                  const Divider(height: 1, color: Colors.white10),
              itemBuilder: (context, index) {
                final item = displayList[index];
                final isInCart = cartItemIds.contains(item.id);

                // Calculate default add quantity (Par - Current), min 1
                double quantityToAdd = item.parLevel - item.currentQuantity;
                if (quantityToAdd <= 0) quantityToAdd = 1;

                return ListTile(
                  title: Row(
                    children: [
                      Expanded(child: Text(item.name)),
                      if (isInCart)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.5),
                            ),
                          ),
                          child: const Text(
                            'IN CART',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    'Stock: ${item.currentQuantity} / Par: ${item.parLevel} ${item.unit}',
                    style: TextStyle(
                      color: item.currentQuantity < item.parLevel
                          ? Colors.redAccent
                          : Colors.grey,
                    ),
                  ),
                  trailing: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isInCart
                          ? Colors.green.withOpacity(0.2)
                          : Colors.white10,
                      foregroundColor: isInCart ? Colors.green : Colors.white,
                      elevation: 0,
                    ),
                    icon: Icon(isInCart ? Icons.check : Icons.add, size: 18),
                    label: Text(
                      isInCart
                          ? 'Add More'
                          : '${quantityToAdd.toStringAsFixed(0)} ${item.unit}',
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final activeCart = cartProvider.activeCart;
                      final existingItem = activeCart != null
                          ? cartProvider.findCartItem(activeCart.id, item.id)
                          : null;
                      await cartProvider.addItemToCart(item.id, quantityToAdd);
                      if (!context.mounted) return;
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                InkWell(
                                  onTap: messenger.hideCurrentSnackBar,
                                  borderRadius: BorderRadius.circular(99),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.22,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.16,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    existingItem == null
                                        ? '${item.name} added to cart'
                                        : '${item.name} quantity updated',
                                  ),
                                ),
                              ],
                            ),
                            duration: kSnackBarDuration,
                            persist: false,
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                if (existingItem == null) {
                                  final activeCartAfterAdd =
                                      cartProvider.activeCart;
                                  final addedItem = activeCartAfterAdd != null
                                      ? cartProvider.findCartItem(
                                          activeCartAfterAdd.id,
                                          item.id,
                                        )
                                      : null;
                                  if (addedItem != null) {
                                    cartProvider.removeItemFromCart(
                                      addedItem.listId,
                                      addedItem.id,
                                    );
                                  }
                                } else {
                                  cartProvider.restoreCartItemSnapshot(
                                    existingItem,
                                  );
                                }
                              },
                            ),
                          ),
                        );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
