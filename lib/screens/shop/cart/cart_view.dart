import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/shop_cart_provider.dart';

class CartView extends ConsumerStatefulWidget {
  const CartView({Key? key}) : super(key: key);

  @override
  ConsumerState<CartView> createState() => _CartViewState();
}

class _CartViewState extends ConsumerState<CartView> {
  late Future<List<Map<String, dynamic>>> _cartFuture;
  String? _checkoutMessage;
  String? _transactionId;

  @override
  void initState() {
    super.initState();
    _refreshCart();
  }

  @override
  void dispose() {
    _checkoutMessage = null;
    _transactionId = null;
    super.dispose();
  }

  void _refreshCart() {
    setState(() {
      _cartFuture = ref.read(shopCartProvider).getCart();
      // Do NOT clear _checkoutMessage/_transactionId here
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = ref.read(shopCartProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 8, right: 8, bottom: 0),
      child: Column(
        children: [
          if (_checkoutMessage != null && _transactionId != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _checkoutMessage!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text(
                        'Transaction ID: ',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      SelectableText(
                        _transactionId!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Cart',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _cartFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: \\${snapshot.error}'));
                }
                final cartItems = snapshot.data ?? [];
                if (cartItems.isEmpty) {
                  return const Center(child: Text('Your cart is empty.'));
                }
                int totalPrice = cartItems.fold<int>(
                  0,
                  (sum, item) => sum + ((item['price'] ?? 0) as int),
                );
                return ListView.separated(
                  itemCount: cartItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    final type = item['type'] ?? '';
                    final name = item['name'] ?? '';
                    final price = item['price'] ?? 0;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        child: Icon(
                          _iconForType(type),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        type,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$price SBD',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            tooltip: 'Remove',
                            onPressed: () async {
                              try {
                                await cartProvider.removeFromCart(
                                  itemId: _getItemId(item),
                                  itemType: type,
                                );
                                _refreshCart();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to remove: $e'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _cartFuture,
                  builder: (context, snapshot) {
                    final cartItems = snapshot.data ?? [];
                    int totalPrice = cartItems.fold<int>(
                      0,
                      (sum, item) => sum + ((item['price'] ?? 0) as int),
                    );
                    return Text(
                      'Total: $totalPrice SBD',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    );
                  },
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_forever),
                      tooltip: 'Clear Cart',
                      onPressed: () async {
                        try {
                          await cartProvider.clearCart();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cart cleared.')),
                          );
                          _refreshCart();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to clear cart: $e')),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.payment),
                      label: const Text('Checkout'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          final result = await cartProvider.checkoutCart();
                          setState(() {
                            _checkoutMessage =
                                '🎉 Checkout successful! Congratulations on your purchase.';
                            _transactionId = result['transaction_id'] ?? '';
                          });
                          _refreshCart();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Checkout failed: $e')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'theme':
        return Icons.palette;
      case 'avatar':
        return Icons.person;
      case 'bundle':
        return Icons.all_inbox;
      case 'banner':
        return Icons.flag;
      default:
        return Icons.shopping_cart;
    }
  }

  String _getItemId(Map<String, dynamic> item) {
    switch (item['type']) {
      case 'theme':
        return item['theme_id'] ?? '';
      case 'avatar':
        return item['avatar_id'] ?? '';
      case 'bundle':
        return item['bundle_id'] ?? '';
      case 'banner':
        return item['banner_id'] ?? '';
      default:
        return item['id'] ?? '';
    }
  }

  // Helper to get all item ids in the cart for use in shop UI
  static Set<String> extractCartItemIds(List<Map<String, dynamic>> cartItems) {
    final ids = <String>{};
    for (final item in cartItems) {
      switch (item['type']) {
        case 'theme':
          ids.add(item['theme_id'] ?? '');
          break;
        case 'avatar':
          ids.add(item['avatar_id'] ?? '');
          break;
        case 'bundle':
          ids.add(item['bundle_id'] ?? '');
          break;
        case 'banner':
          ids.add(item['banner_id'] ?? '');
          break;
        default:
          ids.add(item['id'] ?? '');
      }
    }
    return ids;
  }
}
