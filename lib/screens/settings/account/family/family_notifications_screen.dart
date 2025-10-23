import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/providers/family/family_provider.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'notification_preferences_screen.dart';
import 'package:emotion_tracker/utils/notification_helpers.dart';

class FamilyNotificationsScreen extends ConsumerStatefulWidget {
  final String familyId;

  const FamilyNotificationsScreen({Key? key, required this.familyId})
    : super(key: key);

  @override
  ConsumerState<FamilyNotificationsScreen> createState() =>
      _FamilyNotificationsScreenState();
}

class _FamilyNotificationsScreenState
    extends ConsumerState<FamilyNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(notificationsProvider(widget.familyId).notifier)
          .loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationsState = ref.watch(
      notificationsProvider(widget.familyId),
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Notifications',
        showHamburger: false,
        showCurrency: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NotificationPreferencesScreen(familyId: widget.familyId),
                ),
              );
            },
          ),
          if (notificationsState.unreadCount > 0)
            TextButton(
              onPressed: () async {
                final success = await ref
                    .read(notificationsProvider(widget.familyId).notifier)
                    .markAllAsRead();
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('All notifications marked as read')),
                  );
                }
              },
              child: Text('Mark All Read'),
            ),
        ],
      ),
      body: notificationsState.isLoading
          ? LoadingStateWidget(message: 'Loading notifications...')
          : notificationsState.error != null
          ? ErrorStateWidget(
              error: notificationsState.error,
              onRetry: () {
                ref
                    .read(notificationsProvider(widget.familyId).notifier)
                    .loadNotifications();
              },
            )
          : notificationsState.notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 80,
                    color: theme.hintColor,
                  ),
                  const SizedBox(height: 16),
                  Text('No notifications', style: theme.textTheme.titleLarge),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: notificationsState.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationsState.notifications[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  color: notification.isRead
                      ? null
                      : theme.primaryColor.withOpacity(0.05),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notification.isRead
                          ? theme.hintColor.withOpacity(0.2)
                          : theme.primaryColor.withOpacity(0.2),
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        color: notification.isRead
                            ? theme.hintColor
                            : theme.primaryColor,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notification.message),
                        const SizedBox(height: 6),
                        Text(
                          'From: ${renderFromForNotification(notification.metadata)}',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(notification.createdAt),
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'invitation':
        return Icons.mail;
      case 'token_request':
        return Icons.request_page;
      case 'member_added':
        return Icons.person_add;
      case 'member_removed':
        return Icons.person_remove;
      case 'transaction':
        return Icons.account_balance_wallet;
      default:
        return Icons.notifications;
    }
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
