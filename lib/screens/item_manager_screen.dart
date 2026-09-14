import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/grocery_item.dart';
import '../providers/cart_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/settings_provider.dart';
import 'cart_details_screen.dart';
import '../widgets/add_item_modal.dart';

const int _itemSearchPageSize = 200;

class ItemManagerScreen extends StatefulWidget {
  final String? categoryId;
  final String? supplierId;
  final String? title;

  const ItemManagerScreen({
    super.key,
    this.categoryId,
    this.supplierId,
    this.title,
  });

  @override
  State<ItemManagerScreen> createState() => _ItemManagerScreenState();
}

class _ItemManagerScreenState extends State<ItemManagerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  List<GroceryItem>? _cachedInventoryItems;
  List<GroceryItem> _scopedItems = const [];
  List<GroceryItem> _visibleItems = const [];
  Map<String, GroceryItem> _itemById = const {};
  List<Map<String, String>> _searchEntries = const [];
  bool _searchIndexReady = false;
  String _appliedSearchQuery = '';
  int _visibleLimit = _itemSearchPageSize;
  int _searchGeneration = 0;
  int _scopeGeneration = 0;
  bool _isFiltering = false;
  bool _isPreparingList = true;
  bool _scopeSyncScheduled = false;
  bool _isModalOpen = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreIfNeeded);
  }

  @override
  void didUpdateWidget(covariant ItemManagerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId ||
        oldWidget.supplierId != widget.supplierId) {
      _cachedInventoryItems = null;
      _searchGeneration += 1;
      _scopeGeneration += 1;
      _isPreparingList = true;
      _scopeSyncScheduled = false;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    _scheduleScopedItemsSync(inventory);

    final items = _visibleItems;
    final categoryNameById = {
      for (final category in inventory.categories) category.id: category.name,
    };

    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Manage Items')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orangeAccent, Colors.deepOrange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepOrange.withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _addNewItem(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text(
                        'Add New Item',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.categoryId != null ||
                                widget.supplierId != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    Icon(
                                      widget.categoryId != null
                                          ? Icons.category_outlined
                                          : Icons.local_shipping_outlined,
                                      size: 18,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Showing linked items',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search items by name',
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: Colors.orange,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.06),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Colors.deepOrange,
                                    width: 1.4,
                                  ),
                                ),
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      Expanded(
                        child: _isPreparingList || _isFiltering
                            ? _buildListLoadingState()
                            : items.isEmpty
                            ? const Center(child: Text('No items found.'))
                            : ListView.separated(
                                controller: _scrollController,
                                padding: const EdgeInsets.only(bottom: 12),
                                itemCount: _currentVisibleItemCount(
                                  items.length,
                                ),
                                separatorBuilder: (ctx, index) => Divider(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  final catNames = item.categoryIds
                                      .map((id) {
                                        return categoryNameById[id] ?? '?';
                                      })
                                      .join(', ');

                                  return ListTile(
                                    title: Text(item.name),
                                    subtitle: Text(
                                      '${item.currentQuantity.toStringAsFixed(0)} ${item.unit} • Categories: ${catNames.isEmpty ? "None" : catNames}',
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Consumer<CartProvider>(
                                          builder: (context, cart, child) {
                                            bool isInCart = false;
                                            final activeCart = cart.activeCart;
                                            if (activeCart != null) {
                                              final cartItems = cart
                                                  .getItemsForList(
                                                    activeCart.id,
                                                  );
                                              isInCart = cartItems.any(
                                                (cartItem) =>
                                                    cartItem.itemId == item.id,
                                              );
                                            }

                                            return IconButton(
                                              icon: Icon(
                                                isInCart
                                                    ? Icons.check_circle
                                                    : Icons.add_shopping_cart,
                                                color: isInCart
                                                    ? Colors.green
                                                    : Colors.orange,
                                              ),
                                              tooltip: isInCart
                                                  ? 'Add more to cart'
                                                  : 'Add to cart',
                                              onPressed: () async {
                                                final settings =
                                                    Provider.of<
                                                      SettingsProvider
                                                    >(context, listen: false);
                                                if (settings
                                                    .showQuantityPopup) {
                                                  _showAddToCartDialog(
                                                    context,
                                                    cart,
                                                    item,
                                                  );
                                                } else {
                                                  final messenger =
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      );
                                                  final activeCart =
                                                      cart.activeCart;
                                                  final existingItem =
                                                      activeCart != null
                                                      ? cart.findCartItem(
                                                          activeCart.id,
                                                          item.id,
                                                        )
                                                      : null;
                                                  await cart.addItemToCart(
                                                    item.id,
                                                    1.0,
                                                  );
                                                  if (!context.mounted) return;
                                                  _showCartSnackBar(
                                                    messenger,
                                                    existingItem == null
                                                        ? '${item.name} added to cart'
                                                        : '${item.name} quantity updated',
                                                    action: SnackBarAction(
                                                      label: 'Undo',
                                                      onPressed: () {
                                                        if (existingItem ==
                                                            null) {
                                                          final activeCartAfterAdd =
                                                              cart.activeCart;
                                                          final addedItem =
                                                              activeCartAfterAdd !=
                                                                  null
                                                              ? cart.findCartItem(
                                                                  activeCartAfterAdd
                                                                      .id,
                                                                  item.id,
                                                                )
                                                              : null;
                                                          if (addedItem !=
                                                              null) {
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
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blueAccent,
                                          ),
                                          onPressed: () =>
                                              _editItem(context, item),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () => _confirmDelete(
                                            context,
                                            inventory,
                                            item,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final activeCart = cartProvider.activeCart;
          final itemCount = activeCart != null
              ? cartProvider.getItemsForList(activeCart.id).length
              : 0;
          final showCartButton =
              (widget.categoryId != null || widget.supplierId != null) &&
              itemCount > 0;

          if (!showCartButton) {
            return const SizedBox.shrink();
          }

          return GestureDetector(
            onTap: () {
              if (activeCart != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CartDetailsScreen(listId: activeCart.id),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orangeAccent, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'View Cart',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$itemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _addNewItem(BuildContext context) async {
    await _openItemModal(context, const AddItemModal());
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final normalizedQuery = value.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      _restoreClearedSearchResults();
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      _applySearch(normalizedQuery);
    });
  }

  void _restoreClearedSearchResults() {
    final currentGeneration = ++_searchGeneration;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || currentGeneration != _searchGeneration) {
        return;
      }

      setState(() {
        _appliedSearchQuery = '';
        _visibleItems = _scopedItems;
        _isFiltering = false;
        _resetVisibleLimit();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && currentGeneration == _searchGeneration) {
          _jumpListToTop();
        }
      });
    });
  }

  void _scheduleScopedItemsSync(InventoryProvider inventory) {
    if (_isModalOpen ||
        identical(_cachedInventoryItems, inventory.items) ||
        _scopeSyncScheduled) {
      return;
    }

    _scopeSyncScheduled = true;
    final sourceItems = inventory.items;
    final currentGeneration = ++_scopeGeneration;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareScopedItems(sourceItems, currentGeneration);
    });
  }

  Future<void> _prepareScopedItems(
    List<GroceryItem> sourceItems,
    int generation,
  ) async {
    if (!mounted || _isModalOpen) {
      return;
    }

    setState(() {
      _isPreparingList = true;
    });

    final scopedItems = <GroceryItem>[];
    for (int index = 0; index < sourceItems.length; index++) {
      final item = sourceItems[index];
      if (_matchesScope(item)) {
        scopedItems.add(item);
      }

      if (index > 0 && index % 400 == 0) {
        await Future<void>.delayed(Duration.zero);
        if (!mounted || generation != _scopeGeneration || _isModalOpen) {
          return;
        }
      }
    }

    if (!mounted || generation != _scopeGeneration || _isModalOpen) {
      return;
    }

    _cachedInventoryItems = sourceItems;
    _scopedItems = List<GroceryItem>.unmodifiable(scopedItems);
    _itemById = const {};
    _searchEntries = const [];
    _searchIndexReady = false;
    _scopeSyncScheduled = false;

    if (_appliedSearchQuery.isEmpty) {
      setState(() {
        _visibleItems = _scopedItems;
        _isFiltering = false;
        _isPreparingList = false;
        _resetVisibleLimit();
      });
      return;
    }

    final currentGeneration = ++_searchGeneration;
    setState(() {
      _visibleItems = const [];
      _isPreparingList = false;
      _isFiltering = true;
      _resetVisibleLimit();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || currentGeneration != _searchGeneration || _isModalOpen) {
        return;
      }
      _applySearch(_appliedSearchQuery);
    });
  }

  bool _matchesScope(GroceryItem item) {
    final matchesCategory =
        widget.categoryId == null ||
        item.categoryIds.contains(widget.categoryId);
    final matchesSupplier =
        widget.supplierId == null ||
        item.defaultSupplierId == widget.supplierId;
    return matchesCategory && matchesSupplier;
  }

  Future<void> _applySearch(String normalizedQuery) async {
    if (!mounted ||
        _isModalOpen ||
        (normalizedQuery == _appliedSearchQuery && !_isFiltering)) {
      return;
    }

    if (normalizedQuery.isEmpty) {
      setState(() {
        _appliedSearchQuery = '';
        _visibleItems = _scopedItems;
        _isFiltering = false;
        _resetVisibleLimit();
      });
      _jumpListToTop();
      return;
    }

    _ensureSearchIndex();

    final currentGeneration = ++_searchGeneration;
    if (!_isFiltering) {
      setState(() {
        _isFiltering = true;
      });
    }

    if (!mounted || currentGeneration != _searchGeneration || _isModalOpen) {
      return;
    }

    final nextItems = <GroceryItem>[];
    for (int index = 0; index < _searchEntries.length; index++) {
      final entry = _searchEntries[index];
      final entryName = entry['name'] ?? '';
      if (entryName.contains(normalizedQuery)) {
        final item = _itemById[entry['id']];
        if (item != null) {
          nextItems.add(item);
        }
      }

      if (index > 0 && index % 300 == 0) {
        await Future<void>.delayed(Duration.zero);
        if (!mounted ||
            currentGeneration != _searchGeneration ||
            _isModalOpen) {
          return;
        }
      }
    }

    setState(() {
      _appliedSearchQuery = normalizedQuery;
      _visibleItems = List<GroceryItem>.unmodifiable(nextItems);
      _isFiltering = false;
      _resetVisibleLimit();
    });
    _jumpListToTop();
  }

  void _ensureSearchIndex() {
    if (_searchIndexReady) {
      return;
    }

    _itemById = {for (final item in _scopedItems) item.id: item};
    _searchEntries = [
      for (final item in _scopedItems)
        {'id': item.id, 'name': item.name.toLowerCase()},
    ];
    _searchIndexReady = true;
  }

  void _loadMoreIfNeeded() {
    if (!_scrollController.hasClients ||
        _visibleLimit >= _visibleItems.length) {
      return;
    }

    if (_scrollController.position.extentAfter > 500) {
      return;
    }

    setState(() {
      final nextLimit = _visibleLimit + _itemSearchPageSize;
      _visibleLimit = nextLimit > _visibleItems.length
          ? _visibleItems.length
          : nextLimit;
    });
  }

  int _currentVisibleItemCount(int totalCount) {
    return totalCount < _visibleLimit ? totalCount : _visibleLimit;
  }

  void _resetVisibleLimit() {
    _visibleLimit = _visibleItems.length < _itemSearchPageSize
        ? _visibleItems.length
        : _itemSearchPageSize;
  }

  void _jumpListToTop() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.jumpTo(0);
  }

  Widget _buildListLoadingState() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: 6,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 160,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _editItem(BuildContext context, GroceryItem item) async {
    await _openItemModal(context, AddItemModal(itemToEdit: item));
  }

  Future<void> _openItemModal(BuildContext context, AddItemModal modal) async {
    _searchDebounce?.cancel();
    _searchGeneration += 1;
    _scopeGeneration += 1;

    if (mounted) {
      setState(() {
        _isModalOpen = true;
        _isFiltering = false;
        _scopeSyncScheduled = false;
      });
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => modal,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isModalOpen = false;
      _cachedInventoryItems = null;
      _isPreparingList = true;
      _scopeSyncScheduled = false;
    });
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
          void adjust(double delta) {
            final current = double.tryParse(controller.text) ?? 0.0;
            final next = current + delta;
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
                      onPressed: () => adjust(-1.0),
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
                      onPressed: () => adjust(1.0),
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

  void _confirmDelete(
    BuildContext context,
    InventoryProvider inventory,
    GroceryItem item,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // We need deleteItem in provider too!
              // For now assuming we will add it or have it.
              // checking repository... yes it has deleteItem.
              // checking provider... no deleteItem exposed yet!
              // I need to add deleteItem to provider as well.
              // inventory.deleteItem(item.id);
              Provider.of<InventoryProvider>(
                context,
                listen: false,
              ).deleteItem(item.id); // Will crash if not added
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
