import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/providers/family/family_provider.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';

class FamilyShopScreen extends ConsumerStatefulWidget {
  final String familyId;

  const FamilyShopScreen({Key? key, required this.familyId}) : super(key: key);

  @override
  ConsumerState<FamilyShopScreen> createState() => _FamilyShopScreenState();
}

class _FamilyShopScreenState extends ConsumerState<FamilyShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref
          .read(familyShopProvider(widget.familyId).notifier)
          .loadPaymentOptions();
      ref.read(familyShopProvider(widget.familyId).notifier).loadOwnedItems();
      ref
          .read(familyDetailsProvider(widget.familyId).notifier)
          .loadFamilyDetails();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showPurchaseDialog(Map<String, dynamic> item) async {
    final theme = Theme.of(context);
    final itemName = item['name'] as String? ?? 'Unknown Item';
    final price = item['price'] as int? ?? 0;
    final description = item['description'] as String? ?? '';

    final quantityController = TextEditingController(text: '1');
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase $itemName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (description.isNotEmpty) ...[
                Text(description),
                const SizedBox(height: 16),
              ],
              Text(
                'Price: $price SBD per item',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_cart),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'Reason for purchase (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'This purchase requires admin approval before it will be processed.',
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Submit Request'),
          ),
        ],
      ),
    );

    if (result == true) {
      final quantity = int.tryParse(quantityController.text.trim()) ?? 1;

      if (quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a valid quantity'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // For now, we'll create a purchase request instead of direct purchase
      // This would need to be implemented in the backend API
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase request feature coming soon!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shopState = ref.watch(familyShopProvider(widget.familyId));
    final detailsState = ref.watch(familyDetailsProvider(widget.familyId));
    final account = detailsState.sbdAccount;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Family Shop',
        showHamburger: false,
        showCurrency: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Family Wallet Balance Card
          if (account != null)
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Family Wallet',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${account.balance} SBD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (account.isFrozen)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'FROZEN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Browse Items'),
              Tab(text: 'My Items'),
              Tab(text: 'Purchase History'),
            ],
          ),

          // Tab Content
          Expanded(
            child: shopState.isLoading
                ? LoadingStateWidget(message: 'Loading shop...')
                : shopState.error != null
                ? ErrorStateWidget(
                    error: shopState.error!,
                    onRetry: () {
                      ref
                          .read(familyShopProvider(widget.familyId).notifier)
                          .loadPaymentOptions();
                      ref
                          .read(familyShopProvider(widget.familyId).notifier)
                          .loadOwnedItems();
                    },
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBrowseTab(theme, shopState),
                      _buildOwnedTab(theme, shopState),
                      _buildHistoryTab(theme),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseTab(ThemeData theme, FamilyShopState shopState) {
    // Mock items for demonstration - in real app, this would come from API
    final mockItems = [
      {
        'id': 'avatar_001',
        'name': 'Happy Panda Avatar',
        'type': 'avatar',
        'price': 50,
        'description': 'A cute panda avatar to brighten your day!',
        'image_url': null,
      },
      {
        'id': 'banner_001',
        'name': 'Ocean Sunset Banner',
        'type': 'banner',
        'price': 75,
        'description': 'Beautiful ocean sunset banner for your profile.',
        'image_url': null,
      },
      {
        'id': 'theme_001',
        'name': 'Forest Theme',
        'type': 'theme',
        'price': 100,
        'description': 'Relaxing forest theme with nature sounds.',
        'image_url': null,
      },
    ];

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(familyShopProvider(widget.familyId).notifier)
            .loadPaymentOptions();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: mockItems.length,
        itemBuilder: (context, index) {
          final item = mockItems[index];
          final isOwned = shopState.ownedItems.any(
            (owned) =>
                owned['item_id'] == item['id'] &&
                owned['item_type'] == item['type'],
          );

          return Card(
            margin: EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  // Item Icon/Image placeholder
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getItemIcon(item['type'] as String),
                      color: theme.primaryColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['description'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${item['price']} SBD',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: isOwned ? null : () => _showPurchaseDialog(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOwned
                          ? Colors.grey
                          : theme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isOwned ? 'Owned' : 'Buy'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOwnedTab(ThemeData theme, FamilyShopState shopState) {
    if (shopState.ownedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No items owned yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Purchase items from the shop to see them here',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(familyShopProvider(widget.familyId).notifier)
            .loadOwnedItems();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: shopState.ownedItems.length,
        itemBuilder: (context, index) {
          final item = shopState.ownedItems[index];
          final itemName = item['name'] as String? ?? 'Unknown Item';
          final itemType = item['type'] as String? ?? '';
          final acquiredAt = item['acquired_at'] as String?;

          return Card(
            margin: EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getItemIcon(itemType),
                      color: theme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type: ${itemType.toUpperCase()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        if (acquiredAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Acquired: ${_formatDate(acquiredAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'OWNED',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme) {
    // Mock purchase history - in real app, this would come from API
    final mockHistory = <Map<String, dynamic>>[];

    if (mockHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No purchase history',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: mockHistory.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Purchase history item ${index + 1}'),
          ),
        );
      },
    );
  }

  IconData _getItemIcon(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'avatar':
        return Icons.person;
      case 'banner':
        return Icons.flag;
      case 'theme':
        return Icons.palette;
      case 'bundle':
        return Icons.inventory;
      default:
        return Icons.shopping_bag;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}
