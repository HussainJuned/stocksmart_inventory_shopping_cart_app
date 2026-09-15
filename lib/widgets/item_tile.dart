import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/grocery_item.dart';
import '../models/shopping_list_model.dart';
import '../providers/inventory_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/add_item_modal.dart';
import '../widgets/avatar_icons.dart';
import '../widgets/quantity_stepper.dart';

class ItemTile extends StatelessWidget {
  final GroceryItem item;
  final int? index;

  const ItemTile({super.key, required this.item, this.index});

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context);
    final activeCart = cart.activeCart;
    final cartItem = activeCart != null
        ? cart.findCartItem(activeCart.id, item.id)
        : null;
    final isInCart = cartItem != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Dismissible(
        key: ValueKey('cart_swipe_${item.id}'),
        direction: isInCart
            ? DismissDirection.horizontal
            : DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            HapticFeedback.mediumImpact();
            await _addToCart(context, item);
          } else if (isInCart) {
            HapticFeedback.mediumImpact();
            await _removeFromCart(context, cart, cartItem);
          }
          return false;
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.orangeAccent, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_shopping_cart, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Add to Cart',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Remove from Cart',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.remove_shopping_cart, color: Colors.white, size: 20),
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isInCart
                ? Color.alphaBlend(
                    Colors.green.withOpacity(0.08),
                    const Color(0xFF1C1C1E),
                  )
                : const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isInCart
                  ? Colors.green.withOpacity(0.35)
                  : Colors.white.withOpacity(0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Letter avatar (leading) — also the drag handle.
                  index != null
                      ? ReorderableDragStartListener(
                          index: index!,
                          child: _buildAvatar(item, isInCart),
                        )
                      : _buildAvatar(item, isInCart),
                  const SizedBox(width: 10),
                  // Name — long-press to edit
                  Expanded(
                    child: GestureDetector(
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
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
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.95),
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.start,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Claim horizontal drags here so the Dismissible above
                  // doesn't compete with taps on the quantity field.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (_) {},
                    onHorizontalDragUpdate: (_) {},
                    onHorizontalDragEnd: (_) {},
                    child: _buildStepper(context, item, inventory),
                  ),
                  const SizedBox(width: 10),
                  _buildUnitPill(item),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context, GroceryItem item) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    if (settings.showQuantityPopup) {
      _showAddToCartDialog(context, cart, item);
      return;
    }

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
            final activeCartAfterAdd = cart.activeCart;
            final addedItem = activeCartAfterAdd != null
                ? cart.findCartItem(activeCartAfterAdd.id, item.id)
                : null;
            if (addedItem != null) {
              cart.removeItemFromCart(addedItem.listId, addedItem.id);
            }
          } else {
            cart.restoreCartItemSnapshot(existingItem);
          }
        },
      ),
    );
  }

  Future<void> _removeFromCart(
    BuildContext context,
    CartProvider cart,
    CartItem cartItem,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    cart.removeItemFromCart(cartItem.listId, cartItem.id);
    if (!context.mounted) return;
    _showCartSnackBar(
      messenger,
      '${item.name} removed from cart',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => cart.restoreCartItemSnapshot(cartItem),
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
    return QuantityStepper(item: item, inventory: inventory);
  }

  Widget _buildUnitPill(GroceryItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        item.unit.toUpperCase(),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: Colors.white.withOpacity(0.45),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(GroceryItem item) {
    final custom = item.avatarIconName;
    if (custom != null) {
      final customIcon = kAvatarIconChoices[custom];
      if (customIcon != null) {
        return Icon(customIcon, size: 18, color: Colors.deepOrange.shade200);
      }
      // Not an icon key — it's a user-picked emoji, stored as the literal
      // character.
      return Text(custom, style: const TextStyle(fontSize: 18));
    }
    final emoji = emojiForItemName(item.name);
    if (emoji != null) {
      return Text(emoji, style: const TextStyle(fontSize: 18));
    }
    return Text(
      initialsForItemName(item.name),
      style: TextStyle(
        color: Colors.deepOrange.shade200,
        fontWeight: FontWeight.w800,
        fontSize: 13,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildAvatar(GroceryItem item, bool isInCart) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isInCart
            ? Colors.green.withOpacity(0.16)
            : Colors.white.withOpacity(0.06),
        border: Border.all(
          color: isInCart
              ? Colors.green.withOpacity(0.4)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: _buildAvatarContent(item),
    );
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
