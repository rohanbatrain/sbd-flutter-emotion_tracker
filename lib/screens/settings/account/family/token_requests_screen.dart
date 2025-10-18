import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/providers/family/family_provider.dart';
import 'package:emotion_tracker/providers/family/family_models.dart' as models;
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';

class TokenRequestsScreen extends ConsumerStatefulWidget {
  final String familyId;

  const TokenRequestsScreen({Key? key, required this.familyId})
    : super(key: key);

  @override
  ConsumerState<TokenRequestsScreen> createState() =>
      _TokenRequestsScreenState();
}

class _TokenRequestsScreenState extends ConsumerState<TokenRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(tokenRequestsProvider(widget.familyId).notifier).loadRequests();
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

  Future<void> _showCreateTokenRequestDialog() async {
    final theme = Theme.of(context);
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request SBD Tokens'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_exchange),
                  suffixText: 'SBD',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'Reason (min 5 characters)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note),
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
      final amount = int.tryParse(amountController.text.trim());
      final reason = reasonController.text.trim();

      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a valid amount'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (reason.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reason must be at least 5 characters'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final success = await ref
          .read(tokenRequestsProvider(widget.familyId).notifier)
          .createRequest(amount: amount, reason: reason);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Token request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _showReviewRequestDialog(models.TokenRequest request) async {
    final commentsController = TextEditingController();

    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Review Token Request'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount: ${request.amount} SBD',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text('From: ${request.requestedByUsername}'),
              const SizedBox(height: 8),
              Text('Reason:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text(request.reason),
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
      final success = await ref
          .read(tokenRequestsProvider(widget.familyId).notifier)
          .reviewRequest(
            requestId: request.requestId,
            action: action,
            comments: commentsController.text.trim().isNotEmpty
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
    final requestsState = ref.watch(tokenRequestsProvider(widget.familyId));
    final detailsState = ref.watch(familyDetailsProvider(widget.familyId));
    final isAdmin = detailsState.family?.isAdmin ?? false;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Token Requests',
        showHamburger: false,
        showCurrency: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: !isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showCreateTokenRequestDialog,
              icon: Icon(Icons.add),
              label: Text('Request Tokens'),
              backgroundColor: theme.primaryColor,
            )
          : null,
      body: Column(
        children: [
          if (isAdmin)
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Pending (${requestsState.pendingRequests.length})'),
                Tab(text: 'My Requests'),
              ],
            ),
          Expanded(
            child: requestsState.isLoading
                ? LoadingStateWidget(message: 'Loading requests...')
                : requestsState.error != null
                ? ErrorStateWidget(
                    error: requestsState.error,
                    onRetry: () {
                      ref
                          .read(tokenRequestsProvider(widget.familyId).notifier)
                          .loadRequests();
                    },
                  )
                : isAdmin
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRequestsList(
                        requestsState.pendingRequests,
                        isAdmin,
                        theme,
                      ),
                      _buildRequestsList(
                        requestsState.myRequests,
                        false,
                        theme,
                      ),
                    ],
                  )
                : _buildRequestsList(requestsState.myRequests, false, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(
    List<models.TokenRequest> requests,
    bool showReviewButton,
    ThemeData theme,
  ) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
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
            .read(tokenRequestsProvider(widget.familyId).notifier)
            .loadRequests();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];

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
                          '${request.amount} SBD Tokens',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusChip(request.status, theme),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'From: ${request.requestedByUsername}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    request.reason,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  if (request.reviewComments != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Admin: ${request.reviewComments}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                  if (showReviewButton && request.status == 'pending') ...[
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

    switch (status) {
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
}
