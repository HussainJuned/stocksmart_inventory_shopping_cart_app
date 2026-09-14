import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
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

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
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

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    if (inventory.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // DefaultTabController needs to be rebuilt if length changes.
    // We can use a key derived from length/IDs to force rebuild.
    // If empty, we still provide a controller (length 0) or handle in body.

    // NOTE: AppBar actions should be visible even if empty.

    return DefaultTabController(
      key: ValueKey(inventory.categories.length),
      length: inventory.categories.isEmpty
          ? 1
          : inventory
                .categories
                .length, // Ensure at least 1 for safety if needed, or 0 if supported
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            auth.user?.displayName ?? 'StockSmart',
            overflow: TextOverflow.ellipsis,
          ),
          bottom: inventory.categories.isEmpty
              ? null
              : TabBar(
                  isScrollable: true,
                  indicatorColor: Colors.orange,
                  tabs: inventory.categories
                      .map((c) => Tab(text: c.name))
                      .toList(),
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
        body: SafeArea(top: false, child: _buildBody(inventory)),
        drawer: Drawer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.deepOrange),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.ramen_dining,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            auth.user?.displayName ?? 'StockSmart',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
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
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit_note),
                      title: const Text('Manage Categories'),
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
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Order History'),
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
                    ListTile(
                      leading: const Icon(Icons.local_shipping),
                      title: const Text('Manage Suppliers'),
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
                    const Divider(),
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
                        ListTile(
                          contentPadding: const EdgeInsets.only(left: 32),
                          leading: const Icon(Icons.download),
                          title: const Text('Import from JSON'),
                          onTap: () {
                            Navigator.pop(context); // Close Drawer
                            _showImportDialog(context);
                          },
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.only(left: 32),
                          leading: const Icon(Icons.upload),
                          title: const Text('Export to JSON'),
                          subtitle: const Text(
                            'Backup all items, categories & suppliers',
                            style: TextStyle(fontSize: 11),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _exportToJson(context);
                          },
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
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Provider.of<AuthProvider>(context, listen: false).signOut();
                },
              ),
              const SizedBox(height: 16),
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

  Widget _buildBody(InventoryProvider inventory) {
    // 1. Empty Categories Mode
    if (inventory.categories.isEmpty) {
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
      children: inventory.categories.map((cat) {
        return _CategoryList(categoryId: cat.id, categoryName: cat.name);
      }).toList(),
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
  final String categoryId;
  final String categoryName;
  const _CategoryList({required this.categoryId, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);

    // Filter items by categoryId (Actually implemented now)
    // Filter items: Check if item has THIS category
    final items = inventory.items
        .where((i) => i.categoryIds.contains(categoryId))
        .toList();

    // Or logic to show ALL if categoryId matches 'generic'?
    // For now strict filtering.

    if (items.isEmpty) {
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
