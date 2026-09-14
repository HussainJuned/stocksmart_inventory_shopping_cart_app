import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../constants.dart';
import '../models/shopping_list_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/cart_search_modal.dart';

enum _GroupBy { supplier, category }

class CartDetailsScreen extends StatefulWidget {
  final String listId;
  const CartDetailsScreen({super.key, required this.listId});

  @override
  State<CartDetailsScreen> createState() => _CartDetailsScreenState();
}

class _CartDetailsScreenState extends State<CartDetailsScreen> {
  _GroupBy _groupBy = _GroupBy.supplier;

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    ShoppingList? currentList;
    try {
      currentList = cartProvider.lists.firstWhere((l) => l.id == widget.listId);
    } catch (_) {
      currentList = null;
    }
    final isArchived = currentList?.status == CartStatus.archived;

    final items = cartProvider.getItemsForList(widget.listId);

    // ── Supplier helpers ────────────────────────────────────────────────────
    String getSupplierName(String id) {
      if (id == 'unknown') return 'No Supplier';
      try {
        return inventoryProvider.suppliers.firstWhere((s) => s.id == id).name;
      } catch (_) {
        return 'Unknown Supplier';
      }
    }

    // ── Category helpers ────────────────────────────────────────────────────
    String getCategoryName(String id) {
      if (id == 'uncategorized') return 'Uncategorized';
      try {
        return inventoryProvider.categories.firstWhere((c) => c.id == id).name;
      } catch (_) {
        return 'Unknown Category';
      }
    }

