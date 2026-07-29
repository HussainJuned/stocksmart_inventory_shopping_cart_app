import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/grocery_item.dart';
import '../providers/inventory_provider.dart';
import '../widgets/add_item_modal.dart';

class ItemManagerScreen extends StatefulWidget {
  const ItemManagerScreen({super.key});

  @override
  State<ItemManagerScreen> createState() => _ItemManagerScreenState();
}

class _ItemManagerScreenState extends State<ItemManagerScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);

    // Filter items based on search
    final items = inventory.items.where((item) {
      return item.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Items')),
      body: SafeArea(top: false, child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Items',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No items found.'))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (ctx, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      // Find category names
                      final catNames = item.categoryIds
                          .map((id) {
                            try {
                              return inventory.categories
                                  .firstWhere((c) => c.id == id)
                                  .name;
                            } catch (e) {
                              return '?';
                            }
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
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blueAccent,
                              ),
                              onPressed: () => _editItem(context, item),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () =>
                                  _confirmDelete(context, inventory, item),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewItem(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addNewItem(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddItemModal(),
    );
  }

  void _editItem(BuildContext context, GroceryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddItemModal(itemToEdit: item),
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
