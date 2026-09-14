import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/grocery_item.dart';
import '../providers/inventory_provider.dart';
import '../models/supplier_model.dart';
import 'item_manager_screen.dart';

class SupplierManagerScreen extends StatelessWidget {
  const SupplierManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to changes
    final inventory = Provider.of<InventoryProvider>(context);
    final suppliers = inventory.suppliers;
    final unassignedItems = inventory.items
        .where((item) => item.defaultSupplierId == null)
        .toList();
    final showUnassigned = unassignedItems.isNotEmpty;
    final rowCount = suppliers.length + (showUnassigned ? 1 : 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Suppliers')),
      body: SafeArea(
        top: false,
        child: rowCount == 0
            ? const Center(child: Text('No suppliers added yet.'))
            : ListView.builder(
                itemCount: rowCount,
                itemBuilder: (ctx, i) {
                  if (showUnassigned && i == suppliers.length) {
                    return ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ItemManagerScreen(
                            unassignedSupplierOnly: true,
                            title: 'Unassigned',
                          ),
                        ),
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: Colors.white10,
                        child: Icon(
                          Icons.local_shipping_outlined,
                          color: Colors.grey,
                        ),
                      ),
                      title: const Text(
                        'Unassigned',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        _buildLinkedItemsSummary(unassignedItems),
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    );
                  }

                  final supplier = suppliers[i];
                  final linkedItems = inventory.items
                      .where((item) => item.defaultSupplierId == supplier.id)
                      .toList();
                  return ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemManagerScreen(
                          supplierId: supplier.id,
                          title: supplier.name,
                        ),
                      ),
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.local_shipping, color: Colors.orange),
                    ),
                    title: Text(
                      supplier.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      _buildLinkedItemsSummary(linkedItems),
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () {
                            _showEditSupplierDialog(
                              context,
                              inventory,
                              supplier,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _confirmDelete(
                              context,
                              inventory,
                              supplier.id,
                              supplier.name,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text(
          'New Supplier',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () {
          _showAddSupplierDialog(context, inventory);
        },
      ),
    );
  }

  String _buildLinkedItemsSummary(List<GroceryItem> linkedItems) {
    if (linkedItems.isEmpty) {
      return 'No items assigned';
    }

    final previewNames = linkedItems
        .take(3)
        .map((item) => item.name)
        .join(', ');
    final remaining = linkedItems.length - 3;
    if (remaining > 0) {
      return '${linkedItems.length} items: $previewNames +$remaining more';
    }
    return '${linkedItems.length} items: $previewNames';
  }

  void _showAddSupplierDialog(
    BuildContext context,
    InventoryProvider inventory,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Supplier'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Supplier Name (e.g. Makro)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                inventory.addSupplier(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditSupplierDialog(
    BuildContext context,
    InventoryProvider inventory,
    Supplier supplier,
  ) {
    final controller = TextEditingController(text: supplier.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Supplier'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Supplier Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                inventory.updateSupplier(supplier.copyWith(name: name));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    InventoryProvider inventory,
    String id,
    String name,
  ) {
    // Check if any items use this supplier? (MVP: Just warn or ignore)
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $name?'),
        content: const Text(
          'This will not remove the supplier from existing items, but they will point to an invalid ID.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              inventory.deleteSupplier(id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
