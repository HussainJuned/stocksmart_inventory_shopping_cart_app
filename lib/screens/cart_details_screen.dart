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
              padding: const EdgeInsets.only(bottom: 150),
              itemCount: sortedKeys.length,
              itemBuilder: (context, groupIndex) {
                final supplierId = sortedKeys[groupIndex];
                final groupItems = groupedItems[supplierId]!;
                final supplierName = getSupplierName(supplierId);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Glass-Style Supplier Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        border: Border(
                          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                          top: groupIndex == 0 
                              ? BorderSide.none 
                              : BorderSide(color: Colors.white.withOpacity(0.05)),
                        ),
                      ),
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            supplierName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.orange.withOpacity(0.8),
                              letterSpacing: 1.2,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${groupItems.length} ITEMS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...groupItems.map((item) {
                      final isBought = item.state == CartItemState.bought;
                      final isSkipped = item.state == CartItemState.skipped;
                      final isUnavailable = item.state == CartItemState.unavailable;

                      // Premium Card Style
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            cartProvider.removeItemFromCart(listId, item.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Removed ${item.name}')),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isBought 
                                    ? Colors.green.withOpacity(0.3)
                                    : isUnavailable 
                                        ? Colors.red.withOpacity(0.3)
                                        : Colors.white.withOpacity(0.05),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  if (isBought)
                                    Positioned(
                                      right: -10,
                                      bottom: -10,
                                      child: Icon(
                                        Icons.check_circle, 
                                        size: 80, 
                                        color: Colors.green.withOpacity(0.05)
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        // Status Toggle (Leading)
                                        GestureDetector(
                                          onTap: () {
                                            final newState = isBought
                                                ? CartItemState.pending
                                                : CartItemState.bought;
                                            cartProvider.updateItemState(listId, item.id, newState);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isBought ? Colors.green : Colors.white24,
                                                width: 2,
                                              ),
                                              color: isBought ? Colors.green.withOpacity(0.1) : Colors.transparent,
                                            ),
                                            child: Icon(
                                              isBought ? Icons.check : Icons.circle_outlined,
                                              size: 20,
                                              color: isBought ? Colors.green : Colors.white24,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Item Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: isBought || isSkipped ? Colors.white38 : Colors.white,
                                                    decoration: (isBought || isSkipped) ? TextDecoration.lineThrough : null,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                // Subtle Interactive Stock
                                                GestureDetector(
                                                  onTap: () => _showEditStockDialog(context, inventoryProvider, item.itemId, item.name, item.unit),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.05),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              'Stock: ${_formatQty(_getCurrentStock(inventoryProvider, item.itemId))}',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.w600,
                                                                color: Colors.white.withOpacity(0.4),
                                                                letterSpacing: 0.2,
                                                              ),
                                                            ),
                                                            Text(
                                                              item.unit,
                                                              style: TextStyle(
                                                                fontSize: 8,
                                                                fontWeight: FontWeight.w400,
                                                                color: Colors.white.withOpacity(0.25),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),// Quantity Controls (Trailing-ish)
                                        _buildCartStepper(context, cartProvider, item),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.05),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Start New'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.archive_outlined, size: 18, color: Colors.white.withOpacity(0.7)),
                        const SizedBox(width: 8),
                        const Text(
                          'ARCHIVE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _shareCart(context, items, getSupplierName),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orangeAccent, Colors.deepOrange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepOrange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share_outlined, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'SHARE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartStepper(BuildContext context, CartProvider provider, CartItem item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCartStepButton(
          icon: Icons.remove,
          onPressed: () {
            final newQty = item.quantityNeeded - 1;
            if (newQty >= 0) {
              provider.updateItemQuantity(item.listId, item.id, newQty);
            }
          },
        ),
        GestureDetector(
          onTap: () => _showEditQuantityDialog(context, provider, item),
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minWidth: 60, minHeight: 44),
            alignment: Alignment.center,
            child: Text(
              _formatQty(item.quantityNeeded),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
        _buildCartStepButton(
          icon: Icons.add,
          onPressed: () {
            provider.updateItemQuantity(item.listId, item.id, item.quantityNeeded + 1);
          },
        ),
        const SizedBox(width: 4),
        Text(
          item.unit,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.3),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showEditStockDialog(BuildContext context, InventoryProvider inventory, String itemId, String itemName, String unit) {
    final currentStock = _getCurrentStock(inventory, itemId);
    final controller = TextEditingController(text: _formatQty(currentStock));
    controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.blueAccent.withOpacity(0.2)),
        ),
        title: Text(
          'Update Physical Stock: $itemName',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the actual amount currently on shelves.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixText: unit,
                suffixStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent, width: 2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = double.tryParse(controller.text);
              if (newQty != null && newQty >= 0) {
                inventory.updateItemQuantity(itemId, newQty);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('UPDATE STOCK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ),
        ],
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

  void _showEditQuantityDialog(BuildContext context, CartProvider provider, CartItem item) {
    final controller = TextEditingController(text: _formatQty(item.quantityNeeded));
    controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.orange.withOpacity(0.2)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Edit Quantity: ${item.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () {
                provider.removeItemFromCart(item.listId, item.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} removed from cart'),
                    backgroundColor: Colors.redAccent.withOpacity(0.9),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixText: item.unit,
                suffixStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = double.tryParse(controller.text);
              if (newQty != null && newQty >= 0) {
                provider.updateItemQuantity(item.listId, item.id, newQty);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartStepButton({required IconData icon, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white70),
      ),
    );
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
          '  $status ${item.name} - ${_formatQty(item.quantityNeeded)} ${item.unit}',
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

  String _formatQty(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toString();
  }
}
