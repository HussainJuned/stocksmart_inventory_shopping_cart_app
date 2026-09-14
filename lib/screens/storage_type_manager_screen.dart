import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/storage_type_model.dart';
import '../models/grocery_item.dart';
import '../providers/inventory_provider.dart';
import 'item_manager_screen.dart';

class StorageTypeManagerScreen extends StatelessWidget {
  const StorageTypeManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final storageTypes = inventory.storageTypes;
    final unassignedItems = inventory.items
        .where((item) => item.storageTypeId == null)
        .toList();
    final showUnassigned = unassignedItems.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Storage Types')),
      body: SafeArea(
        top: false,
        child: storageTypes.isEmpty && !showUnassigned
            ? const Center(child: Text('No storage types yet.'))
            : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 96),
                child: Column(
                  children: [
                    if (storageTypes.isNotEmpty)
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: storageTypes.length,
                        onReorder: (oldIndex, newIndex) {
                          Provider.of<InventoryProvider>(
                            context,
                            listen: false,
                          ).reorderStorageType(oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final storageType = storageTypes[index];
                          final linkedItems = inventory.items
                              .where(
                                (item) =>
                                    item.storageTypeId == storageType.id,
                              )
                              .toList();
                          return ListTile(
                            key: ValueKey(storageType.id),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ItemManagerScreen(
                                  storageTypeId: storageType.id,
                                  title: storageType.name,
                                ),
                              ),
                            ),
                            title: Text(storageType.name),
                            subtitle: Text(
                              _buildLinkedItemsSummary(linkedItems),
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
                                  onPressed: () =>
                                      _showEditDialog(context, storageType),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () =>
                                      _confirmDelete(context, storageType),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    if (showUnassigned) ...[
                      const Divider(height: 1),
                      ListTile(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ItemManagerScreen(
                              unassignedStorageTypeOnly: true,
                              title: 'Unassigned',
                            ),
                          ),
                        ),
                        leading: const Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.grey,
                        ),
                        title: const Text('Unassigned'),
                        subtitle: Text(
                          _buildLinkedItemsSummary(unassignedItems),
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text(
          'New Storage Type',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
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

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Storage Type'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. Dry Food',
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
              if (controller.text.isNotEmpty) {
                Provider.of<InventoryProvider>(
                  context,
                  listen: false,
                ).addStorageType(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, StorageType storageType) {
    final controller = TextEditingController(text: storageType.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Storage Type'),
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
              if (controller.text.isNotEmpty) {
                final updated = StorageType(
                  id: storageType.id,
                  name: controller.text,
                  color: storageType.color,
                  sortOrder: storageType.sortOrder,
                );
                Provider.of<InventoryProvider>(
                  context,
                  listen: false,
                ).updateStorageType(updated);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, StorageType storageType) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Storage Type?'),
        content: Text(
          'Are you sure you want to delete "${storageType.name}"? Items using this storage type will be preserved but may need re-assigning.',
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
              ).deleteStorageType(storageType.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
