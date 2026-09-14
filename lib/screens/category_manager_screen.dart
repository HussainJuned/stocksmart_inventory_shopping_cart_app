import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../models/grocery_item.dart';
import '../providers/inventory_provider.dart';
import 'item_manager_screen.dart';

class CategoryManagerScreen extends StatelessWidget {
  const CategoryManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final categories = inventory.categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: SafeArea(
        top: false,
        child: categories.isEmpty
            ? const Center(child: Text('No categories yet.'))
            : ReorderableListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                buildDefaultDragHandles: false,
                itemCount: categories.length,
                onReorder: (oldIndex, newIndex) {
                  Provider.of<InventoryProvider>(
                    context,
                    listen: false,
                  ).reorderCategory(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final linkedItems = inventory.items
                      .where((item) => item.categoryIds.contains(category.id))
                      .toList();
                  return ListTile(
                    key: ValueKey(category.id),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemManagerScreen(
                          categoryId: category.id,
                          title: category.name,
                        ),
                      ),
                    ),
                    title: Text(category.name),
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
                          onPressed: () => _showEditDialog(context, category),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _confirmDelete(context, category),
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
          'New Category',
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
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. Produce',
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
                ).addCategory(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Category category) {
    final controller = TextEditingController(text: category.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Category'),
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
                final updated = Category(
                  id: category.id,
                  name: controller.text,
                  color: category.color,
                  sortOrder: category.sortOrder,
                );
                Provider.of<InventoryProvider>(
                  context,
                  listen: false,
                ).updateCategory(updated);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? Items in this category will be preserved but may need re-assigning.',
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
              ).deleteCategory(category.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
