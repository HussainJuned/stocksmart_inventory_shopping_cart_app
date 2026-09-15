import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/grocery_item.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/item_tile.dart';
import 'cart_history_screen.dart';
import 'cart_details_screen.dart';
import 'category_manager_screen.dart';
import 'item_manager_screen.dart';
import 'supplier_manager_screen.dart';
import 'storage_type_manager_screen.dart';
import 'unit_manager_screen.dart';

// All filtering/sorting below runs purely against the already-loaded Hive
// items list (see InventoryProvider), so search and sort work fully
// offline — no network round-trip involved.
enum _HomeSortBy { defaultOrder, nameAsc, stockLow, lastModified }

String _homeSortByLabel(_HomeSortBy sortBy) => switch (sortBy) {
  _HomeSortBy.defaultOrder => 'Default order',
  _HomeSortBy.nameAsc => 'Name (A–Z)',
  _HomeSortBy.stockLow => 'Stock level (lowest first)',
  _HomeSortBy.lastModified => 'Last modified (newest first)',
};

void _sortHomeItemsInPlace(List<GroceryItem> items, _HomeSortBy sortBy) {
  switch (sortBy) {
    case _HomeSortBy.defaultOrder:
      return;
    case _HomeSortBy.nameAsc:
      items.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return;
    case _HomeSortBy.stockLow:
      items.sort(
        (a, b) => (a.currentQuantity - a.parLevel).compareTo(
          b.currentQuantity - b.parLevel,
        ),
      );
      return;
    case _HomeSortBy.lastModified:
      items.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
      return;
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _HomeSortBy _sortBy = _HomeSortBy.defaultOrder;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _editRestaurantName(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentName = auth.user?.displayName ?? 'StockSmart';
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Restaurant Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                await auth.updateRestaurantName(newName);
              }
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    bool isImporting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Import from JSON'),
              content: SizedBox(
                width: double.maxFinite,
                child: TextField(
                  controller: controller,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    hintText: 'Paste your JSON here...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isImporting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isImporting
                      ? null
                      : () async {
                          final jsonString = controller.text.trim();
                          if (jsonString.isEmpty) return;

                          setState(() => isImporting = true);
                          try {
                            final provider = Provider.of<InventoryProvider>(
                              context,
                              listen: false,
                            );
                            await provider.importFromJson(jsonString);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Import successful!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Invalid JSON or import failed: $e',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            setState(() => isImporting = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: isImporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Import'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _copyJsonToClipboard(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context, listen: false);
    final jsonString = inventory.exportToJson();
    Clipboard.setData(ClipboardData(text: jsonString));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('JSON copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportToJson(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context, listen: false);
    final jsonString = inventory.exportToJson();

    try {
      Share.share(
        jsonString,
        subject:
            'StockSmart Backup – ${DateTime.now().toLocal().toString().substring(0, 10)}',
      );
    } catch (_) {
      // Web / share unavailable – show copy dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Export JSON'),
          content: SingleChildScrollView(child: SelectableText(jsonString)),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonString));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('JSON copied to clipboard!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Widget _drawerSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      minVerticalPadding: 14,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: const TextStyle(fontSize: 11)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    if (inventory.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Only surface an "Uncategorized" tab when there's actually an item
    // sitting in it — otherwise it's just clutter.
    final showUncategorized = inventory.items.any(
      (i) => i.categoryIds.isEmpty,
    );
    final tabCount = inventory.categories.length + (showUncategorized ? 1 : 0);

    // DefaultTabController needs to be rebuilt if length changes.
    // We can use a key derived from length/IDs to force rebuild.
    // If empty, we still provide a controller (length 0) or handle in body.

    // NOTE: AppBar actions should be visible even if empty.

    return DefaultTabController(
      key: ValueKey('$tabCount-$showUncategorized'),
      length: tabCount == 0 ? 1 : tabCount,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            auth.user?.displayName ?? 'StockSmart',
            overflow: TextOverflow.ellipsis,
          ),
          bottom: tabCount == 0
              ? null
              : TabBar(
                  isScrollable: true,
                  indicatorColor: Colors.orange,
                  tabs: [
                    ...inventory.categories.map((c) => Tab(text: c.name)),
                    if (showUncategorized) const Tab(text: 'Uncategorized'),
                  ],
                ),
          actions: [
            ...[
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: SizedBox(
                    height: 36,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.list_alt, size: 18),
                      label: const Text(
                        'Manage Items',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ItemManagerScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              if (inventory.items.isNotEmpty) _buildSearchSortBar(),
              Expanded(child: _buildBody(inventory, showUncategorized)),
            ],
          ),
        ),
        drawer: Drawer(
          backgroundColor: const Color(0xFF161616),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                margin: EdgeInsets.zero,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orangeAccent, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.ramen_dining,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            auth.user?.displayName ?? 'StockSmart',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            Navigator.pop(context); // Close drawer
                            _editRestaurantName(context);
                          },
                          tooltip: 'Edit Restaurant Name',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    8,
                    0,
                    8 + MediaQuery.of(context).padding.bottom,
                  ),
                  children: [
                    _drawerSectionLabel('Menu'),
                    _drawerTile(
                      icon: Icons.edit_note,
                      iconColor: Colors.blueAccent,
                      label: 'Manage Categories',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoryManagerScreen(),
                          ),
                        );
                      },
                    ),
                    _drawerTile(
                      icon: Icons.local_shipping,
                      iconColor: Colors.teal,
                      label: 'Manage Suppliers',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SupplierManagerScreen(),
                          ),
                        );
                      },
                    ),
                    _drawerTile(
                      icon: Icons.inventory_2_outlined,
                      iconColor: Colors.amber,
                      label: 'Manage Storage Types',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StorageTypeManagerScreen(),
                          ),
                        );
                      },
                    ),
                    _drawerTile(
                      icon: Icons.list_alt,
                      iconColor: Colors.deepOrange,
                      label: 'Manage Items',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ItemManagerScreen(),
                          ),
                        );
                      },
                    ),
                    _drawerTile(
                      icon: Icons.straighten,
                      iconColor: Colors.lightGreen,
                      label: 'Manage Units',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UnitManagerScreen(),
                          ),
                        );
                      },
                    ),
                    _drawerTile(
                      icon: Icons.history,
                      iconColor: Colors.purpleAccent,
                      label: 'Order History',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CartHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(height: 24),
                    ),
                    ExpansionTile(
                      leading: const Icon(Icons.backup_outlined),
                      title: const Text('Data Backup'),
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.only(
                            left: 32,
                            right: 16,
                          ),
                          leading: const Icon(
                            Icons.download_rounded,
                            size: 20,
                            color: Colors.lightBlue,
                          ),
                          title: const Text(
                            'Import from JSON',
                            style: TextStyle(fontSize: 14),
                          ),
                          dense: true,
                          onTap: () {
                            Navigator.pop(context); // Close Drawer
                            _showImportDialog(context);
                          },
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.only(
                            left: 32,
                            right: 16,
                          ),
                          leading: const Icon(
                            Icons.upload_rounded,
                            size: 20,
                            color: Colors.green,
                          ),
                          title: const Text(
                            'Export to JSON',
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Backup all items, categories & suppliers',
                            style: TextStyle(fontSize: 11),
                          ),
                          dense: true,
                          onTap: () {
                            Navigator.pop(context);
                            _exportToJson(context);
                          },
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.only(
                            left: 32,
                            right: 16,
                          ),
                          leading: const Icon(
                            Icons.content_copy_outlined,
                            size: 20,
                            color: Colors.amber,
                          ),
                          title: const Text(
                            'Copy as Text',
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Copy the backup JSON to your clipboard',
                            style: TextStyle(fontSize: 11),
                          ),
                          dense: true,
                          onTap: () {
                            Navigator.pop(context);
                            _copyJsonToClipboard(context);
                          },
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(height: 24),
                    ),
                    ExpansionTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Settings'),
                      children: [
                        if (auth.user?.email != null)
                          ListTile(
                            contentPadding: const EdgeInsets.only(
                              left: 32,
                              right: 16,
                            ),
                            leading: const Icon(
                              Icons.email_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),
                            title: Text(
                              auth.user!.email!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            dense: true,
                          ),
                        Consumer<SettingsProvider>(
                          builder: (context, settings, _) => SwitchListTile(
                            contentPadding: const EdgeInsets.only(
                              left: 32,
                              right: 16,
                            ),
                            secondary: const Icon(
                              Icons.touch_app_outlined,
                              size: 20,
                            ),
                            title: const Text(
                              'Ask quantity when adding to cart',
                              style: TextStyle(fontSize: 14),
                            ),
                            value: settings.showQuantityPopup,
                            onChanged: settings.setShowQuantityPopup,
                            dense: true,
                            activeThumbColor: Colors.deepOrange,
                            activeTrackColor: Colors.deepOrange.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        /* ListTile(
                          contentPadding: const EdgeInsets.only(left: 32),
                          leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                          title: const Text('Reset All Data', style: TextStyle(color: Colors.redAccent)),
                          onTap: () {
                            Navigator.pop(context);
                            _showResetConfirmation(context);
                          },
                        ), */
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(height: 24),
                    ),
                    _drawerTile(
                      icon: Icons.logout,
                      iconColor: Colors.redAccent,
                      label: 'Logout',
                      onTap: () {
                        Navigator.pop(context);
                        Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        ).signOut();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            final activeCart = cartProvider.activeCart;
            final itemCount = activeCart != null
                ? cartProvider.getItemsForList(activeCart.id).length
                : 0;

            if (itemCount == 0) return const SizedBox.shrink();

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orangeAccent, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.4),
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
                    Text(
                      'View Cart',
                      style: const TextStyle(
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$itemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(InventoryProvider inventory, bool showUncategorized) {
    // 1. Empty Categories Mode
    if (inventory.categories.isEmpty && !showUncategorized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No Categories Found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CategoryManagerScreen(),
                  ),
                );
              },
              child: const Text('Manage Categories'),
            ),
          ],
        ),
      );
    }

    // 2. TabBar Mode (Default)
    return TabBarView(
      children: [
        ...inventory.categories.map(
          (cat) => _CategoryList(
            categoryId: cat.id,
            categoryName: cat.name,
            searchQuery: _searchQuery,
            sortBy: _sortBy,
          ),
        ),
        if (showUncategorized)
          _CategoryList(
            categoryId: null,
            categoryName: 'Uncategorized',
            searchQuery: _searchQuery,
            sortBy: _sortBy,
          ),
      ],
    );
  }

  Widget _buildSearchSortBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search items...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim()),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<_HomeSortBy>(
            tooltip: 'Sort by',
            initialValue: _sortBy,
            onSelected: (sortBy) => setState(() => _sortBy = sortBy),
            itemBuilder: (context) => [
              for (final sortBy in _HomeSortBy.values)
                CheckedPopupMenuItem<_HomeSortBy>(
                  value: sortBy,
                  checked: _sortBy == sortBy,
                  child: Text(_homeSortByLabel(sortBy)),
                ),
            ],
            child: Container(
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.sort_rounded,
                size: 20,
                color: _sortBy == _HomeSortBy.defaultOrder
                    ? Colors.white70
                    : Colors.orangeAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete all items, categories, suppliers, and order history from both your device and the cloud. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final inventory = Provider.of<InventoryProvider>(context, listen: false);
              final cart = Provider.of<CartProvider>(context, listen: false);
              
              await inventory.resetEverything();
              await cart.resetData();

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data has been reset.')),
              );
            },
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  } */
}

