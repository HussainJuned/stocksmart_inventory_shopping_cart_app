import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
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

  InputDecoration _fieldDecoration({String? label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
        top: 12,
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
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.itemToEdit == null ? 'Add New Item' : 'Edit Item',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _showIconPicker,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
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
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1E1E1E),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (_selectedAvatarIconName != null)
                        Positioned(
                          top: -4,
                          left: -4,
                          child: GestureDetector(
                            onTap: () => setState(
                              () => _selectedAvatarIconName = null,
                            ),
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
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: _fieldDecoration(label: 'Name'),
                    autofocus: widget.itemToEdit == null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _parController,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration(label: 'Par Level'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: Consumer<InventoryProvider>(
                    builder: (context, inventory, child) {
                      final names = inventory.units
                          .map((u) => u.name)
                          .toList();
                      // Keep a unit no longer in the managed list (e.g.
                      // removed after this item was created) selectable so
                      // the dropdown doesn't crash on an unmatched value.
                      if (!names.contains(_selectedUnit)) {
                        names.insert(0, _selectedUnit);
                      }
                      return DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        isExpanded: true,
                        decoration: _fieldDecoration(label: 'Unit'),
                        items: names
                            .map(
                              (e) =>
                                  DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedUnit = v!),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<InventoryProvider>(
              builder: (context, inventory, child) {
                if (inventory.categories.isEmpty) {
                  return Text(
                    'No categories available.',
                    style: TextStyle(color: Colors.white.withOpacity(0.4)),
                  );
                }
                final selectedNames = inventory.categories
                    .where((c) => _selectedCategoryIds.contains(c.id))
                    .map((c) => c.name)
                    .join(', ');
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showCategoryPicker(inventory.categories),
                  child: InputDecorator(
                    decoration: _fieldDecoration(label: 'Categories')
                        .copyWith(
                          suffixIcon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white54,
                          ),
                        ),
                    child: Text(
                      selectedNames.isEmpty ? 'None' : selectedNames,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selectedNames.isEmpty
                            ? Colors.white38
                            : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Consumer<InventoryProvider>(
              builder: (context, inventory, child) {
                if (inventory.suppliers.isEmpty) {
                  return Text(
                    'No suppliers added.',
                    style: TextStyle(color: Colors.white.withOpacity(0.4)),
                  );
                }
                return DropdownButtonFormField<String>(
                  value: _selectedSupplierId,
                  isExpanded: true,
                  decoration: _fieldDecoration(label: 'Supplier'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...inventory.suppliers.map((s) {
                      return DropdownMenuItem<String>(
                        value: s.id,
                        child: Text(s.name, overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                  onChanged: (v) => setState(() => _selectedSupplierId = v),
                );
              },
            ),
            const SizedBox(height: 16),
            Consumer<InventoryProvider>(
              builder: (context, inventory, child) {
                if (inventory.storageTypes.isEmpty) {
                  return Text(
                    'No storage types added.',
                    style: TextStyle(color: Colors.white.withOpacity(0.4)),
                  );
                }
                return DropdownButtonFormField<String>(
                  value: _selectedStorageTypeId,
                  isExpanded: true,
                  decoration: _fieldDecoration(label: 'Storage Type'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...inventory.storageTypes.map((t) {
                      return DropdownMenuItem<String>(
                        value: t.id,
                        child: Text(t.name, overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedStorageTypeId = v),
                );
              },
            ),
            const SizedBox(height: 28),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  void _showCategoryPicker(List<Category> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: categories.map((cat) {
                          final selected = _selectedCategoryIds.contains(
                            cat.id,
                          );
                          return CheckboxListTile(
                            value: selected,
                            title: Text(cat.name),
                            activeColor: Colors.deepOrange,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedCategoryIds.add(cat.id);
                                } else {
                                  _selectedCategoryIds.remove(cat.id);
                                }
                              });
                              setSheetState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Shows the currently-used icon: the picked override if there is one,
  // otherwise whatever the home screen would actually show by default —
  // the emoji auto-matched from the item name, or letter-initials if no
  // keyword matches. Updates live as the name is typed, and reverts to the
  // auto-match whenever the custom icon is removed, so this preview never
  // disagrees with what the item's tile displays.
  Widget _buildAvatarPreview() {
    final custom = _selectedAvatarIconName;
    if (custom != null && custom != kInitialsAvatarKey) {
      final icon = kAvatarIconChoices[custom];
      if (icon != null) {
        return Icon(icon, color: Colors.deepOrange.shade200, size: 22);
      }
      return Text(custom, style: const TextStyle(fontSize: 20));
    }
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _nameController,
      builder: (context, value, child) {
        final autoEmoji = custom == kInitialsAvatarKey
            ? null
            : emojiForItemName(value.text);
        if (autoEmoji != null) {
          return Text(autoEmoji, style: const TextStyle(fontSize: 20));
        }
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
    final searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final query = searchController.text.trim().toLowerCase();
            final filteredEmoji = query.isEmpty
                ? kAvatarEmojiChoices
                : kAvatarEmojiChoices
                      .where(
                        (emoji) => (kKeywordsForEmoji[emoji] ?? const [])
                            .any((keyword) => keyword.contains(query)),
                      )
                      .toList();
            final filteredIcons = query.isEmpty
                ? kAvatarIconChoices.entries.toList()
                : kAvatarIconChoices.entries
                      .where(
                        (entry) =>
                            entry.key.replaceAll('_', ' ').contains(query),
                      )
                      .toList();
            // If nothing's explicitly picked, this is the emoji the item is
            // actually showing right now (auto-matched from its name) —
            // mark it so it's clear that's the current default.
            final autoEmoji = _selectedAvatarIconName == null
                ? emojiForItemName(_nameController.text)
                : null;

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
                      const SizedBox(height: 10),
                      TextField(
                        controller: searchController,
                        onChanged: (_) => setSheetState(() {}),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Search icons, e.g. "pork"',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                          ),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    searchController.clear();
                                    setSheetState(() {});
                                  },
                                ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (query.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Row(
                                    children: [
                                      Builder(
                                        builder: (context) {
                                          final selected =
                                              _selectedAvatarIconName ==
                                              kInitialsAvatarKey;
                                          return GestureDetector(
                                            onTap: () {
                                              setState(
                                                () => _selectedAvatarIconName =
                                                    kInitialsAvatarKey,
                                              );
                                              Navigator.pop(ctx);
                                            },
                                            child: Container(
                                              width: 44,
                                              height: 44,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: selected
                                                    ? Colors.deepOrange
                                                          .withOpacity(0.25)
                                                    : Colors.white
                                                          .withOpacity(0.05),
                                                border: Border.all(
                                                  color: selected
                                                      ? Colors.deepOrange
                                                      : Colors.white
                                                            .withOpacity(0.1),
                                                ),
                                              ),
                                              child: const Text(
                                                'AB',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white70,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Plain text initials — clears any '
                                          'auto-assigned icon',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (filteredEmoji.isNotEmpty) ...[
                                _pickerSectionLabel('Emoji'),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 6,
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 10,
                                      ),
                                  itemCount: filteredEmoji.length,
                                  itemBuilder: (context, index) {
                                    final emoji = filteredEmoji[index];
                                    final selected =
                                        _selectedAvatarIconName == emoji;
                                    final isAutoDefault =
                                        !selected && emoji == autoEmoji;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(
                                          () =>
                                              _selectedAvatarIconName = emoji,
                                        );
                                        Navigator.pop(ctx);
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: selected
                                              ? Colors.deepOrange.withOpacity(
                                                  0.25,
                                                )
                                              : Colors.white.withOpacity(
                                                  0.05,
                                                ),
                                          border: Border.all(
                                            color: selected
                                                ? Colors.deepOrange
                                                : isAutoDefault
                                                ? Colors.amber.shade300
                                                : Colors.white.withOpacity(
                                                    0.1,
                                                  ),
                                          ),
                                        ),
                                        child: Text(
                                          emoji,
                                          style: const TextStyle(
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                              if (filteredIcons.isNotEmpty) ...[
                                _pickerSectionLabel('Icons'),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 6,
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 10,
                                      ),
                                  itemCount: filteredIcons.length,
                                  itemBuilder: (context, index) {
                                    final entry = filteredIcons[index];
                                    final selected =
                                        _selectedAvatarIconName == entry.key;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(
                                          () => _selectedAvatarIconName =
                                              entry.key,
                                        );
                                        Navigator.pop(ctx);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: selected
                                              ? Colors.deepOrange.withOpacity(
                                                  0.25,
                                                )
                                              : Colors.white.withOpacity(
                                                  0.05,
                                                ),
                                          border: Border.all(
                                            color: selected
                                                ? Colors.deepOrange
                                                : Colors.white.withOpacity(
                                                    0.1,
                                                  ),
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
                              if (filteredEmoji.isEmpty &&
                                  filteredIcons.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 24),
                                  child: Text(
                                    'No icons match "$query".',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                  ),
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
