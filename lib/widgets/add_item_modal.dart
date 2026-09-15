import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/grocery_item.dart';
import '../providers/inventory_provider.dart';
import 'avatar_icons.dart';

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
  String? _selectedStorageTypeId;
  String? _selectedAvatarIconName;
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
      _selectedStorageTypeId = widget.itemToEdit!.storageTypeId;
      _selectedAvatarIconName = widget.itemToEdit!.avatarIconName;
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
            const SizedBox(height: 16),
            const Text(
              'Storage Type (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Consumer<InventoryProvider>(
              builder: (context, inventory, child) {
                if (inventory.storageTypes.isEmpty) {
                  return const Text(
                    'No storage types added. Go to "Manage Storage Types" to add one.',
                  );
                }
                return DropdownButtonFormField<String>(
                  value: _selectedStorageTypeId,
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
                    ...inventory.storageTypes.map((t) {
                      return DropdownMenuItem<String>(
                        value: t.id,
                        child: Text(t.name),
                      );
                    }),
                  ],
                  onChanged: (v) => setState(() => _selectedStorageTypeId = v),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Avatar Icon (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: _buildAvatarPreview(),
                    ),
                    if (_selectedAvatarIconName != null)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedAvatarIconName = null),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF1E1E1E),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _showIconPicker,
                  icon: const Icon(Icons.grid_view_rounded, size: 16),
                  label: const Text('Choose Icon'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
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
                              widget.itemToEdit == null
                                  ? 'Save Item'
                                  : 'Update Item',
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Shows the currently-used icon: the picked override if there is one,
  // otherwise a plain letter-initials avatar (not the emoji auto-match the
  // home screen falls back to) — updates live as the name is typed, and
  // reverts to this whenever the custom icon is removed.
  Widget _buildAvatarPreview() {
    final custom = _selectedAvatarIconName;
    if (custom != null) {
      final icon = kAvatarIconChoices[custom];
      if (icon != null) {
        return Icon(icon, color: Colors.deepOrange.shade200, size: 22);
      }
      return Text(custom, style: const TextStyle(fontSize: 20));
    }
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _nameController,
      builder: (context, value, child) {
        return Text(
          initialsForItemName(value.text),
          style: TextStyle(
            color: Colors.deepOrange.shade200,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        );
      },
    );
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              height: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose an Icon',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _pickerSectionLabel('Emoji'),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                ),
                            itemCount: kAvatarEmojiChoices.length,
                            itemBuilder: (context, index) {
                              final emoji = kAvatarEmojiChoices[index];
                              final selected =
                                  _selectedAvatarIconName == emoji;
                              return GestureDetector(
                                onTap: () {
                                  setState(
                                    () => _selectedAvatarIconName = emoji,
                                  );
                                  Navigator.pop(ctx);
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selected
                                        ? Colors.deepOrange.withOpacity(0.25)
                                        : Colors.white.withOpacity(0.05),
                                    border: Border.all(
                                      color: selected
                                          ? Colors.deepOrange
                                          : Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              );
                            },
                          ),
                          _pickerSectionLabel('Icons'),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                ),
                            itemCount: kAvatarIconChoices.length,
                            itemBuilder: (context, index) {
                              final entry = kAvatarIconChoices.entries
                                  .elementAt(index);
                              final selected =
                                  _selectedAvatarIconName == entry.key;
                              return GestureDetector(
                                onTap: () {
                                  setState(
                                    () =>
                                        _selectedAvatarIconName = entry.key,
                                  );
                                  Navigator.pop(ctx);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selected
                                        ? Colors.deepOrange.withOpacity(0.25)
                                        : Colors.white.withOpacity(0.05),
                                    border: Border.all(
                                      color: selected
                                          ? Colors.deepOrange
                                          : Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Icon(
                                    entry.value,
                                    color: selected
                                        ? Colors.deepOrange.shade200
                                        : Colors.white70,
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pickerSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Colors.white.withOpacity(0.4),
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
          storageTypeId: _selectedStorageTypeId,
          avatarIconName: _selectedAvatarIconName,
        );
        await inventory.updateItem(updatedItem);
      } else {
        final newItem = GroceryItem.create(
          name: _nameController.text.trim(),
          categoryIds: List<String>.from(_selectedCategoryIds),
          unit: _selectedUnit,
          parLevel: double.tryParse(_parController.text) ?? 0,
          defaultSupplierId: _selectedSupplierId,
          storageTypeId: _selectedStorageTypeId,
          avatarIconName: _selectedAvatarIconName,
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
