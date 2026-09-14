import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/grocery_item.dart';
import '../providers/inventory_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/settings_provider.dart';
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
          color: isLowStock
              ? Colors.redAccent.withOpacity(0.5)
              : Colors.white.withOpacity(0.05),
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
              // 1. Name & Stock Information (Flexible Center)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name Tappable for Editing
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => AddItemModal(itemToEdit: item),
                        );
                      },
                      child: Text(
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
                    ),
                    const SizedBox(height: 8),
                    // Bottom Row: Stock Controls & Multi-line Unit
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            item.unit,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white.withOpacity(0.2),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Right Actions (Trailing Group - Balanced Anchor)
              SizedBox(
                width: 90,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Premium Cart Button
                    Consumer<CartProvider>(
                      builder: (context, cart, child) {
                        bool isInCart = false;
                        final activeCart = cart.activeCart;
                        if (activeCart != null) {
                          final activeListId = activeCart.id;
                          final items = cart.getItemsForList(activeListId);
                          isInCart = items.any((i) => i.itemId == item.id);
                        }

                        return GestureDetector(
                          onTap: () async {
                            final settings = Provider.of<SettingsProvider>(
                              context,
                              listen: false,
                            );
                            if (settings.showQuantityPopup) {
                              _showAddToCartDialog(context, cart, item);
                            } else {
                              final messenger = ScaffoldMessenger.of(context);
                              final activeCart = cart.activeCart;
                              final existingItem = activeCart != null
                                  ? cart.findCartItem(activeCart.id, item.id)
                                  : null;
                              await cart.addItemToCart(item.id, 1.0);
                              if (!context.mounted) return;
                              _showCartSnackBar(
                                messenger,
                                existingItem == null
                                    ? '${item.name} added to cart'
                                    : '${item.name} quantity updated',
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () {
                                    if (existingItem == null) {
                                      final activeCartAfterAdd =
                                          cart.activeCart;
                                      final addedItem =
                                          activeCartAfterAdd != null
                                          ? cart.findCartItem(
                                              activeCartAfterAdd.id,
                                              item.id,
                                            )
                                          : null;
                                      if (addedItem != null) {
                                        cart.removeItemFromCart(
                                          addedItem.listId,
                                          addedItem.id,
                                        );
                                      }
                                    } else {
                                      cart.restoreCartItemSnapshot(
                                        existingItem,
                                      );
                                    }
                                  },
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isInCart
                                    ? [
                                        Colors.greenAccent,
                                        Colors.green.shade700,
                                      ]
                                    : [Colors.orangeAccent, Colors.deepOrange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isInCart
                                              ? Colors.greenAccent
                                              : Colors.orangeAccent)
                                          .withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              isInCart
                                  ? Icons.check_circle
                                  : Icons.add_shopping_cart,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    // Drag Handle
                    if (index != null)
                      ReorderableDragStartListener(
                        index: index!,
                        child: Icon(
                          Icons.drag_handle,
                          color: Colors.white.withOpacity(0.15),
                          size: 24,
                        ),
                      ),
                  ],
                ),
              ),
            ],
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
    final parentContext = context;
    final messenger = ScaffoldMessenger.of(context);
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
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.orange,
                      ),
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
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.orange,
                      ),
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
                onPressed: () async {
                  final qty = double.tryParse(controller.text);
                  if (qty != null && qty > 0) {
                    final activeCart = cart.activeCart;
                    final existingItem = activeCart != null
                        ? cart.findCartItem(activeCart.id, item.id)
                        : null;
                    await cart.addItemToCart(item.id, qty);
                    Navigator.pop(ctx);
                    if (!parentContext.mounted) return;
                    _showCartSnackBar(
                      messenger,
                      existingItem == null
                          ? '${item.name} added: $qty ${item.unit}'
                          : '${item.name} updated: +$qty ${item.unit}',
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          if (existingItem == null) {
                            final activeCartAfterAdd = cart.activeCart;
                            final addedItem = activeCartAfterAdd != null
                                ? cart.findCartItem(
                                    activeCartAfterAdd.id,
                                    item.id,
                                  )
                                : null;
                            if (addedItem != null) {
                              cart.removeItemFromCart(
                                addedItem.listId,
                                addedItem.id,
                              );
                            }
                          } else {
                            cart.restoreCartItemSnapshot(existingItem);
                          }
                        },
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
    return _QuantityInput(item: item, inventory: inventory);
  }

  void _showCartSnackBar(
    ScaffoldMessengerState messenger,
    String message, {
    SnackBarAction? action,
  }) {
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
                    color: Colors.black.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: const Icon(Icons.close, size: 18, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          duration: kSnackBarDuration,
          // Flutter defaults `persist` to true when an action is present,
          // which suppresses the auto-dismiss timer entirely.
          persist: false,
          action: action,
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
      text: _formatQty(widget.item.currentQuantity),
    );
  }

  String _formatQty(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toString();
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
        _controller.text = _formatQty(widget.item.currentQuantity);
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
      _controller.text = _formatQty(widget.item.currentQuantity);
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
            width: 50,
            alignment: Alignment.center,
            child: TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
            boxShadow: isAdd
                ? [
                    BoxShadow(
                      color: Colors.orangeAccent.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
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
