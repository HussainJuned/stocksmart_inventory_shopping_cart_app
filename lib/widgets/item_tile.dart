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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLowStock ? Colors.redAccent.withOpacity(0.5) : Colors.white.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          if (isLowStock)
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: -2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                child: _buildIconButton(
                  icon: Icons.edit,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AddItemModal(itemToEdit: item),
                    );
                  },
                  color: Colors.white10,
                  iconColor: Colors.white70,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // 2. Main Content (Flexible Center)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name Left-Aligned
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.white.withOpacity(0.95),
                        letterSpacing: 0.5,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 1),
                            blurRadius: 2.0,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Bottom Row: Stock Controls (Start-Aligned)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Current Stock:',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.4),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStepper(context, item, inventory),
                      ],
                    ),
                  ],
                ),
              ),

                // 3. Right Actions (Trailing Group - Fixed Anchor)
              SizedBox(
                width: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Premium Cart Button
                    Consumer<CartProvider>(
                      builder: (context, cart, child) {
                        bool isInCart = false;
                        if (cart.lists.isNotEmpty) {
                          final activeListId = cart.lists.first.id;
                          final items = cart.getItemsForList(activeListId);
                          isInCart = items.any((i) => i.itemId == item.id);
                        }
                        
                        return GestureDetector(
                          onTap: () => _showAddToCartDialog(context, cart, item),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isInCart 
                                  ? [Colors.greenAccent, Colors.green.shade700]
                                  : [Colors.orangeAccent, Colors.deepOrange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isInCart ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              isInCart ? Icons.check_circle : Icons.add_shopping_cart,
                              color: isInCart ? Colors.white : Colors.white,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                    // Drag Handle
                    if (index != null)
                      ReorderableDragStartListener(
                        index: index!,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.drag_handle,
                            color: Colors.white.withOpacity(0.15),
                            size: 22,
                          ),
                        ),
                      ),
                  ],
                ),
              ),            ],
          ),
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

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    Color? iconColor,
    double size = 40,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: size * 0.6,
            color: iconColor,
          ),
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStepButton(
            icon: Icons.remove,
            onPressed: () {
              final newQty = widget.item.currentQuantity - 1;
              if (newQty >= 0)
                widget.inventory.updateItemQuantity(widget.item.id, newQty);
            },
          ),
          Container(
            width: 30,
            alignment: Alignment.center,
            child: TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
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
          _buildStepButton(
            icon: Icons.add,
            onPressed: () {
              widget.inventory.updateItemQuantity(
                widget.item.id,
                widget.item.currentQuantity + 1,
              );
            },
            isAdd: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isAdd = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isAdd ? Colors.orangeAccent : Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: isAdd ? [
              BoxShadow(
                color: Colors.orangeAccent.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              )
            ] : null,
          ),
          child: Icon(
            icon,
            color: isAdd ? Colors.black : Colors.white,
            size: 14,
          ),
        ),
      ),
    );
  }
}
