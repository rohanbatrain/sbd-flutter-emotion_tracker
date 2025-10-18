import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/providers/family/family_api_service.dart';
import 'package:emotion_tracker/providers/family/family_models.dart' as models;
import 'package:emotion_tracker/widgets/loading_state_widget.dart';

final notificationPreferencesProvider =
    StateNotifierProvider<
      NotificationPreferencesNotifier,
      NotificationPreferencesState
    >((ref) {
      final apiService = ref.watch(familyApiServiceProvider);
      return NotificationPreferencesNotifier(apiService);
    });

class NotificationPreferencesState {
  final models.NotificationPreferences? preferences;
  final bool isLoading;
  final String? error;

  NotificationPreferencesState({
    this.preferences,
    required this.isLoading,
    this.error,
  });

  NotificationPreferencesState copyWith({
    models.NotificationPreferences? preferences,
    bool? isLoading,
    String? error,
  }) {
    return NotificationPreferencesState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferencesState> {
  final FamilyApiService _apiService;

  NotificationPreferencesNotifier(this._apiService)
    : super(NotificationPreferencesState(isLoading: false));

  Future<void> loadPreferences() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await _apiService.getNotificationPreferences();
      state = state.copyWith(preferences: prefs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updatePreferences(models.NotificationPreferences prefs) async {
    try {
      final updated = await _apiService.updateNotificationPreferences(prefs);
      state = state.copyWith(preferences: updated);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  final String familyId;

  const NotificationPreferencesScreen({Key? key, required this.familyId})
    : super(key: key);

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  final _thresholdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationPreferencesProvider.notifier).loadPreferences();
    });
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _updatePreference(
    models.NotificationPreferences updatedPrefs,
  ) async {
    final success = await ref
        .read(notificationPreferencesProvider.notifier)
        .updatePreferences(updatedPrefs);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preferences updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showThresholdDialog(int currentThreshold) async {
    _thresholdController.text = currentThreshold.toString();

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Transaction Threshold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Get notified when transactions exceed this amount'),
            const SizedBox(height: 16),
            TextField(
              controller: _thresholdController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (SBD)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_exchange),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(_thresholdController.text.trim());
              if (value != null && value >= 0) {
                Navigator.pop(context, value);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final prefs = ref.read(notificationPreferencesProvider).preferences;
      if (prefs != null) {
        final updated = models.NotificationPreferences(
          emailNotifications: prefs.emailNotifications,
          pushNotifications: prefs.pushNotifications,
          smsNotifications: prefs.smsNotifications,
          notifyOnSpend: prefs.notifyOnSpend,
          notifyOnDeposit: prefs.notifyOnDeposit,
          largeTransactionThreshold: result,
        );
        await _updatePreference(updated);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(notificationPreferencesProvider);
    final prefs = state.preferences;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Notification Preferences',
        showHamburger: false,
        showCurrency: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: state.isLoading
          ? LoadingStateWidget(message: 'Loading preferences...')
          : prefs == null
          ? Center(child: Text('Failed to load preferences'))
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.notifications,
                          color: theme.primaryColor,
                        ),
                        title: Text('Notification Channels'),
                        subtitle: Text(
                          'Choose how you want to receive notifications',
                        ),
                      ),
                      Divider(),
                      SwitchListTile(
                        secondary: Icon(Icons.email),
                        title: Text('Email Notifications'),
                        subtitle: Text('Receive updates via email'),
                        value: prefs.emailNotifications,
                        onChanged: (value) {
                          final updated = models.NotificationPreferences(
                            emailNotifications: value,
                            pushNotifications: prefs.pushNotifications,
                            smsNotifications: prefs.smsNotifications,
                            notifyOnSpend: prefs.notifyOnSpend,
                            notifyOnDeposit: prefs.notifyOnDeposit,
                            largeTransactionThreshold:
                                prefs.largeTransactionThreshold,
                          );
                          _updatePreference(updated);
                        },
                      ),
                      SwitchListTile(
                        secondary: Icon(Icons.phone_android),
                        title: Text('Push Notifications'),
                        subtitle: Text('Receive push notifications'),
                        value: prefs.pushNotifications,
                        onChanged: (value) {
                          final updated = models.NotificationPreferences(
                            emailNotifications: prefs.emailNotifications,
                            pushNotifications: value,
                            smsNotifications: prefs.smsNotifications,
                            notifyOnSpend: prefs.notifyOnSpend,
                            notifyOnDeposit: prefs.notifyOnDeposit,
                            largeTransactionThreshold:
                                prefs.largeTransactionThreshold,
                          );
                          _updatePreference(updated);
                        },
                      ),
                      SwitchListTile(
                        secondary: Icon(Icons.sms),
                        title: Text('SMS Notifications'),
                        subtitle: Text('Receive text messages'),
                        value: prefs.smsNotifications,
                        onChanged: (value) {
                          final updated = models.NotificationPreferences(
                            emailNotifications: prefs.emailNotifications,
                            pushNotifications: prefs.pushNotifications,
                            smsNotifications: value,
                            notifyOnSpend: prefs.notifyOnSpend,
                            notifyOnDeposit: prefs.notifyOnDeposit,
                            largeTransactionThreshold:
                                prefs.largeTransactionThreshold,
                          );
                          _updatePreference(updated);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.account_balance_wallet,
                          color: theme.primaryColor,
                        ),
                        title: Text('Transaction Notifications'),
                        subtitle: Text('Get notified about account activity'),
                      ),
                      Divider(),
                      SwitchListTile(
                        secondary: Icon(
                          Icons.arrow_downward,
                          color: Colors.red,
                        ),
                        title: Text('Notify on Spend'),
                        subtitle: Text('Alert when tokens are spent'),
                        value: prefs.notifyOnSpend,
                        onChanged: (value) {
                          final updated = models.NotificationPreferences(
                            emailNotifications: prefs.emailNotifications,
                            pushNotifications: prefs.pushNotifications,
                            smsNotifications: prefs.smsNotifications,
                            notifyOnSpend: value,
                            notifyOnDeposit: prefs.notifyOnDeposit,
                            largeTransactionThreshold:
                                prefs.largeTransactionThreshold,
                          );
                          _updatePreference(updated);
                        },
                      ),
                      SwitchListTile(
                        secondary: Icon(
                          Icons.arrow_upward,
                          color: Colors.green,
                        ),
                        title: Text('Notify on Deposit'),
                        subtitle: Text('Alert when tokens are added'),
                        value: prefs.notifyOnDeposit,
                        onChanged: (value) {
                          final updated = models.NotificationPreferences(
                            emailNotifications: prefs.emailNotifications,
                            pushNotifications: prefs.pushNotifications,
                            smsNotifications: prefs.smsNotifications,
                            notifyOnSpend: prefs.notifyOnSpend,
                            notifyOnDeposit: value,
                            largeTransactionThreshold:
                                prefs.largeTransactionThreshold,
                          );
                          _updatePreference(updated);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.warning_amber),
                        title: Text('Large Transaction Threshold'),
                        subtitle: Text(
                          '${prefs.largeTransactionThreshold} SBD',
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _showThresholdDialog(
                            prefs.largeTransactionThreshold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
