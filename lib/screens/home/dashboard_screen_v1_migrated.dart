import 'package:emotion_tracker/core/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/core/global_error_handler.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'dart:async';

/// Example provider that might fail - simulates dashboard data loading
final dashboardDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Simulate network delay
  await Future.delayed(const Duration(seconds: 1));

  // Simulate different error scenarios for demonstration
  final random = DateTime.now().millisecondsSinceEpoch % 5;

  switch (random) {
    case 0:
      // Simulate network error
      throw Exception(
        'Network connection failed. Please check your internet connection.',
      );
    case 1:
      // Simulate server error
      throw Exception('Server error occurred. Please try again later.');
    case 2:
      // Simulate authentication error
      throw Exception('Session expired. Please log in again.');
    case 3:
      // Simulate rate limiting
      throw Exception('Too many requests. Please wait before trying again.');
    default:
      // Success case
      return {
        'user_name': 'John Doe',
        'total_entries': 42,
        'recent_activity': 'Logged mood: Happy',
        'streak_days': 7,
      };
  }
});

/// Migrated version of DashboardScreenV1 demonstrating error handling integration
class DashboardScreenV1Migrated extends ConsumerWidget {
  const DashboardScreenV1Migrated({super.key});

  /// Handles retry action when data loading fails
  void _handleRetry(WidgetRef ref) {
    ref.invalidate(dashboardDataProvider);

    // Optional: Show user feedback
    // Note: We can't show snackbar here since we don't have BuildContext
    // In a StatefulWidget, you could show feedback in the retry handler
  }

  /// Shows additional error information to help users
  void _showErrorInfo(BuildContext context, dynamic error) {
    final errorState = GlobalErrorHandler.processError(error);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(errorState.icon, color: errorState.color),
                const SizedBox(width: 8),
                const Text('Dashboard Error Help'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Unable to load your dashboard data.'),
                const SizedBox(height: 12),
                Text(
                  'What you can try:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(_getDashboardTroubleshootingSteps(errorState.type)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: errorState.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: errorState.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: errorState.color,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your data is safe. This is just a temporary loading issue.',
                          style: TextStyle(
                            color: errorState.color.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  String _getDashboardTroubleshootingSteps(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.unauthorized:
        return '• Log out and log back in\n• Check if your session is still valid\n• Contact support if login fails';
      case ErrorType.networkError:
        return '• Check your internet connection\n• Try switching between WiFi and mobile data\n• Move to an area with better signal';
      case ErrorType.serverError:
        return '• Our servers may be temporarily down\n• Try again in a few minutes\n• Check if other app features work';
      case ErrorType.rateLimited:
        return '• You\'re refreshing too quickly\n• Wait a minute before trying again\n• The dashboard will load automatically';
      default:
        return '• Pull down to refresh the dashboard\n• Close and reopen the app\n• Contact support if problem continues';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardDataProvider);
            // Wait for the provider to complete
            await ref.read(dashboardDataProvider.future);
          },
          child: dashboardAsync.when(
            loading:
                () => const LoadingStateWidget(
                  message: 'Loading your dashboard...',
                ),
            error: (error, stackTrace) {
              return ErrorStateWidget(
                error: error,
                onRetry: () => _handleRetry(ref),
                onInfo: () => _showErrorInfo(context, error),
                customMessage:
                    'Unable to load your dashboard. Pull down to refresh or tap retry.',
              );
            },
            data: (data) => _buildDashboardContent(context, theme, data),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> data,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Row(
            children: [
              Icon(
                Icons.dashboard_rounded,
                size: 32,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      data['user_name'] ?? 'User',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Total Entries',
                  '${data['total_entries'] ?? 0}',
                  Icons.edit_note,
                  theme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Streak Days',
                  '${data['streak_days'] ?? 0}',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Activity
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: theme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Activity',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  data['recent_activity'] ?? 'No recent activity',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  theme,
                  'Add Entry',
                  Icons.add_circle_outline,
                  () {
                    // Navigate to add entry screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add Entry tapped')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  theme,
                  'View History',
                  Icons.history,
                  () {
                    // Navigate to history screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('View History tapped')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    ThemeData theme,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.primaryColor, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
