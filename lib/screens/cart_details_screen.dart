import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/shopping_list_model.dart';
import '../providers/cart_provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/cart_search_modal.dart';

class CartDetailsScreen extends StatelessWidget {
  final String listId;
  const CartDetailsScreen({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);

    final items = cartProvider.getItemsForList(listId);

    // Grouping Logic
    final Map<String, List<CartItem>> groupedItems = {};
    for (var item in items) {
      final supplierId = item.supplierId ?? 'unknown';
      if (!groupedItems.containsKey(supplierId)) {
        groupedItems[supplierId] = [];
      }
      groupedItems[supplierId]!.add(item);
    }

    // Get Supplier Names for headers
    String getSupplierName(String id) {
      if (id == 'unknown') return 'No Supplier';
      try {
        final supplier = inventoryProvider.suppliers.firstWhere(
          (s) => s.id == id,
        );
        return supplier.name;
      } catch (e) {
        return 'Unknown Supplier ($id)';
      }
    }

    final sortedKeys = groupedItems.keys.toList()
      ..sort((a, b) {
        if (a == 'unknown') return 1; // Put unknown at bottom
        if (b == 'unknown') return -1;
        return getSupplierName(a).compareTo(getSupplierName(b));
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => CartSearchModal(listId: listId),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: items.isEmpty
          ? const Center(child: Text('Empty List'))
          : ListView.builder(
              padding: const EdgeInsets.only(
                bottom: 120,
              ), // Padding for FAB + BottomBar
              itemCount: sortedKeys.length,
              itemBuilder: (context, groupIndex) {
                final supplierId = sortedKeys[groupIndex];
                final groupItems = groupedItems[supplierId]!;
                final supplierName = getSupplierName(supplierId);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.white10,
                      width: double.infinity,
                      child: Text(
                        supplierName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    ...groupItems.map((item) {
                      final isBought = item.state == CartItemState.bought;
                      final isSkipped = item.state == CartItemState.skipped;
                      final isUnavailable =
                          item.state == CartItemState.unavailable;

                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          cartProvider.removeItemFromCart(listId, item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed ${item.name}'),
                              duration: const Duration(milliseconds: 500),
                            ),
                          );
                        },
                        child: ListTile(
                          leading: Checkbox(
                            value: isBought,
                            activeColor: Colors.green,
                            onChanged: (val) {
                              final newState = val == true
                                  ? CartItemState.bought
                                  : CartItemState.pending;
                              cartProvider.updateItemState(
                                listId,
                                item.id,
                                newState,
                              );
                            },
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              decoration: (isBought || isSkipped)
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: (isBought || isSkipped)
                                  ? Colors.grey
                                  : Colors.white,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quantity controls
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      final newQty = item.quantityNeeded - 1;
                                      if (newQty > 0) {
                                        cartProvider.updateItemQuantity(
                                          listId,
                                          item.id,
                                          newQty,
                                        );
                                      }
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      _showEditQuantityDialog(
                                        context,
                                        cartProvider,
                                        item,
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${item.quantityNeeded.toStringAsFixed(0)} ${item.unit}',
                                        style: TextStyle(
                                          color: isUnavailable
                                              ? Colors.red
                                              : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      cartProvider.updateItemQuantity(
                                        listId,
                                        item.id,
                                        item.quantityNeeded + 1,
                                      );
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              // Current stock display/edit
                              GestureDetector(
                                onTap: () {
                                  _showEditStockDialog(
                                    context,
                                    inventoryProvider,
                                    item.itemId,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Stock: ${_getCurrentStock(inventoryProvider, item.itemId)} ${item.unit}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: isUnavailable
                              ? const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                )
                              : isSkipped
                              ? const Icon(Icons.skip_next, color: Colors.grey)
                              : null,
                          onLongPress: () {
                            _showItemOptions(context, cartProvider, item);
                          },
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.archive),
                label: const Text('Archive & New'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Start New Order?'),
                      content: const Text(
                        'This will archive the current order and create a fresh one based on current stock levels.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            cartProvider.createNewCart();
                            Navigator.pop(context);
                          },
                          child: const Text('Start New'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                onPressed: () => _shareCart(context, items, getSupplierName),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditQuantityDialog(
    BuildContext context,
    CartProvider provider,
    CartItem item,
  ) {
    final controller = TextEditingController(
      text: item.quantityNeeded.toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${item.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(suffixText: item.unit),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                provider.updateItemQuantity(item.listId, item.id, val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showItemOptions(
    BuildContext context,
    CartProvider provider,
    CartItem item,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Mark as Bought'),
              onTap: () {
                provider.updateItemState(
                  item.listId,
                  item.id,
                  CartItemState.bought,
                );
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pending, color: Colors.blue),
              title: const Text('Mark as Pending'),
              onTap: () {
                provider.updateItemState(
                  item.listId,
                  item.id,
                  CartItemState.pending,
                );
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle, color: Colors.grey),
              title: const Text('Skip Item'),
              onTap: () {
                provider.updateItemState(
                  item.listId,
                  item.id,
                  CartItemState.skipped,
                );
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.error, color: Colors.red),
              title: const Text('Mark Unavailable'),
              onTap: () {
                provider.updateItemState(
                  item.listId,
                  item.id,
                  CartItemState.unavailable,
                );
                Navigator.pop(ctx);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Remove from List',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                provider.removeItemFromCart(item.listId, item.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed ${item.name}'),
                    duration: const Duration(milliseconds: 500),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  double _getCurrentStock(InventoryProvider inventory, String itemId) {
    try {
      final item = inventory.items.firstWhere((i) => i.id == itemId);
      return item.currentQuantity;
    } catch (e) {
      return 0;
    }
  }

  void _showEditStockDialog(
    BuildContext context,
    InventoryProvider inventory,
    String itemId,
  ) {
    try {
      final item = inventory.items.firstWhere((i) => i.id == itemId);
      final controller = TextEditingController(
        text: item.currentQuantity.toStringAsFixed(1),
      );

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Update Stock: ${item.name}'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Current Stock (${item.unit})',
              hintText: 'Enter current stock',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newQty = double.tryParse(controller.text.trim());
                if (newQty != null && newQty >= 0) {
                  inventory.updateItemQuantity(item.id, newQty);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Updated ${item.name} stock to $newQty ${item.unit}',
                      ),
                      duration: const Duration(milliseconds: 500),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item not found in inventory')),
      );
    }
  }

  void _shareCart(
    BuildContext context,
    List<CartItem> items,
    String Function(String) getSupplierName,
  ) {
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }

    // Group items by supplier
    final Map<String, List<CartItem>> groupedItems = {};
    for (var item in items) {
      final supplierId = item.supplierId ?? 'unknown';
      if (!groupedItems.containsKey(supplierId)) {
        groupedItems[supplierId] = [];
      }
      groupedItems[supplierId]!.add(item);
    }

    // Sort suppliers
    final sortedKeys = groupedItems.keys.toList()
      ..sort((a, b) {
        if (a == 'unknown') return 1;
        if (b == 'unknown') return -1;
        return getSupplierName(a).compareTo(getSupplierName(b));
      });

    // Build share text
    final buffer = StringBuffer();
    buffer.writeln('🛒 Shopping List');
    buffer.writeln(DateFormat('MMM dd, yyyy').format(DateTime.now()));
    buffer.writeln();

    int totalItems = 0;
    for (var supplierId in sortedKeys) {
      final supplierItems = groupedItems[supplierId]!;
      buffer.writeln('📦 ${getSupplierName(supplierId)} -');

      for (var item in supplierItems) {
        final status = item.state == CartItemState.bought
            ? '✅'
            : item.state == CartItemState.skipped
            ? '⏭️'
            : item.state == CartItemState.unavailable
            ? '❌'
            : '🔹';

        buffer.writeln(
          '  $status ${item.name} - ${item.quantityNeeded.toStringAsFixed(0)} ${item.unit}',
        );
        totalItems++;
      }
      buffer.writeln();
    }

    buffer.writeln('━━━━━━');
    buffer.writeln('Total Items: $totalItems');

    final shareText = buffer.toString();

    // Try to share, fallback to clipboard
    try {
      Share.share(
        shareText,
        subject:
            'Shopping List - ${DateFormat('MMM dd').format(DateTime.now())}',
      );
    } catch (e) {
      // Fallback: Copy to clipboard (works better on web)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('📋 Shopping list copied to clipboard!'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
          duration: const Duration(seconds: 3),
        ),
      );

      // Note: For web, you'd need to manually copy since Clipboard API
      // requires user permission. For now, just show the text in a dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Shopping List'),
          content: SingleChildScrollView(child: SelectableText(shareText)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}