    Color getCategoryColor(String id) {
      if (id == 'uncategorized') return Colors.grey;
      try {
        final hex = inventoryProvider.categories
            .firstWhere((c) => c.id == id)
            .color
            .replaceFirst('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {
        return Colors.orange;
      }
    }

    // ── Build grouped data based on mode ────────────────────────────────────
    final Map<String, List<CartItem>> groupedItems = {};
    List<String> sortedKeys;

    if (_groupBy == _GroupBy.supplier) {
      for (var item in items) {
        final key = item.supplierId ?? 'unknown';
        groupedItems.putIfAbsent(key, () => []).add(item);
      }
      sortedKeys = groupedItems.keys.toList()
        ..sort((a, b) {
          if (a == 'unknown') return 1;
          if (b == 'unknown') return -1;
          return getSupplierName(a).compareTo(getSupplierName(b));
        });
    } else {
      for (var cartItem in items) {
        String key = 'uncategorized';
        try {
          final gi = inventoryProvider.items.firstWhere(
            (i) => i.id == cartItem.itemId,
          );
          if (gi.categoryIds.isNotEmpty) key = gi.categoryIds.first;
        } catch (_) {}
        groupedItems.putIfAbsent(key, () => []).add(cartItem);
      }
      sortedKeys = groupedItems.keys.toList()
        ..sort((a, b) {
          if (a == 'uncategorized') return 1;
          if (b == 'uncategorized') return -1;
          try {
            final orderA = inventoryProvider.categories
                .firstWhere((c) => c.id == a)
                .sortOrder;
            final orderB = inventoryProvider.categories
                .firstWhere((c) => c.id == b)
                .sortOrder;
            return orderA.compareTo(orderB);
          } catch (_) {
            return 0;
          }
        });
    }

    // ── Secondary sort within each group ────────────────────────────────────
    // Grouped by supplier → order items within each group by category sortOrder
    // Grouped by category → order items within each group by supplier name
    int _getCategorySortOrder(CartItem cartItem) {
      try {
        final gi = inventoryProvider.items.firstWhere(
          (i) => i.id == cartItem.itemId,
        );
        if (gi.categoryIds.isEmpty) return 9999;
        return inventoryProvider.categories
            .firstWhere((c) => c.id == gi.categoryIds.first)
            .sortOrder;
      } catch (_) {
        return 9999;
      }
    }

    String _getItemSupplierName(CartItem cartItem) {
      return getSupplierName(cartItem.supplierId ?? 'unknown');
    }

    for (final groupItems in groupedItems.values) {
      if (_groupBy == _GroupBy.supplier) {
        groupItems.sort((a, b) {
          final orderA = _getCategorySortOrder(a);
          final orderB = _getCategorySortOrder(b);
          final cmp = orderA.compareTo(orderB);
          if (cmp != 0) return cmp;
          return a.name.compareTo(b.name);
        });
      } else {
        groupItems.sort((a, b) {
          final cmp = _getItemSupplierName(
            a,
          ).compareTo(_getItemSupplierName(b));
          if (cmp != 0) return cmp;
          return a.name.compareTo(b.name);
        });
      }
    }

    // Pre-compute flat item+sub-header data per group (used by SliverList)
    final flatGroupItems = <String, List<Object>>{};
    for (final key in sortedKeys) {
      final groupItems = groupedItems[key]!;
      final flat = <Object>[];
      String? lastSubKey;
      for (int i = 0; i < groupItems.length; i++) {
        final item = groupItems[i];
        final subKey = _getSubKey(item, inventoryProvider);
        if (subKey != lastSubKey) {
          lastSubKey = subKey;
          flat.add(_SubHeaderData(subKey));
        }
        flat.add(item);
      }
      flatGroupItems[key] = flat;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<_GroupBy>(
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _GroupBy.supplier,
                  icon: Icon(Icons.local_shipping_outlined, size: 16),
                  tooltip: 'Group by supplier',
                ),
                ButtonSegment(
                  value: _GroupBy.category,
                  icon: Icon(Icons.category_outlined, size: 16),
                  tooltip: 'Group by category',
                ),
              ],
              selected: {_groupBy},
              onSelectionChanged: (Set<_GroupBy> selection) {
                setState(() => _groupBy = selection.first);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isArchived
          ? null
          : FloatingActionButton.extended(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => CartSearchModal(listId: widget.listId),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
      body: items.isEmpty
          ? const Center(child: Text('Empty List'))
          : CustomScrollView(
              slivers: [
                for (int gi = 0; gi < sortedKeys.length; gi++) ...[
                  SliverToBoxAdapter(
                    child: _buildGroupHeader(
                      groupIndex: gi,
                      groupKey: sortedKeys[gi],
                      pendingCount: groupedItems[sortedKeys[gi]]!
                          .where((i) => i.state == CartItemState.pending)
                          .length,
                      itemCount: groupedItems[sortedKeys[gi]]!.length,
                      getSupplierName: getSupplierName,
                      getCategoryName: getCategoryName,
                      getCategoryColor: getCategoryColor,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final key = sortedKeys[gi];
                      final entry = flatGroupItems[key]![index];
                      if (entry is _SubHeaderData) {
                        return _buildSubGroupHeader(
                          entry.subKey,
                          getSupplierName,
                          getCategoryName,
                          getCategoryColor,
                        );
                      }
                      final item = entry as CartItem;
                      final isBought = item.state == CartItemState.bought;
                      final isSkipped = item.state == CartItemState.skipped;
                      final isUnavailable =
                          item.state == CartItemState.unavailable;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Dismissible(
                          key: Key(item.id),
                          direction: isArchived
                              ? DismissDirection.none
                              : DismissDirection.horizontal,
                          // Swipe right: toggle bought/pending
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            decoration: BoxDecoration(
                              color: isBought
                                  ? Colors.orange.withOpacity(0.8)
                                  : Colors.green.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              isBought ? Icons.refresh : Icons.check,
                              color: Colors.white,
                            ),
                          ),
                          // Swipe left: delete
                          secondaryBackground: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            if (isArchived) return false;
                            if (direction == DismissDirection.startToEnd) {
                              HapticFeedback.mediumImpact();
                              cartProvider.updateItemState(
                                widget.listId,
                                item.id,
                                isBought
                                    ? CartItemState.pending
                                    : CartItemState.bought,
                              );
                              return false;
                            }
                            return true;
                          },
                          onDismissed: (_) {
                            final removed = item;
                            final messenger = ScaffoldMessenger.of(context);
                            cartProvider.removeItemFromCart(
                              widget.listId,
                              item.id,
                            );
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
                                        child: Text('${removed.name} removed'),
                                      ),
                                    ],
                                  ),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () {
                                      cartProvider.restoreCartItem(removed);
                                    },
                                  ),
                                  duration: kSnackBarDuration,
                                  // Flutter defaults `persist` to true when an
                                  // action is present, which suppresses the
                                  // auto-dismiss timer entirely.
                                  persist: false,
                                ),
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
                                        color: Colors.green.withOpacity(0.05),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: isArchived
                                              ? null
                                              : () {
                                                  HapticFeedback.lightImpact();
                                                  cartProvider.updateItemState(
                                                    widget.listId,
                                                    item.id,
                                                    isBought
                                                        ? CartItemState.pending
                                                        : CartItemState.bought,
                                                  );
                                                },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isBought
                                                    ? Colors.green
                                                    : Colors.white24,
                                                width: 2,
                                              ),
                                              color: isBought
                                                  ? Colors.green.withOpacity(
                                                      0.1,
                                                    )
                                                  : Colors.transparent,
                                            ),
                                            child: Icon(
                                              isBought
                                                  ? Icons.check
                                                  : Icons.circle_outlined,
                                              size: 20,
                                              color: isBought
                                                  ? Colors.green
                                                  : Colors.white24,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isBought || isSkipped
                                                      ? Colors.white38
                                                      : Colors.white,
                                                  decoration:
                                                      (isBought || isSkipped)
                                                      ? TextDecoration
                                                            .lineThrough
                                                      : null,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              GestureDetector(
                                                onTap: () =>
                                                    _showEditStockDialog(
                                                      context,
                                                      inventoryProvider,
                                                      item.itemId,
                                                      item.name,
                                                      item.unit,
                                                    ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.05),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.1),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            'Stock: ${_formatQty(_getCurrentStock(inventoryProvider, item.itemId))}',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                    0.4,
                                                                  ),
                                                              letterSpacing:
                                                                  0.2,
                                                            ),
                                                          ),
                                                          Text(
                                                            item.unit,
                                                            style: TextStyle(
                                                              fontSize: 8,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                    0.25,
                                                                  ),
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
                                        ),
                                        _buildCartStepper(
                                          context,
                                          cartProvider,
                                          item,
                                          enabled: !isArchived,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: flatGroupItems[sortedKeys[gi]]!.length),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 150)),
              ],
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                if (!isArchived) ...[
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
                                  backgroundColor: Colors.white.withOpacity(
                                    0.05,
                                  ),
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
                            Icon(
                              Icons.archive_outlined,
                              size: 18,
                              color: Colors.white.withOpacity(0.7),
                            ),
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
                ],
                Expanded(
                  child: GestureDetector(
                    onTap: () => _shareCart(
                      context,
                      items,
                      getSupplierName,
                      getCategoryName,
                    ),
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
                          Icon(
                            Icons.share_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
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
      ),
    );
  }

  // ── Group header ────────────────────────────────────────────────────────────
  Widget _buildGroupHeader({
    required int groupIndex,
    required String groupKey,
    required int pendingCount,
    required int itemCount,
    required String Function(String) getSupplierName,
    required String Function(String) getCategoryName,
    required Color Function(String) getCategoryColor,
  }) {
    final isCategory = _groupBy == _GroupBy.category;
    final label = isCategory
        ? getCategoryName(groupKey).toUpperCase()
        : getSupplierName(groupKey).toUpperCase();
    final accent = isCategory
        ? getCategoryColor(groupKey)
        : Colors.orange.withOpacity(0.8);

    final badgeText = pendingCount == itemCount
        ? '$itemCount ITEMS'
        : '$pendingCount / $itemCount PENDING';
    final badgeColor = pendingCount < itemCount
        ? Colors.orange.withOpacity(0.7)
        : Colors.white.withOpacity(0.4);

    return Container(
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
          Row(
            children: [
              if (isCategory)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: accent,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Secondary sub-group key ────────────────────────────────────────────────
  String _getSubKey(CartItem item, InventoryProvider inventoryProvider) {
    if (_groupBy == _GroupBy.supplier) {
      try {
        final gi = inventoryProvider.items.firstWhere(
          (i) => i.id == item.itemId,
        );
        return gi.categoryIds.isNotEmpty
            ? gi.categoryIds.first
            : 'uncategorized';
      } catch (_) {
        return 'uncategorized';
      }
    } else {
      return item.supplierId ?? 'unknown';
    }
  }

  // ── Sub-group header ─────────────────────────────────────────────────────────
  Widget _buildSubGroupHeader(
    String subKey,
    String Function(String) getSupplierName,
    String Function(String) getCategoryName,
    Color Function(String) getCategoryColor,
  ) {
    final isCategory = _groupBy == _GroupBy.supplier;
    final label = isCategory
        ? getCategoryName(subKey)
        : getSupplierName(subKey);
    final color = isCategory
        ? getCategoryColor(subKey)
        : Colors.white.withOpacity(0.35);

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 16, top: 10, bottom: 2),
      child: Row(
        children: [
          if (isCategory)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Icon(
                Icons.local_shipping_outlined,
                size: 10,
                color: color,
              ),
            ),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ── Cart stepper ────────────────────────────────────────────────────────────
  Widget _buildCartStepper(
    BuildContext context,
    CartProvider provider,
    CartItem item, {
    required bool enabled,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCartStepButton(
          icon: Icons.remove,
          enabled: enabled,
          onPressed: () {
            final newQty = item.quantityNeeded - 1;
            if (newQty >= 0) {
              provider.updateItemQuantity(item.listId, item.id, newQty);
            }
          },
        ),
        GestureDetector(
          onTap: enabled
              ? () => _showEditQuantityDialog(context, provider, item)
              : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minWidth: 60, minHeight: 44),
            alignment: Alignment.center,
            child: Text(
              _formatQty(item.quantityNeeded),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: enabled ? Colors.white : Colors.white38,
              ),
            ),
          ),
        ),
        _buildCartStepButton(
          icon: Icons.add,
          enabled: enabled,
          onPressed: () {
            provider.updateItemQuantity(
              item.listId,
              item.id,
              item.quantityNeeded + 1,
            );
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

  Widget _buildCartStepButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(enabled ? 0.05 : 0.02),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Colors.white70 : Colors.white24,
        ),
      ),
    );
  }

  void _showEditStockDialog(
    BuildContext context,
    InventoryProvider inventory,
    String itemId,
    String itemName,
    String unit,
  ) {
    final currentStock = _getCurrentStock(inventory, itemId);
    final controller = TextEditingController(text: _formatQty(currentStock));
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );

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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixText: unit,
                suffixStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 14,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'UPDATE STOCK',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditQuantityDialog(
    BuildContext context,
    CartProvider provider,
    CartItem item,
  ) {
    final controller = TextEditingController(
      text: _formatQty(item.quantityNeeded),
    );
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );

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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: () {
                provider.removeItemFromCart(item.listId, item.id);
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
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
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('${item.name} removed from cart'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.redAccent.withOpacity(0.9),
                      duration: kSnackBarDuration,
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixText: item.unit,
                suffixStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 14,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'SAVE',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  double _getCurrentStock(InventoryProvider inventory, String itemId) {
    try {
      return inventory.items.firstWhere((i) => i.id == itemId).currentQuantity;
    } catch (_) {
      return 0;
    }
  }

  // ── Share ───────────────────────────────────────────────────────────────────
  void _shareCart(
    BuildContext context,
    List<CartItem> items,
    String Function(String) getSupplierName,
    String Function(String) getCategoryName,
  ) {
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }

    final inventoryProvider = Provider.of<InventoryProvider>(
      context,
      listen: false,
    );
    final Map<String, List<CartItem>> groupedItems = {};

    if (_groupBy == _GroupBy.supplier) {
      for (var item in items) {
        groupedItems
            .putIfAbsent(item.supplierId ?? 'unknown', () => [])
            .add(item);
      }
    } else {
      for (var cartItem in items) {
        String key = 'uncategorized';
        try {
          final gi = inventoryProvider.items.firstWhere(
            (i) => i.id == cartItem.itemId,
          );
          if (gi.categoryIds.isNotEmpty) key = gi.categoryIds.first;
        } catch (_) {}
        groupedItems.putIfAbsent(key, () => []).add(cartItem);
      }
    }

    final sortedKeys = groupedItems.keys.toList()
      ..sort((a, b) {
        const fallbacks = {'unknown', 'uncategorized'};
        if (fallbacks.contains(a)) return 1;
        if (fallbacks.contains(b)) return -1;
        final nameA = _groupBy == _GroupBy.supplier
            ? getSupplierName(a)
            : getCategoryName(a);
        final nameB = _groupBy == _GroupBy.supplier
            ? getSupplierName(b)
            : getCategoryName(b);
        return nameA.compareTo(nameB);
      });

    // ── Header ─────────────────────────────────────────────────────────────
    final restaurantName =
        Provider.of<AuthProvider>(context, listen: false).user?.displayName ??
        'Order List';
    final now = DateTime.now();
    final dateStr = DateFormat('EEE, dd MMM · HH:mm').format(now);
    final modeLabel = _groupBy == _GroupBy.supplier
        ? 'By Supplier'
        : 'By Category';

    // ── Stats ──────────────────────────────────────────────────────────────
    final boughtCount = items
        .where((i) => i.state == CartItemState.bought)
        .length;
    final pendingCount = items
        .where((i) => i.state == CartItemState.pending)
        .length;
    final skippedCount = items
        .where((i) => i.state == CartItemState.skipped)
        .length;
    final unavailableCount = items
        .where((i) => i.state == CartItemState.unavailable)
        .length;

    // ── Build text ─────────────────────────────────────────────────────────
    final buffer = StringBuffer();

    buffer
      ..writeln('🍜 $restaurantName · Order List')
      ..writeln('📅 $dateStr')
      ..writeln('───────────────────')
      ..writeln();

    // Progress summary
    final summaryParts = <String>[
      if (pendingCount > 0) '🔹 $pendingCount pending',
      if (boughtCount > 0) '✅ $boughtCount bought',
      if (unavailableCount > 0) '❌ $unavailableCount unavailable',
      if (skippedCount > 0) '⏭️ $skippedCount skipped',
    ];
    buffer
      ..writeln(summaryParts.join('  ·  '))
      ..writeln()
      ..writeln('── $modeLabel ──────────────────')
      ..writeln();

    // Groups with sub-groups, stock context and notes
    for (var key in sortedKeys) {
      final groupItems = groupedItems[key]!;
      final groupName = _groupBy == _GroupBy.supplier
          ? getSupplierName(key)
          : getCategoryName(key);
      buffer.writeln('📦 $groupName');

      for (var item in groupItems) {
        final status = item.state == CartItemState.bought
            ? '✅'
            : item.state == CartItemState.skipped
            ? '⏭️'
            : item.state == CartItemState.unavailable
            ? '❌'
            : '🔹';

        // Stock context from inventory
        String stockInfo = '';
        try {
          final gi = inventoryProvider.items.firstWhere(
            (i) => i.id == item.itemId,
          );
          stockInfo =
              '  [stock: ${_formatQty(gi.currentQuantity)} ${item.unit}]';
        } catch (_) {}

        buffer.writeln(
          '    $status ${item.name}  ×${_formatQty(item.quantityNeeded)} ${item.unit}$stockInfo',
        );

        // Per-item note
        if (item.note != null && item.note!.isNotEmpty) {
          buffer.writeln('       📝 ${item.note}');
        }
      }
      buffer.writeln();
    }

    buffer
      ..writeln('───────────────────')
      ..write('Total: ${items.length} items')
      ..write('  ·  Pending: $pendingCount')
      ..write('  ·  Done: $boughtCount');
    if (unavailableCount > 0)
      buffer.write('  ·  Unavailable: $unavailableCount');
    buffer.writeln();

    final shareText = buffer.toString();

    try {
      Share.share(
        shareText,
        subject:
            '$restaurantName – Order List ${DateFormat('dd MMM').format(now)}',
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('📋 Shopping list copied to clipboard!'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
          duration: kSnackBarDuration,
          persist: false,
        ),
      );
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

// ── Marker for sub-group header rows in flat item lists ──────────────────────
class _SubHeaderData {
  final String subKey;
  const _SubHeaderData(this.subKey);
}
