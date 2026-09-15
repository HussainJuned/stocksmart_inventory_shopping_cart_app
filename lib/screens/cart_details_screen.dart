import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../constants.dart';
import '../models/grocery_item.dart';
import '../models/shopping_list_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/cart_search_modal.dart';
import '../widgets/quantity_stepper.dart';

enum _GroupBy { supplier, category, storageType }

class CartDetailsScreen extends StatefulWidget {
  final String listId;
  const CartDetailsScreen({super.key, required this.listId});

  @override
  State<CartDetailsScreen> createState() => _CartDetailsScreenState();
}

class _CartDetailsScreenState extends State<CartDetailsScreen> {
  _GroupBy _groupBy = _GroupBy.supplier;
  // null = no secondary (sub-)grouping.
  _GroupBy? _secondaryGroupBy;
  // PopupMenuButton treats a selected item's `value` of literal `null` the
  // same as the menu being dismissed without a selection, so `onSelected`
  // never fires for it. Use this sentinel instead for the "none" item.
  static const Object _noSecondaryGroupBy = Object();

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

    // ── Storage Type helpers ────────────────────────────────────────────────
    String getStorageTypeName(String id) {
      if (id == 'unassigned') return 'Unassigned';
      try {
        return inventoryProvider.storageTypes
            .firstWhere((t) => t.id == id)
            .name;
      } catch (_) {
        return 'Unknown Storage Type';
      }
    }

