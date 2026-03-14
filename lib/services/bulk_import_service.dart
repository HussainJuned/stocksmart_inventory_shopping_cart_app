import 'dart:convert';
import '../models/grocery_item.dart';
import '../models/category_model.dart';
import '../models/supplier_model.dart';
import '../repositories/grocery_repository.dart';

class BulkImportService {
  final GroceryRepository repository;

  BulkImportService(this.repository);

  Future<void> importFromJson(String jsonString) async {
    final Map<String, dynamic> data = jsonDecode(jsonString);

    // 1. Import Categories
    final List<dynamic> catData = data['categories'] ?? [];
    final Map<String, String> categoryNameToId = {};

    // Fetch existing categories to avoid duplicates
    final existingCats = repository.getCategories();
    for (var cat in existingCats) {
      categoryNameToId[cat.name.toLowerCase()] = cat.id;
    }

    for (var catMap in catData) {
      final name = catMap['name'] as String;
      final nameLower = name.toLowerCase();
      if (!categoryNameToId.containsKey(nameLower)) {
        final newCat = Category.create(
          name: name,
          color: catMap['color'] ?? '#FF9900',
          sortOrder: existingCats.length + categoryNameToId.length,
        );
        await repository.addCategory(newCat);
        categoryNameToId[nameLower] = newCat.id;
      }
    }

    // 2. Import Suppliers
    final List<dynamic> supplierData = data['suppliers'] ?? [];
    final Map<String, String> supplierNameToId = {};

    final existingSuppliers = repository.getSuppliers();
    for (var s in existingSuppliers) {
      supplierNameToId[s.name.toLowerCase()] = s.id;
    }

    for (var sMap in supplierData) {
      final name = sMap['name'] as String;
      final nameLower = name.toLowerCase();
      if (!supplierNameToId.containsKey(nameLower)) {
        final newSupplier = Supplier.create(name: name);
        await repository.addSupplier(newSupplier);
        supplierNameToId[nameLower] = newSupplier.id;
      }
    }

    // 3. Import Items
    final List<dynamic> itemData = data['items'] ?? [];
    for (var iMap in itemData) {
      final name = iMap['name'] as String;

      // Resolve Category IDs
      final List<String> categoryNames = List<String>.from(
        iMap['categoryNames'] ?? [],
      );
      final List<String> categoryIds = categoryNames
          .map((n) => categoryNameToId[n.toLowerCase()])
          .whereType<String>()
          .toList();

      // Resolve Supplier ID
      final String? sName = iMap['supplierName'];
      final String? supplierId = sName != null
          ? supplierNameToId[sName.toLowerCase()]
          : null;

      final newItem = GroceryItem.create(
        name: name,
        categoryIds: categoryIds,
        defaultSupplierId: supplierId,
        unit: iMap['unit'] ?? 'kg',
        parLevel: (iMap['parLevel'] as num?)?.toDouble() ?? 5.0,
      );

      await repository.addItem(newItem);
    }
  }
}
