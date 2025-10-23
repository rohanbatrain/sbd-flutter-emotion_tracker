import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/providers/family/family_provider.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/providers/family/family_models.dart' as models;
import 'package:emotion_tracker/screens/settings/account/family/family_avatars_tab.dart';
import 'package:emotion_tracker/screens/settings/account/family/family_banners_tab.dart';
import 'package:emotion_tracker/screens/settings/account/family/family_themes_tab.dart';
import 'package:emotion_tracker/screens/settings/account/family/family_bundles_tab.dart';

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
    _tabController = TabController(length: 5, vsync: this);
    Future.microtask(() {
      ref
          .read(familyShopProvider(widget.familyId).notifier)
          .loadPaymentOptions();
      ref.read(familyShopProvider(widget.familyId).notifier).loadShopItems();
      ref.read(familyShopProvider(widget.familyId).notifier).loadOwnedItems();
      ref
          .read(familyShopProvider(widget.familyId).notifier)
          .loadPurchaseHistory();
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

  Future<void> _showPurchaseDialog(models.ShopItem item) async {
    final theme = Theme.of(context);
    final quantityController = TextEditingController(text: '1');
    final reasonController = TextEditingController();

    final shopNotifier = ref.read(familyShopProvider(widget.familyId).notifier);
    final availableOptions = shopNotifier.getAvailablePaymentOptions();
    final familyWalletOption = shopNotifier.getFamilyWalletOption();

    String? selectedPaymentOptionId = familyWalletOption?.sourceId;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with item info
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (item.imageUrl != null)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.05,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getItemIcon(item.itemType),
                            size: 40,
                            color: theme.primaryColor,
                          ),
                        )
                      else
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.05,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getItemIcon(item.itemType),
                            size: 40,
                            color: theme.primaryColor,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        item.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${item.price} SBD',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quantity
                      Text(
                        'Quantity',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter quantity',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.shopping_cart),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Payment Method
                      Text(
                        'Payment Method',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...availableOptions.map(
                        (option) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedPaymentOptionId == option.sourceId
                                  ? theme.primaryColor
                                  : theme.dividerColor,
                              width: selectedPaymentOptionId == option.sourceId
                                  ? 2
                                  : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: selectedPaymentOptionId == option.sourceId
                                ? theme.primaryColor.withOpacity(0.05)
                                : null,
                          ),
                          child: RadioListTile<String>(
                            title: Text(
                              option.label,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: option.description != null
                                ? Text(
                                    option.description!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.hintColor,
                                    ),
                                  )
                                : null,
                            value: option.sourceId,
                            groupValue: selectedPaymentOptionId,
                            onChanged: (value) {
                              setState(() => selectedPaymentOptionId = value);
                            },
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Family wallet notice
                      if (selectedPaymentOptionId ==
                          familyWalletOption?.sourceId) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'This purchase requires admin approval before it will be processed.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Reason (optional)
                      Text(
                        'Reason (Optional)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: 'Why are you purchasing this item?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedPaymentOptionId != null
                              ? () => Navigator.of(context).pop(true)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text('Purchase'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true && selectedPaymentOptionId != null) {
      final quantity = int.tryParse(quantityController.text.trim()) ?? 1;
      final useFamilyWallet =
          selectedPaymentOptionId == familyWalletOption?.sourceId;

      if (quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a valid quantity'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final purchaseResult = await ref
            .read(familyShopProvider(widget.familyId).notifier)
            .purchaseItem(
              itemId: item.itemId,
              itemType: item.itemType,
              quantity: quantity,
              useFamilyWallet: useFamilyWallet,
              paymentSourceId: selectedPaymentOptionId,
              reason: reasonController.text.trim().isNotEmpty
                  ? reasonController.text.trim()
                  : null,
            );

        if (purchaseResult['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Purchase successful!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (purchaseResult['status'] == 'pending') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Purchase request submitted for approval.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        print('[FAMILY_SHOP] Purchase error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
            labelColor: theme.primaryColor,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
            indicatorColor: theme.primaryColor,
            indicator: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Avatars'),
              Tab(text: 'Banners'),
              Tab(text: 'Themes'),
              Tab(text: 'Bundles'),
              Tab(text: 'History'),
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
                      FamilyAvatarsTab(
                        familyId: widget.familyId,
                        onPurchase: _showPurchaseDialog,
                      ),
                      FamilyBannersTab(
                        familyId: widget.familyId,
                        onPurchase: _showPurchaseDialog,
                      ),
                      FamilyThemesTab(
                        familyId: widget.familyId,
                        onPurchase: _showPurchaseDialog,
                      ),
                      FamilyBundlesTab(
                        familyId: widget.familyId,
                        onPurchase: _showPurchaseDialog,
                      ),
                      _buildHistoryTab(theme, shopState),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme, FamilyShopState shopState) {
    if (shopState.purchaseHistory.isEmpty) {
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

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(familyShopProvider(widget.familyId).notifier)
            .loadPurchaseHistory();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: shopState.purchaseHistory.length,
        itemBuilder: (context, index) {
          final historyItem = shopState.purchaseHistory[index];

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
                      _getItemIcon(historyItem.itemType),
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
                          historyItem.itemName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type: ${historyItem.itemType.toUpperCase()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Purchased: ${_formatDate(historyItem.purchasedAt.toIso8601String())}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cost: ${historyItem.cost} SBD (${historyItem.paymentMethod})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: historyItem.wasApproved
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      historyItem.wasApproved ? 'APPROVED' : 'DIRECT',
                      style: TextStyle(
                        color: historyItem.wasApproved
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
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