    Color getStorageTypeColor(String id) {
      if (id == 'unassigned') return Colors.grey;
      try {
        final hex = inventoryProvider.storageTypes
            .firstWhere((t) => t.id == id)
            .color
            .replaceFirst('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {
        return Colors.amber;
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
    } else if (_groupBy == _GroupBy.category) {
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
    } else {
      for (var cartItem in items) {
        String key = 'unassigned';
        try {
          final gi = inventoryProvider.items.firstWhere(
            (i) => i.id == cartItem.itemId,
          );
          if (gi.storageTypeId != null) key = gi.storageTypeId!;
        } catch (_) {}
        groupedItems.putIfAbsent(key, () => []).add(cartItem);
      }
      sortedKeys = groupedItems.keys.toList()
        ..sort((a, b) {
          if (a == 'unassigned') return 1;
          if (b == 'unassigned') return -1;
          try {
            final orderA = inventoryProvider.storageTypes
                .firstWhere((t) => t.id == a)
                .sortOrder;
            final orderB = inventoryProvider.storageTypes
                .firstWhere((t) => t.id == b)
                .sortOrder;
            return orderA.compareTo(orderB);
          } catch (_) {
            return 0;
          }
        });
    }

    // Sort items within each group, then (if a secondary grouping is set)
    // interleave sub-group headers into a flat per-group render list.
    final flatGroupItems = <String, List<Object>>{};
    for (final key in sortedKeys) {
      final groupItems = groupedItems[key]!;
      final subDim = _secondaryGroupBy;

      if (subDim == null) {
        groupItems.sort((a, b) => a.name.compareTo(b.name));
        flatGroupItems[key] = groupItems;
        continue;
      }

      groupItems.sort((a, b) {
        final subKeyA = _rawKeyFor(subDim, a, inventoryProvider);
        final subKeyB = _rawKeyFor(subDim, b, inventoryProvider);
        final orderA = _sortOrderFor(subDim, subKeyA, inventoryProvider);
        final orderB = _sortOrderFor(subDim, subKeyB, inventoryProvider);
        final cmp = orderA != null && orderB != null
            ? orderA.compareTo(orderB)
            : _displayNameFor(
                subDim,
                subKeyA,
                getSupplierName,
                getCategoryName,
                getStorageTypeName,
              ).compareTo(
                _displayNameFor(
                  subDim,
                  subKeyB,
                  getSupplierName,
                  getCategoryName,
                  getStorageTypeName,
                ),
              );
        if (cmp != 0) return cmp;
        return a.name.compareTo(b.name);
      });

      final flat = <Object>[];
      String? lastSubKey;
      for (final item in groupItems) {
        final subKey = _rawKeyFor(subDim, item, inventoryProvider);
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
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: SegmentedButton<_GroupBy>(
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: WidgetStateProperty.all(BorderSide.none),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? Colors.deepOrange
                        : Colors.transparent;
                  }),
                  iconColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? Colors.white
                        : Colors.white54;
                  }),
                ),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: _GroupBy.supplier,
                    icon: Icon(Icons.local_shipping_outlined, size: 18),
                    tooltip: 'Group by supplier',
                  ),
                  ButtonSegment(
                    value: _GroupBy.category,
                    icon: Icon(Icons.category_outlined, size: 18),
                    tooltip: 'Group by category',
                  ),
                  ButtonSegment(
                    value: _GroupBy.storageType,
                    icon: Icon(Icons.inventory_2_outlined, size: 18),
                    tooltip: 'Group by storage type',
                  ),
                ],
                selected: {_groupBy},
                onSelectionChanged: (Set<_GroupBy> selection) {
                  setState(() {
                    _groupBy = selection.first;
                    // A dimension can't be both primary and secondary.
                    if (_secondaryGroupBy == _groupBy) {
                      _secondaryGroupBy = null;
                    }
                  });
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<Object>(
              tooltip: 'Then group by…',
              padding: EdgeInsets.zero,
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _secondaryGroupBy != null
                      ? Colors.deepOrange.withOpacity(0.18)
                      : Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _secondaryGroupBy != null
                        ? Colors.deepOrange.withOpacity(0.5)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Icon(
                  Icons.layers_outlined,
                  size: 17,
                  color: _secondaryGroupBy != null
                      ? Colors.deepOrange
                      : Colors.white70,
                ),
              ),
              onSelected: (value) {
                setState(
                  () => _secondaryGroupBy = value == _noSecondaryGroupBy
                      ? null
                      : value as _GroupBy,
                );
              },
              itemBuilder: (context) => [
                CheckedPopupMenuItem<Object>(
                  value: _noSecondaryGroupBy,
                  checked: _secondaryGroupBy == null,
                  child: const Text('No secondary grouping'),
                ),
                for (final dim in _GroupBy.values)
                  if (dim != _groupBy)
                    CheckedPopupMenuItem<Object>(
                      value: dim,
                      checked: _secondaryGroupBy == dim,
                      child: Text('Then by ${_groupByLabel(dim)}'),
                    ),
              ],
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
                      getStorageTypeName: getStorageTypeName,
                      getStorageTypeColor: getStorageTypeColor,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final key = sortedKeys[gi];
                      final entry = flatGroupItems[key]![index];
                      if (entry is _SubHeaderData) {
                        return _buildSubGroupHeader(
                          _secondaryGroupBy!,
                          entry.subKey,
                          getSupplierName,
                          getCategoryName,
                          getStorageTypeName,
                          getCategoryColor,
                          getStorageTypeColor,
                        );
                      }
                      final item = entry as CartItem;
                      final isBought = item.state == CartItemState.bought;
                      final isSkipped = item.state == CartItemState.skipped;

                      return Dismissible(
                        key: Key(item.id),
                        direction: isArchived
                            ? DismissDirection.none
                            : DismissDirection.horizontal,
                        // Swipe right: toggle bought/pending
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: isBought
                              ? Colors.orange.withOpacity(0.8)
                              : Colors.green.withOpacity(0.8),
                          child: Icon(
                            isBought ? Icons.refresh : Icons.check,
                            color: Colors.white,
                          ),
                        ),
                        // Swipe left: delete
                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.redAccent.withOpacity(0.8),
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
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withOpacity(0.07),
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 14),
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
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isBought
                                                ? Colors.green
                                                : Colors.white24,
                                            width: 2,
                                          ),
                                          color: isBought
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.transparent,
                                        ),
                                        child: Icon(
                                          isBought
                                              ? Icons.check
                                              : Icons.circle_outlined,
                                          size: 24,
                                          color: isBought
                                              ? Colors.green
                                              : Colors.white24,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 32),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            item.name,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: isBought || isSkipped
                                                  ? Colors.white38
                                                  : Colors.white,
                                              decoration:
                                                  (isBought || isSkipped)
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          GestureDetector(
                                            onTap: () => _showEditStockDialog(
                                              context,
                                              inventoryProvider,
                                              item.itemId,
                                              item.name,
                                              item.unit,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.inventory_2_outlined,
                                                  size: 10,
                                                  color: Colors.amber
                                                      .withOpacity(0.55),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Stock: ${_formatQty(_getCurrentStock(inventoryProvider, item.itemId))} ${item.unit}',
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.amber
                                                        .withOpacity(0.55),
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                              ],
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
                      getStorageTypeName,
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
                const SizedBox(width: 12),
                Tooltip(
                  message: 'Copy as text',
                  child: GestureDetector(
                    onTap: () => _copyShareText(
                      context,
                      items,
                      getSupplierName,
                      getCategoryName,
                      getStorageTypeName,
                    ),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.content_copy_outlined,
                        size: 18,
                        color: Colors.white.withOpacity(0.7),
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
    required String Function(String) getStorageTypeName,
    required Color Function(String) getStorageTypeColor,
  }) {
    final showDot =
        _groupBy == _GroupBy.category || _groupBy == _GroupBy.storageType;
    final label = switch (_groupBy) {
      _GroupBy.category => getCategoryName(groupKey).toUpperCase(),
      _GroupBy.storageType => getStorageTypeName(groupKey).toUpperCase(),
      _GroupBy.supplier => getSupplierName(groupKey).toUpperCase(),
    };
    final accent = switch (_groupBy) {
      _GroupBy.category => getCategoryColor(groupKey),
      _GroupBy.storageType => getStorageTypeColor(groupKey),
      _GroupBy.supplier => Colors.orange.withOpacity(0.8),
    };

    final doneCount = itemCount - pendingCount;
    final isComplete = pendingCount == 0;
    final badgeText = pendingCount == itemCount
        ? '$itemCount TO BUY'
        : isComplete
        ? 'ALL DONE'
        : '$doneCount / $itemCount DONE';
    final badgeColor = isComplete
        ? Colors.green
        : doneCount > 0
        ? Colors.orange.withOpacity(0.8)
        : Colors.white.withOpacity(0.45);
    final badgeBg = isComplete
        ? Colors.green.withOpacity(0.12)
        : Colors.white.withOpacity(0.05);

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
              if (showDot)
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
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isComplete) ...[
                  Icon(Icons.check_circle, size: 11, color: badgeColor),
                  const SizedBox(width: 4),
                ],
                Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Cross-dimension grouping helpers ─────────────────────────────────────
  // Shared by the primary grouping pass, the secondary (sub-)grouping pass,
  // and the share-text builder, so all three stay in sync.

  String _fallbackKeyFor(_GroupBy dim) => switch (dim) {
    _GroupBy.supplier => 'unknown',
    _GroupBy.category => 'uncategorized',
    _GroupBy.storageType => 'unassigned',
  };

  String _rawKeyFor(_GroupBy dim, CartItem item, InventoryProvider inv) {
    switch (dim) {
      case _GroupBy.supplier:
        return item.supplierId ?? 'unknown';
      case _GroupBy.category:
        try {
          final gi = inv.items.firstWhere((i) => i.id == item.itemId);
          return gi.categoryIds.isNotEmpty
              ? gi.categoryIds.first
              : 'uncategorized';
        } catch (_) {
          return 'uncategorized';
        }
      case _GroupBy.storageType:
        try {
          final gi = inv.items.firstWhere((i) => i.id == item.itemId);
          return gi.storageTypeId ?? 'unassigned';
        } catch (_) {
          return 'unassigned';
        }
    }
  }

  /// Underlying sortOrder for a key, when the dimension has one (category,
  /// storage type). Null for supplier (and any unresolved key), signalling
  /// callers to fall back to sorting by display name instead.
  int? _sortOrderFor(_GroupBy dim, String key, InventoryProvider inv) {
    switch (dim) {
      case _GroupBy.supplier:
        return null;
      case _GroupBy.category:
        try {
          return inv.categories.firstWhere((c) => c.id == key).sortOrder;
        } catch (_) {
          return null;
        }
      case _GroupBy.storageType:
        try {
          return inv.storageTypes.firstWhere((t) => t.id == key).sortOrder;
        } catch (_) {
          return null;
        }
    }
  }

  String _displayNameFor(
    _GroupBy dim,
    String key,
    String Function(String) getSupplierName,
    String Function(String) getCategoryName,
    String Function(String) getStorageTypeName,
  ) => switch (dim) {
    _GroupBy.supplier => getSupplierName(key),
    _GroupBy.category => getCategoryName(key),
    _GroupBy.storageType => getStorageTypeName(key),
  };

  Color _displayColorFor(
    _GroupBy dim,
    String key,
    Color Function(String) getCategoryColor,
    Color Function(String) getStorageTypeColor,
  ) => switch (dim) {
    _GroupBy.supplier => Colors.white.withOpacity(0.35),
    _GroupBy.category => getCategoryColor(key),
    _GroupBy.storageType => getStorageTypeColor(key),
  };

  String _groupByLabel(_GroupBy dim) => switch (dim) {
    _GroupBy.supplier => 'Supplier',
    _GroupBy.category => 'Category',
    _GroupBy.storageType => 'Storage Type',
  };

  // ── Sub-group header ─────────────────────────────────────────────────────
  Widget _buildSubGroupHeader(
    _GroupBy dimension,
    String subKey,
    String Function(String) getSupplierName,
    String Function(String) getCategoryName,
    String Function(String) getStorageTypeName,
    Color Function(String) getCategoryColor,
    Color Function(String) getStorageTypeColor,
  ) {
    final label = _displayNameFor(
      dimension,
      subKey,
      getSupplierName,
      getCategoryName,
      getStorageTypeName,
    );
    final hasDot = dimension != _GroupBy.supplier;
    final color = _displayColorFor(
      dimension,
      subKey,
      getCategoryColor,
      getStorageTypeColor,
    );

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 16, top: 10, bottom: 2),
      child: Row(
        children: [
          if (hasDot)
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
    return _CartQuantityStepper(
      provider: provider,
      item: item,
      enabled: enabled,
      formatQty: _formatQty,
      onEditQuantity: _showEditQuantityDialog,
    );
  }


  void _showEditStockDialog(
    BuildContext context,
    InventoryProvider inventory,
    String itemId,
    String itemName,
    String unit,
  ) {
    GroceryItem? groceryItem;
    try {
      groceryItem = inventory.items.firstWhere((i) => i.id == itemId);
    } catch (_) {
      groceryItem = null;
    }
    if (groceryItem == null) return;
    final resolvedItem = groceryItem;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.amber.withOpacity(0.2)),
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                QuantityStepper(item: resolvedItem, inventory: inventory),
                const SizedBox(width: 10),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'DONE',
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
  /// Builds the shareable order text. Returns null (and shows a snackbar) if
  /// the cart is empty.
  ({String text, String subject})? _buildShareText(
    BuildContext context,
    List<CartItem> items,
    String Function(String) getSupplierName,
    String Function(String) getCategoryName,
    String Function(String) getStorageTypeName,
  ) {
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return null;
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
    } else if (_groupBy == _GroupBy.category) {
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
    } else {
      for (var cartItem in items) {
        String key = 'unassigned';
        try {
          final gi = inventoryProvider.items.firstWhere(
            (i) => i.id == cartItem.itemId,
          );
          if (gi.storageTypeId != null) key = gi.storageTypeId!;
        } catch (_) {}
        groupedItems.putIfAbsent(key, () => []).add(cartItem);
      }
    }

    final fallbackKey = _fallbackKeyFor(_groupBy);
    final sortedKeys = groupedItems.keys.toList()
      ..sort((a, b) {
        if (a == fallbackKey) return 1;
        if (b == fallbackKey) return -1;
        final nameA = switch (_groupBy) {
          _GroupBy.supplier => getSupplierName(a),
          _GroupBy.category => getCategoryName(a),
          _GroupBy.storageType => getStorageTypeName(a),
        };
        final nameB = switch (_groupBy) {
          _GroupBy.supplier => getSupplierName(b),
          _GroupBy.category => getCategoryName(b),
          _GroupBy.storageType => getStorageTypeName(b),
        };
        return nameA.compareTo(nameB);
      });

    // ── Header ─────────────────────────────────────────────────────────────
    final restaurantName =
        Provider.of<AuthProvider>(context, listen: false).user?.displayName ??
        'Order List';
    final now = DateTime.now();
    final dateStr = DateFormat('EEE, dd MMM · HH:mm').format(now);
    final modeLabel = switch (_groupBy) {
      _GroupBy.supplier => 'By Supplier',
      _GroupBy.category => 'By Category',
      _GroupBy.storageType => 'By Storage Type',
    };

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
      final groupName = switch (_groupBy) {
        _GroupBy.supplier => getSupplierName(key),
        _GroupBy.category => getCategoryName(key),
        _GroupBy.storageType => getStorageTypeName(key),
      };
      buffer.writeln('📦 $groupName');

      final subDim = _secondaryGroupBy;
      if (subDim != null) {
        groupItems.sort((a, b) {
          final subKeyA = _rawKeyFor(subDim, a, inventoryProvider);
          final subKeyB = _rawKeyFor(subDim, b, inventoryProvider);
          final orderA = _sortOrderFor(subDim, subKeyA, inventoryProvider);
          final orderB = _sortOrderFor(subDim, subKeyB, inventoryProvider);
          final cmp = orderA != null && orderB != null
              ? orderA.compareTo(orderB)
              : _displayNameFor(
                  subDim,
                  subKeyA,
                  getSupplierName,
                  getCategoryName,
                  getStorageTypeName,
                ).compareTo(
                  _displayNameFor(
                    subDim,
                    subKeyB,
                    getSupplierName,
                    getCategoryName,
                    getStorageTypeName,
                  ),
                );
          if (cmp != 0) return cmp;
          return a.name.compareTo(b.name);
        });
      } else {
        groupItems.sort((a, b) => a.name.compareTo(b.name));
      }

      String? lastSubKey;
      for (var item in groupItems) {
        if (subDim != null) {
          final subKey = _rawKeyFor(subDim, item, inventoryProvider);
          if (subKey != lastSubKey) {
            lastSubKey = subKey;
            final subLabel = _displayNameFor(
              subDim,
              subKey,
              getSupplierName,
              getCategoryName,
              getStorageTypeName,
            );
            buffer.writeln('  ▸ $subLabel');
          }
        }

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
    final subject =
        '$restaurantName – Order List ${DateFormat('dd MMM').format(now)}';

    return (text: shareText, subject: subject);
  }

  /// Invokes the OS/browser share sheet. Falls back to copying the text to
  /// the clipboard (with a manual review dialog) if sharing isn't available
  /// — e.g. desktop Chrome, where the Web Share API is often unsupported.
  Future<void> _shareCart(
    BuildContext context,
    List<CartItem> items,
    String Function(String) getSupplierName,
    String Function(String) getCategoryName,
    String Function(String) getStorageTypeName,
  ) async {
    final built = _buildShareText(
      context,
      items,
      getSupplierName,
      getCategoryName,
      getStorageTypeName,
    );
    if (built == null) return;

    try {
      await Share.share(built.text, subject: built.subject);
    } catch (_) {
      if (!context.mounted) return;
      await Clipboard.setData(ClipboardData(text: built.text));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Sharing isn\'t available — copied to clipboard'),
          duration: kSnackBarDuration,
        ),
      );
      _showShareTextDialog(context, built.text);
    }
  }

  /// Copies the order text straight to the clipboard — a reliable option on
  /// platforms (like desktop Chrome) where the native share sheet is
  /// unavailable or doesn't offer a plain-text copy target.
  Future<void> _copyShareText(
    BuildContext context,
    List<CartItem> items,
    String Function(String) getSupplierName,
    String Function(String) getCategoryName,
    String Function(String) getStorageTypeName,
  ) async {
    final built = _buildShareText(
      context,
      items,
      getSupplierName,
      getCategoryName,
      getStorageTypeName,
    );
    if (built == null) return;

    await Clipboard.setData(ClipboardData(text: built.text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Order list copied to clipboard!'),
        duration: kSnackBarDuration,
      ),
    );
  }

  void _showShareTextDialog(BuildContext context, String shareText) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Order List'),
        content: SingleChildScrollView(child: SelectableText(shareText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: shareText));
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('📋 Copied to clipboard!'),
                  duration: kSnackBarDuration,
                ),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
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

