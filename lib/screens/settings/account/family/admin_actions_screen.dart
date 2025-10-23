import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/providers/family/family_api_service.dart';
import 'package:emotion_tracker/providers/family/family_models.dart' as models;
import 'package:emotion_tracker/providers/family/family_provider.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';

final adminActionsProvider =
    StateNotifierProvider.family<
      AdminActionsNotifier,
      AdminActionsState,
      String
    >((ref, familyId) {
      final apiService = ref.watch(familyApiServiceProvider);
      return AdminActionsNotifier(apiService, familyId);
    });

class AdminActionsState {
  final List<models.AdminAction> actions;
  final bool isLoading;
  final String? error;

  AdminActionsState({
    required this.actions,
    required this.isLoading,
    this.error,
  });

  AdminActionsState copyWith({
    List<models.AdminAction>? actions,
    bool? isLoading,
    String? error,
  }) {
    return AdminActionsState(
      actions: actions ?? this.actions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminActionsNotifier extends StateNotifier<AdminActionsState> {
  final FamilyApiService _apiService;
  final String familyId;

  AdminActionsNotifier(this._apiService, this.familyId)
    : super(AdminActionsState(actions: [], isLoading: false));

  Future<void> loadActions({String? actionType, int? limit}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final actions = await _apiService.getAdminActions(
        familyId,
        limit: limit ?? 100,
      );
      // Filter by actionType if specified
      final filtered = actionType != null
          ? actions.where((a) => a.actionType == actionType).toList()
          : actions;
      state = state.copyWith(actions: filtered, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class AdminActionsScreen extends ConsumerStatefulWidget {
  final String familyId;

  const AdminActionsScreen({Key? key, required this.familyId})
    : super(key: key);

  @override
  ConsumerState<AdminActionsScreen> createState() => _AdminActionsScreenState();
}

class _AdminActionsScreenState extends ConsumerState<AdminActionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedFilter;
  final List<String> _filterOptions = [
    'All',
    'promote',
    'demote',
    'remove_member',
    'invite',
    'freeze_account',
    'unfreeze_account',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(adminActionsProvider(widget.familyId).notifier).loadActions();
      ref
          .read(familyShopProvider(widget.familyId).notifier)
          .loadPurchaseRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyFilter(String? filter) {
    setState(() {
      _selectedFilter = filter == 'All' ? null : filter;
    });
    ref
        .read(adminActionsProvider(widget.familyId).notifier)
        .loadActions(actionType: _selectedFilter);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Admin Dashboard',
        showHamburger: false,
        showCurrency: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: _tabController.index == 0
            ? [
                PopupMenuButton<String>(
                  icon: Icon(Icons.filter_list),
                  onSelected: _applyFilter,
                  itemBuilder: (context) => _filterOptions.map((filter) {
                    return PopupMenuItem<String>(
                      value: filter,
                      child: Row(
                        children: [
                          if (filter == _selectedFilter ||
                              (filter == 'All' && _selectedFilter == null))
                            Icon(
                              Icons.check,
                              size: 18,
                              color: theme.primaryColor,
                            ),
                          if (filter != _selectedFilter &&
                              (filter != 'All' || _selectedFilter != null))
                            const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Text(
                            filter == 'All'
                                ? 'All Actions'
                                : filter.replaceAll('_', ' ').toUpperCase(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ]
            : [],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Admin Actions'),
              Tab(text: 'Purchase Requests'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAdminActionsTab(theme),
                _buildPurchaseRequestsTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionsTab(ThemeData theme) {
    final state = ref.watch(adminActionsProvider(widget.familyId));
    return state.isLoading
        ? LoadingStateWidget(message: 'Loading admin actions...')
        : state.error != null
        ? ErrorStateWidget(
            error: state.error,
            onRetry: () {
              ref
                  .read(adminActionsProvider(widget.familyId).notifier)
                  .loadActions(actionType: _selectedFilter);
            },
          )
        : state.actions.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No admin actions logged',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(adminActionsProvider(widget.familyId).notifier)
                  .loadActions(actionType: _selectedFilter);
            },
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: state.actions.length,
              itemBuilder: (context, index) {
                final action = state.actions[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildActionIcon(action.actionType),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    action.actionType
                                        .replaceAll('_', ' ')
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'By ${action.performedByUsername}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatDate(action.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (action.targetUsername != null) ...[
                          const SizedBox(height: 8),
                          Divider(),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Target: ${action.targetUsername}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ],
                        if (action.metadata != null &&
                            action.metadata!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    action.metadata.toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildPurchaseRequestsTab(ThemeData theme) {
    final state = ref.watch(familyShopProvider(widget.familyId));
    return state.isLoading
        ? LoadingStateWidget(message: 'Loading purchase requests...')
        : state.error != null
        ? ErrorStateWidget(
            error: state.error,
            onRetry: () {
              ref
                  .read(familyShopProvider(widget.familyId).notifier)
                  .loadPurchaseRequests();
            },
          )
        : state.purchaseRequests.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No purchase requests',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(familyShopProvider(widget.familyId).notifier)
                  .loadPurchaseRequests();
            },
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: state.purchaseRequests.length,
              itemBuilder: (context, index) {
                final request = state.purchaseRequests[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shopping_bag, color: theme.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.item.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'By ${request.requester.username}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Cost: ${request.cost}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Status: ${request.status}',
                          style: TextStyle(
                            color: request.isPending
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                        if (request.isPending) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => ref
                                    .read(
                                      familyShopProvider(
                                        widget.familyId,
                                      ).notifier,
                                    )
                                    .approvePurchaseRequest(request.requestId),
                                child: Text('Approve'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () =>
                                    _showDenyDialog(request.requestId),
                                child: Text('Deny'),
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

  void _showDenyDialog(String requestId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Deny Purchase Request'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Reason (optional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(familyShopProvider(widget.familyId).notifier)
                  .denyPurchaseRequest(requestId, reason: controller.text);
              Navigator.pop(context);
            },
            child: Text('Deny'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(String actionType) {
    IconData icon;
    Color color;

    switch (actionType) {
      case 'promote':
        icon = Icons.arrow_upward;
        color = Colors.green;
        break;
      case 'demote':
        icon = Icons.arrow_downward;
        color = Colors.orange;
        break;
      case 'remove_member':
        icon = Icons.person_remove;
        color = Colors.red;
        break;
      case 'invite':
        icon = Icons.mail;
        color = Colors.blue;
        break;
      case 'freeze_account':
        icon = Icons.lock;
        color = Colors.red;
        break;
      case 'unfreeze_account':
        icon = Icons.lock_open;
        color = Colors.green;
        break;
      default:
        icon = Icons.admin_panel_settings;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
