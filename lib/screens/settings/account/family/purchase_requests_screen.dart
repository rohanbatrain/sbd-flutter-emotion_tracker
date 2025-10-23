import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/providers/family/family_provider.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';

class PurchaseRequestsScreen extends ConsumerStatefulWidget {
  final String familyId;

  const PurchaseRequestsScreen({Key? key, required this.familyId})
    : super(key: key);

  @override
  ConsumerState<PurchaseRequestsScreen> createState() =>
      _PurchaseRequestsScreenState();
}

class _PurchaseRequestsScreenState extends ConsumerState<PurchaseRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref
          .read(familyShopProvider(widget.familyId).notifier)
          .loadPurchaseRequests();
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

  Future<void> _showReviewRequestDialog(Map<String, dynamic> request) async {
    final commentsController = TextEditingController();
    final requestId = request['request_id'] as String;
    final itemName = request['item_name'] as String? ?? 'Unknown Item';
    final cost = request['cost'] as int? ?? 0;
    final requesterUsername =
        request['requester_username'] as String? ?? 'Unknown';

    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Review Purchase Request'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Item: $itemName',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text('Cost: $cost SBD'),
              const SizedBox(height: 8),
              Text('Requested by: $requesterUsername'),
              const SizedBox(height: 16),
              TextField(
                controller: commentsController,
                maxLines: 3,
                maxLength: 1000,
                decoration: InputDecoration(
                  labelText: 'Admin Comments (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.comment),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop('deny'),
            child: Text('Deny'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop('approve'),
            child: Text('Approve'),
          ),
        ],
      ),
    );

    if (action != null && action.isNotEmpty) {
      final success = action == 'approve'
          ? await ref
                .read(familyShopProvider(widget.familyId).notifier)
                .approvePurchaseRequest(requestId)
          : await ref
                .read(familyShopProvider(widget.familyId).notifier)
                .denyPurchaseRequest(
                  requestId,
                  reason: commentsController.text.trim().isNotEmpty
                      ? commentsController.text.trim()
                      : null,
                );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${action}d successfully!'),
            backgroundColor: action == 'approve' ? Colors.green : Colors.red,
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
    final isAdmin = detailsState.family?.isAdmin ?? false;

    // Only admins can see this screen
    if (!isAdmin) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Purchase Requests',
          showHamburger: false,
          showCurrency: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Admin access required',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Purchase Requests',
        showHamburger: false,
        showCurrency: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                text:
                    'Pending (${shopState.purchaseRequests.where((r) => r['status'] == 'pending').length})',
              ),
              Tab(text: 'All Requests (${shopState.purchaseRequests.length})'),
            ],
          ),
          Expanded(
            child: shopState.isLoading
                ? LoadingStateWidget(message: 'Loading requests...')
                : shopState.error != null
                ? ErrorStateWidget(
                    error: shopState.error!,
                    onRetry: () {
                      ref
                          .read(familyShopProvider(widget.familyId).notifier)
                          .loadPurchaseRequests();
                    },
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRequestsList(
                        shopState.purchaseRequests
                            .where((r) => r['status'] == 'pending')
                            .toList(),
                        theme,
                      ),
                      _buildRequestsList(shopState.purchaseRequests, theme),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(
    List<Map<String, dynamic>> requests,
    ThemeData theme,
  ) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No requests',
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
            .loadPurchaseRequests();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          final itemName = request['item_name'] as String? ?? 'Unknown Item';
          final itemType = request['item_type'] as String? ?? '';
          final cost = request['cost'] as int? ?? 0;
          final status = request['status'] as String? ?? 'pending';
          final requesterUsername =
              request['requester_username'] as String? ?? 'Unknown';
          final createdAt = request['created_at'] as String?;
          final denialReason = request['denial_reason'] as String?;

          return Card(
            margin: EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          itemName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusChip(status, theme),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Type: $itemType',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cost: $cost SBD',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Requested by: $requesterUsername',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Requested: ${_formatDate(createdAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                  if (denialReason != null && denialReason.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: Text(
                        'Denial reason: $denialReason',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                  if (status == 'pending') ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () => _showReviewRequestDialog(request),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Review'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case 'denied':
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange.shade700;
        icon = Icons.schedule;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
