import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/supplier_model.dart';

class SupplierManagerScreen extends StatelessWidget {
  const SupplierManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to changes
    final inventory = Provider.of<InventoryProvider>(context);
    final suppliers = inventory.suppliers;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Suppliers')),
      body: SafeArea(
        top: false,
        child: suppliers.isEmpty
            ? const Center(child: Text('No suppliers added yet.'))
            : ListView.builder(
              itemCount: suppliers.length,
              itemBuilder: (ctx, i) {
                final supplier = suppliers[i];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.local_shipping, color: Colors.orange),
                  ),
                  title: Text(
                    supplier.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () {
                          _showEditSupplierDialog(context, inventory, supplier);
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          _showAddSupplierDialog(context, inventory);
        },
      ),
    );
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
