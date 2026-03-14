import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/grocery_item.dart';
import '../providers/inventory_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/add_item_modal.dart';

class ItemTile extends StatelessWidget {
  final GroceryItem item;
  final int? index;

  const ItemTile({super.key, required this.item, this.index});

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context, listen: false);
    final isLowStock = item.currentQuantity < item.parLevel;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF2C2C2E), // Dark card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isLowStock
            ? const BorderSide(color: Colors.redAccent, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Column (flex 2): Item Icon - vertically centered
            Expanded(
              flex: 2,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => AddItemModal(itemToEdit: item),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 22,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Middle Column (flex 8): Item Name + Par Level + In Stock
            Expanded(
              flex: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Item Name
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Par Level and In Stock Row
                  Row(
                    children: [
                      // Par Level
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Par Level',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.parLevel.toStringAsFixed(0)} ${item.unit}',
                              style: TextStyle(
                                color: isLowStock
                                    ? Colors.redAccent
                                    : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // In Stock Stepper
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'In Stock',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildStepper(context, item, inventory),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right Column (flex 2): Add to Cart Button - vertically centered
            Expanded(
              flex: 2,
              child: Consumer<CartProvider>(
                builder: (context, cart, child) {
                  bool isInCart = false;
                  if (cart.lists.isNotEmpty) {
                    final activeListId = cart.lists.first.id;
                    final items = cart.getItemsForList(activeListId);
                    isInCart = items.any((i) => i.itemId == item.id);
                  }

                  return Align(
                    alignment: Alignment.center,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showAddToCartDialog(context, cart, item),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isInCart
                                ? Colors.green.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isInCart
                                ? Icons.shopping_cart_checkout
                                : Icons.add_shopping_cart_outlined,
                            size: 26,
                            color: isInCart ? Colors.green : Colors.greenAccent,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Optional: Drag Handle Column (flex 1)
            if (index != null)
              Expanded(
                flex: 1,
                child: ReorderableDragStartListener(
                  index: index!,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.drag_handle,
                      color: Colors.white30,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddToCartDialog(
    BuildContext context,
    CartProvider cart,
    GroceryItem item,
  ) {
    final controller = TextEditingController(text: '1.0');
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          void _adjust(double delta) {
            final current = double.tryParse(controller.text) ?? 0.0;
            final next = (current + delta);
            if (next >= 0) {
              controller.text = next.toStringAsFixed(1);
            }
          }

          return AlertDialog(
            title: Text('Add ${item.name} to Cart'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter quantity to order:'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                      onPressed: () => _adjust(-1.0),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        autofocus: true,
                        decoration: InputDecoration(
                          suffixText: item.unit,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                      onPressed: () => _adjust(1.0),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final qty = double.tryParse(controller.text);
                  if (qty != null && qty > 0) {
                    cart.addItemToCart(item.id, qty);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${item.name} added/updated: ${qty} ${item.unit}',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add to Cart'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepper(
    BuildContext context,
    GroceryItem item,
    InventoryProvider inventory,
  ) {
    // Controller initialized with current value.
    // Note: Creating controller in build method is efficient enough for this small widgets in listviews
    // but ideally we should be careful. Since this is a stateless widget, we'll use a local Key or
    // rely on the fact that if user types, we update provider.
    // Better approach for inputs in list view: Use a generic StatelessWidget but with a text field
    // that updates onSubmitted or lost focus.

    // Simplest reliable way for stateless item:
    // Use a TextEditingController that we don't dispose (anti-pattern) OR
    // better: make this part a StatefulWidget or just use a custom input widget.
    // Let's make a small helper widget to handle the input state.
    return _QuantityInput(item: item, inventory: inventory);
  }
}

class _QuantityInput extends StatefulWidget {
  final GroceryItem item;
  final InventoryProvider inventory;
  const _QuantityInput({required this.item, required this.inventory});

  @override
  State<_QuantityInput> createState() => _QuantityInputState();
}

class _QuantityInputState extends State<_QuantityInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.item.currentQuantity.toStringAsFixed(0),
    );
  }

  @override
  void didUpdateWidget(_QuantityInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.currentQuantity != widget.item.currentQuantity) {
      // Create a new controller or update text if external change happened (e.g. +/- buttons)
      // Only update if not focused to avoid overwriting user while typing?
      // For now, let's keep it simple: sync if value mismatch.
      final textVal = double.tryParse(_controller.text) ?? 0;
      if (textVal != widget.item.currentQuantity) {
        _controller.text = widget.item.currentQuantity.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    // Unfocus to hide keyboard/cursor
    FocusScope.of(context).unfocus();

    final newQty = double.tryParse(value);
    if (newQty != null && newQty >= 0) {
      widget.inventory.updateItemQuantity(widget.item.id, newQty);
    } else {
      // Revert if invalid
      _controller.text = widget.item.currentQuantity.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.orange, size: 16),
            padding: const EdgeInsets.all(2),
            constraints: const BoxConstraints(),
            onPressed: () {
              final newQty = widget.item.currentQuantity - 1;
              if (newQty >= 0)
                widget.inventory.updateItemQuantity(widget.item.id, newQty);
            },
          ),
          SizedBox(
            width: 32,
            child: TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: _submit,
              onTapOutside: (_) => _submit(_controller.text),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.orange, size: 16),
            padding: const EdgeInsets.all(2),
            constraints: const BoxConstraints(),
            onPressed: () {
              widget.inventory.updateItemQuantity(
                widget.item.id,
                widget.item.currentQuantity + 1,
              );
            },
          ),
        ],
      ),
    );
  }
}