// ── Cart quantity stepper ─────────────────────────────────────────────────
// Debounces +/- taps into a single write after the user pauses, instead of
// one Firestore write per tap.
class _CartQuantityStepper extends StatefulWidget {
  final CartProvider provider;
  final CartItem item;
  final bool enabled;
  final String Function(double) formatQty;
  final void Function(BuildContext context, CartProvider provider, CartItem item)
  onEditQuantity;

  const _CartQuantityStepper({
    required this.provider,
    required this.item,
    required this.enabled,
    required this.formatQty,
    required this.onEditQuantity,
  });

  @override
  State<_CartQuantityStepper> createState() => _CartQuantityStepperState();
}

class _CartQuantityStepperState extends State<_CartQuantityStepper> {
  // Non-null while a +/- edit hasn't been written yet, so rapid taps only
  // trigger one debounced write and a stale provider echo of our own
  // pending edit doesn't clobber the displayed value.
  double? _pendingQuantity;
  Timer? _debounce;

  @override
  void didUpdateWidget(covariant _CartQuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.quantityNeeded != widget.item.quantityNeeded &&
        (_pendingQuantity == null ||
            widget.item.quantityNeeded == _pendingQuantity)) {
      _pendingQuantity = null;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_pendingQuantity != null) {
      // Flush immediately so a rapid tap-then-navigate-away isn't lost.
      widget.provider.updateItemQuantity(
        widget.item.listId,
        widget.item.id,
        _pendingQuantity!,
      );
    }
    super.dispose();
  }

  void _stepBy(double delta) {
    final base = _pendingQuantity ?? widget.item.quantityNeeded;
    final next = base + delta;
    if (next < 0) return;

    setState(() => _pendingQuantity = next);

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.provider.updateItemQuantity(
        widget.item.listId,
        widget.item.id,
        next,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayQty = _pendingQuantity ?? widget.item.quantityNeeded;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
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
                enabled: widget.enabled,
                onPressed: () => _stepBy(-1),
              ),
              GestureDetector(
                onTap: widget.enabled
                    ? () => widget.onEditQuantity(
                        context,
                        widget.provider,
                        widget.item,
                      )
                    : null,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 42, minHeight: 22),
                  alignment: Alignment.center,
                  child: Text(
                    widget.formatQty(displayQty),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.enabled ? Colors.white : Colors.white38,
                    ),
                  ),
                ),
              ),
              _buildStepButton(
                icon: Icons.add,
                enabled: widget.enabled,
                onPressed: () => _stepBy(1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.item.unit.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(enabled ? 0.05 : 0.02),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled ? Colors.white70 : Colors.white24,
        ),
      ),
    );
  }
}
