import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/unit_model.dart';
import '../providers/inventory_provider.dart';

class UnitManagerScreen extends StatelessWidget {
  const UnitManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final units = inventory.units;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Units')),
      body: SafeArea(
        top: false,
        child: units.isEmpty
            ? const Center(child: Text('No units yet.'))
            : ReorderableListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                buildDefaultDragHandles: false,
                itemCount: units.length,
                onReorder: (oldIndex, newIndex) {
                  Provider.of<InventoryProvider>(
                    context,
                    listen: false,
                  ).reorderUnit(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final unit = units[index];
                  final itemsUsingUnit = inventory.items
                      .where((item) => item.unit == unit.name)
                      .length;
                  return ListTile(
                    key: ValueKey(unit.id),
                    title: Text(unit.name, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      itemsUsingUnit == 0
                          ? 'Not used by any item'
                          : 'Used by $itemsUsingUnit item${itemsUsingUnit == 1 ? '' : 's'}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: Icon(Icons.drag_indicator),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () => _showEditDialog(context, unit),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _confirmDelete(context, unit),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text(
          'New Unit',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Unit'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. crate',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Provider.of<InventoryProvider>(
                  context,
                  listen: false,
                ).addUnit(name);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Unit unit) {
    final controller = TextEditingController(text: unit.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Unit'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final updated = Unit(
                  id: unit.id,
                  name: name,
                  sortOrder: unit.sortOrder,
                );
                Provider.of<InventoryProvider>(
                  context,
                  listen: false,
                ).updateUnit(updated);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Unit unit) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Unit?'),
        content: Text(
          'Are you sure you want to delete "${unit.name}"? Items already using this unit keep showing it — it just won\'t be offered as a choice anymore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<InventoryProvider>(
                context,
                listen: false,
              ).deleteUnit(unit.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