class _CategoryList extends StatelessWidget {
  // Null categoryId means "uncategorized" (items with no category assigned).
  final String? categoryId;
  final String categoryName;
  final String searchQuery;
  final _HomeSortBy sortBy;

  const _CategoryList({
    required this.categoryId,
    required this.categoryName,
    this.searchQuery = '',
    this.sortBy = _HomeSortBy.defaultOrder,
  });

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);

    final categoryItems = inventory.items
        .where(
          (i) => categoryId == null
              ? i.categoryIds.isEmpty
              : i.categoryIds.contains(categoryId),
        )
        .toList();

    if (categoryItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No items in $categoryName.'),
            const SizedBox(height: 8),
            // Hint: Add item to this category
          ],
        ),
      );
    }

    final query = searchQuery.toLowerCase();
    final items = query.isEmpty
        ? categoryItems
        : categoryItems
              .where((i) => i.name.toLowerCase().contains(query))
              .toList();

    if (items.isEmpty) {
      return Center(child: Text('No items match "$searchQuery".'));
    }

    // Manual drag reorder only makes sense against the item's real stored
    // order — once the list is searched or sorted, fall back to a plain
    // (non-reorderable) list.
    final isReorderable = query.isEmpty && sortBy == _HomeSortBy.defaultOrder;
    if (!isReorderable) {
      _sortHomeItemsInPlace(items, sortBy);
      return ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ItemTile(key: ValueKey(items[index].id), item: items[index]);
        },
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: items.length,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        inventory.reorderItem(oldIndex, newIndex, categoryId);
      },
      itemBuilder: (context, index) {
        final item = items[index];
        return ItemTile(
          key: ValueKey(item.id), // Required for ReorderableListView
          item: item,
          index: index,
        );
      },
    );
  }
}
