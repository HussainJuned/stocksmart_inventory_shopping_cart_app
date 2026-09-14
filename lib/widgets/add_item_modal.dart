import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/grocery_item.dart';
import '../providers/inventory_provider.dart';

class AddItemModal extends StatefulWidget {
  final GroceryItem? itemToEdit; // Added for edit mode support
  const AddItemModal({super.key, this.itemToEdit});

  @override
  State<AddItemModal> createState() => _AddItemModalState();
}

class _AddItemModalState extends State<AddItemModal> {
  late TextEditingController _nameController;
  late TextEditingController _parController;
  String _selectedUnit = 'kg';
  List<String> _selectedCategoryIds = [];
  String? _selectedSupplierId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      _nameController = TextEditingController(text: widget.itemToEdit!.name);
      _parController = TextEditingController(
        text: widget.itemToEdit!.parLevel.toStringAsFixed(0),
      );
      _selectedUnit = widget.itemToEdit!.unit;
      _selectedCategoryIds = List.from(widget.itemToEdit!.categoryIds);
      _selectedSupplierId = widget.itemToEdit!.defaultSupplierId;
    } else {
      _nameController = TextEditingController();
      _parController = TextEditingController(text: '5');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _parController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.itemToEdit == null ? 'Add New Item' : 'Edit Item',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              autofocus: widget.itemToEdit == null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _parController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Par Level',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedUnit,
                  items:
                      [
                            'kg',
                            'g',
                            'L',
                            'pcs',
                            'box',
                            'bunch',
                            'tray',
                            'roll',
                            'pack',
                            'bag',
                            'bottle',
                            'can',
                            'sheet',
                            'carton',
                            'case',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _selectedUnit = v!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Categories (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Consumer<InventoryProvider>(
              builder: (context, inventory, child) {
                if (inventory.categories.isEmpty) {
                  return const Text('No categories available.');
                }
                return Wrap(
                  spacing: 8.0,
                  children: inventory.categories.map((cat) {
                    final isSelected = _selectedCategoryIds.contains(cat.id);
                    return FilterChip(
                      label: Text(cat.name),
                      selected: isSelected,
                      selectedColor: Colors.deepOrange,
                      checkmarkColor: Colors.white,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategoryIds.add(cat.id);
                          } else {
                            _selectedCategoryIds.remove(cat.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Default Supplier (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Consumer<InventoryProvider>(
              builder: (context, inventory, child) {
                if (inventory.suppliers.isEmpty) {
                  return const Text(
                    'No suppliers added. Go to "Manage Suppliers" to add one.',
                  );
                }
                return DropdownButtonFormField<String>(
                  value: _selectedSupplierId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...inventory.suppliers.map((s) {
                      return DropdownMenuItem<String>(
                        value: s.id,
                        child: Text(s.name),
                      );
                    }),
                  ],
                  onChanged: (v) => setState(() => _selectedSupplierId = v),
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.itemToEdit == null ? 'Save Item' : 'Update Item',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty || _isSaving) return;

    final inventory = Provider.of<InventoryProvider>(context, listen: false);

    setState(() {
      _isSaving = true;
    });

    // No fallback needed now. Empty list is valid (Uncategorized).

    try {
      if (widget.itemToEdit != null) {
        final updatedItem = widget.itemToEdit!.copyWith(
          name: _nameController.text.trim(),
          categoryIds: List<String>.from(_selectedCategoryIds),
          unit: _selectedUnit,
          parLevel: double.tryParse(_parController.text) ?? 0,
          defaultSupplierId: _selectedSupplierId,
        );
        await inventory.updateItem(updatedItem);
      } else {
        final newItem = GroceryItem.create(
          name: _nameController.text.trim(),
          categoryIds: List<String>.from(_selectedCategoryIds),
          unit: _selectedUnit,
          parLevel: double.tryParse(_parController.text) ?? 0,
          defaultSupplierId: _selectedSupplierId,
        );
        await inventory.addItem(newItem);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save item: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }
  }
}
