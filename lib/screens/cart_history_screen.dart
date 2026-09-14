import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/shopping_list_model.dart';
import '../providers/cart_provider.dart';
import 'cart_details_screen.dart';

class CartHistoryScreen extends StatelessWidget {
  const CartHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping History')),
      body: SafeArea(top: false, child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Cart Section
            if (cartProvider.activeCart != null) ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Active Cart',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              _CartListTile(
                list: cartProvider.activeCart!,
                itemCount: cartProvider
                    .getItemsForList(cartProvider.activeCart!.id)
                    .length,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CartDetailsScreen(
                        listId: cartProvider.activeCart!.id,
                      ),
                    ),
                  );
                },
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('No Active Cart')),
              ),
            ],

            const Divider(),

            // Archived Carts Section
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Past Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            if (cartProvider.archivedLists.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No past orders.'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cartProvider.archivedLists.length,
                itemBuilder: (context, index) {
                  final list = cartProvider.archivedLists[index];
                  final itemCount = cartProvider.getItemsForList(list.id).length;
                  
                  return Dismissible(
                    key: Key(list.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.redAccent,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1A1A1A),
                          title: const Text('Delete Order?'),
                          content: const Text('This will permanently remove this shopping history record.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('CANCEL'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              child: const Text('DELETE', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      cartProvider.deleteShoppingList(list.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Order history deleted'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    },
                    child: _CartListTile(
                      list: list,
                      itemCount: itemCount,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CartDetailsScreen(listId: list.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      )),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: const Text('New Cart'),
        onPressed: () {
          // If active cart exists, warn before archiving?
          // Provider handles archiving, but maybe UI prompt?
          // Just call create for speed MVP.
          cartProvider.createNewCart();
        },
      ),
    );
  }
}

class _CartListTile extends StatelessWidget {
  final ShoppingList list;
  final int itemCount;
  final VoidCallback onTap;

  const _CartListTile({
    required this.list,
    required this.itemCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.white10,
        child: Icon(Icons.shopping_bag, color: Colors.white),
      ),
      title: Text(DateFormat('EEEE, MMM d, y').format(list.createdAt)),
      subtitle: Text('$itemCount items • ${list.status.name}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
