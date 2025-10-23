import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/providers/family/family_provider.dart';
import 'package:emotion_tracker/providers/family/family_models.dart' as models;
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/screens/settings/account/family/family_details_screen.dart';
import 'package:emotion_tracker/screens/settings/account/family/received_invitations_screen.dart';
import 'package:emotion_tracker/providers/family/received_invitations_provider.dart';

class FamilyScreenV1 extends ConsumerStatefulWidget {
  const FamilyScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<FamilyScreenV1> createState() => _FamilyScreenV1State();
}

class _FamilyScreenV1State extends ConsumerState<FamilyScreenV1> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(familyListProvider.notifier).loadFamilies();
    });
  }

  Future<void> _showCreateFamilyDialog() async {
    final theme = Theme.of(context);
    final nameController = TextEditingController();

    // Require a non-empty family name. Use StatefulBuilder to enable/disable
    // the Create button based on the text field contents.
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final raw = nameController.text.trim();
            // Programmable-safe name: only allow letters, numbers, '.', '_' and '-'.
            final validNameRegex = RegExp(r'^[a-zA-Z0-9._-]+$');
            final isEmpty = raw.isEmpty;
            final isValid = !isEmpty && validNameRegex.hasMatch(raw);
            String? errorText;
            if (isEmpty) {
              errorText = 'Family name is required';
            } else if (!validNameRegex.hasMatch(raw)) {
              errorText = 'Only letters, numbers, dot, underscore and hyphen allowed; no spaces';
            }

            return AlertDialog(
              title: Text('Create New Family'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Create a new family group to manage members and shared resources.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Family Name',
                      hintText: 'e.g., smith_family or Smith-Family',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.family_restroom),
                      errorText: errorText,
                    ),
                    maxLength: 100,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
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
                  onPressed: isValid
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  child: Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final name = nameController.text.trim();
      final family = await ref
          .read(familyListProvider.notifier)
          .createFamily(name: name);

      if (family != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Family created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to family details
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FamilyDetailsScreen(familyId: family.familyId),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final familyState = ref.watch(familyListProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Family',
        showHamburger: false,
        showCurrency: false, // SBD token display disabled
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Badge showing pending invitation count
          Consumer(
            builder: (context, ref, _) {
              final invState = ref.watch(receivedInvitationsProvider);
              final pendingCount = invState.pendingInvitations.length;

              return IconButton(
                icon: Badge(
                  label: Text('$pendingCount'),
                  isLabelVisible: pendingCount > 0,
                  child: const Icon(Icons.mail_outline),
                ),
                tooltip: 'Family Invitations',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReceivedInvitationsScreen(),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateFamilyDialog,
        icon: Icon(Icons.add),
        label: Text('Create Family'),
        backgroundColor: theme.primaryColor,
      ),
      body: familyState.isLoading && familyState.families.isEmpty
          ? LoadingStateWidget(message: 'Loading families...')
          : familyState.error != null
          ? ErrorStateWidget(
              error: familyState.error,
              onRetry: () {
                ref.read(familyListProvider.notifier).clearError();
                ref.read(familyListProvider.notifier).loadFamilies();
              },
            )
          : familyState.families.isEmpty
          ? _buildEmptyState(theme)
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(familyListProvider.notifier).loadFamilies();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: familyState.families.length,
                itemBuilder: (context, index) {
                  final family = familyState.families[index];
                  return _buildFamilyCard(family, theme);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom,
              size: 100,
              color: theme.primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Families Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first family group to start managing members and shared resources.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showCreateFamilyDialog,
              icon: Icon(Icons.add),
              label: Text('Create Your First Family'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyCard(models.Family family, ThemeData theme) {
    return Dismissible(
      key: Key(family.familyId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(family, theme);
      },
      onDismissed: (direction) async {
        final success = await ref
            .read(familyListProvider.notifier)
            .deleteFamily(family.familyId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Family deleted successfully'
                    : 'Failed to delete family',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      },
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.red, size: 28),
      ),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FamilyDetailsScreen(familyId: family.familyId),
              ),
            );
          },
          onLongPress: family.isAdmin
              ? () => _showFamilyOptions(family, theme)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.family_restroom,
                        color: theme.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            family.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${family.memberCount} member${family.memberCount != 1 ? 's' : ''}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (family.isAdmin)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'ADMIN',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: theme.hintColor),
                  ],
                ),
                if (family.sbdAccount != null) ...[
                  const SizedBox(height: 16),
                  Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 20,
                        color: family.sbdAccount!.isFrozen
                            ? Colors.red
                            : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text('Balance:', style: theme.textTheme.bodyMedium),
                      const SizedBox(width: 8),
                      Text(
                        '${family.sbdAccount!.balance} ${family.sbdAccount!.currency}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      if (family.sbdAccount!.isFrozen) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'FROZEN',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(
    models.Family family,
    ThemeData theme,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Family?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${family.name}"?',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showFamilyOptions(models.Family family, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Family'),
              subtitle: Text('Permanently delete this family'),
              onTap: () {
                Navigator.of(context).pop();
                _showDeleteConfirmation(family, theme);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.close, color: Colors.grey),
              title: Text('Leave Family'),
              subtitle: Text('Remove yourself from this family'),
              onTap: () {
                Navigator.of(context).pop();
                // Future implementation for leaving family
              },
            ),
          ],
        ),
      ),
    );
  }
}
