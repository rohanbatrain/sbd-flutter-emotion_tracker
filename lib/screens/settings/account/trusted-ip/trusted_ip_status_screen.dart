import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/trusted_ip_lockdown_service.dart';
import 'trusted_ip_setup_screen.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/core/session_manager.dart';
import 'package:emotion_tracker/core/exceptions.dart' as core_exceptions;

/// TrustedIpStatusScreen
/// 
/// This screen displays the current Trusted IP Lockdown status for the user, including:
///   - Whether lockdown is enabled or disabled
///   - The user's current IP (as seen by the backend)
///   - A button to enable or disable lockdown, which navigates to the setup screen
///   - Handles loading and error states
///   - Uses the trustedIpLockdownServiceProvider to fetch status from the backend
///
/// This is the main entry point for managing Trusted IP Lockdown in the app.
class TrustedIpStatusScreen extends ConsumerWidget {
  final VoidCallback? onBackToSettings;

  const TrustedIpStatusScreen({Key? key, this.onBackToSettings}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusAsync = ref.watch(_trustedIpStatusProvider);

    return statusAsync.when(
      data: (data) {
        // Support both legacy and new backend keys for enabled status
        final enabled =
          data['enabled'] == true ||
          data['enabled'] == 'true' ||
          data['enabled'] == 1 ||
          data['trusted_ip_lockdown'] == true ||
          data['trusted_ip_lockdown'] == 'true' ||
          data['trusted_ip_lockdown'] == 1;
        final currentIp = data['current_ip'] as String? ?? data['your_ip'] as String?;
        final trustedIps = (data['trusted_ips'] as List?)?.cast<String>() ?? [];
        // Always show a status summary screen first, not directly setup or enabled
        return Scaffold(
          appBar: AppBar(
            title: const Text('Trusted IP Lockdown'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (onBackToSettings != null) {
                  onBackToSettings!();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            centerTitle: true,
            elevation: 0,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    enabled ? Icons.shield : Icons.shield_outlined,
                    size: 64,
                    color: enabled ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    enabled ? 'Trusted IP Lockdown is enabled.' : 'Trusted IP Lockdown is disabled.',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (currentIp != null)
                    Text('Your current IP: $currentIp'),
                  if (enabled && trustedIps.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Trusted IPs:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: trustedIps.map((ip) => Chip(label: Text(ip))).toList(),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(enabled ? Icons.lock_open : Icons.verified_user),
                      label: Text(enabled ? 'Disable Lockdown' : 'Enable Lockdown'),
                      onPressed: () async {
                        // Show setup screen for enable or disable, and refresh status after
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TrustedIpSetupScreen(
                              enableMode: !enabled ? true : false, // true for enable, false for disable
                              currentIp: currentIp ?? '',
                              initialTrustedIps: trustedIps,
                            ),
                          ),
                        );
                        ref.invalidate(_trustedIpStatusProvider);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const LoadingStateWidget(message: 'Loading your Trusted IP status...'),
      error: (err, stack) {
        if (err is core_exceptions.UnauthorizedException) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            SessionManager.redirectToLogin(context, message: 'Your session has expired. Please log in again.');
          });
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(child: Text('Session expired. Redirecting to login...')),
          );
        }
        return ErrorStateWidget(
          error: err,
          onRetry: () => ref.invalidate(_trustedIpStatusProvider),
          customMessage: 'Unable to load Trusted IP status. Please try again.',
        );
      },
    );
  }
}

final _trustedIpStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(trustedIpLockdownServiceProvider);
  return await service.getStatus();
});
