import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'trusted_user_agent_setup_screen.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/providers/trusted_user_agent_lockdown_service.dart';

/// TrustedUserAgentStatusScreen
/// 
/// This screen displays the current Trusted User Agent Lockdown status for the user, including:
///   - Whether lockdown is enabled or disabled
///   - The user's current User Agent (as seen by the backend)
///   - A button to enable or disable lockdown, which navigates to the setup screen
///   - Handles loading and error states
///   - Uses the trustedUserAgentLockdownServiceProvider to fetch status from the backend
class TrustedUserAgentStatusScreen extends ConsumerWidget {
  final VoidCallback? onBackToSettings;

  const TrustedUserAgentStatusScreen({Key? key, this.onBackToSettings}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusAsync = ref.watch(_trustedUserAgentStatusProvider);

    return statusAsync.when(
      data: (data) {
        final enabled =
          data['trusted_user_agent_lockdown'] == true ||
          data['trusted_user_agent_lockdown'] == 'true' ||
          data['trusted_user_agent_lockdown'] == 1;
        final currentUserAgent = data['your_user_agent'] as String?;
        final trustedUserAgents = (data['trusted_user_agents'] as List?)?.cast<String>() ?? [];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Trusted User Agent Lockdown'),
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
              child: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          enabled ? Icons.verified_user : Icons.verified_user_outlined,
                          color: enabled ? Colors.green : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          enabled ? 'Lockdown Enabled' : 'Lockdown Disabled',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: enabled ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Current User Agent:', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        currentUserAgent ?? 'Unknown',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (trustedUserAgents.isNotEmpty) ...[
                      Text('Trusted User Agents:', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      ...trustedUserAgents.map((ua) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('• $ua', style: const TextStyle(fontSize: 11)),
                      )),
                      const SizedBox(height: 24),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TrustedUserAgentSetupScreen(
                                enableMode: !enabled,
                                currentUserAgent: currentUserAgent ?? '',
                                initialTrustedUserAgents: trustedUserAgents,
                              ),
                            ),
                          );
                          ref.invalidate(_trustedUserAgentStatusProvider);
                        },
                        child: Text(enabled ? 'Disable Lockdown' : 'Enable Lockdown'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const LoadingStateWidget(message: 'Loading status...'),
      error: (err, stack) => ErrorStateWidget(
        error: err,
        onRetry: () => ref.refresh(_trustedUserAgentStatusProvider),
        customMessage: 'Unable to fetch Trusted User Agent Lockdown status.',
      ),
    );
  }
}

final _trustedUserAgentStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(trustedUserAgentLockdownServiceProvider);
  return await service.getStatus();
});

final trustedUserAgentLockdownServiceProvider = Provider<TrustedUserAgentLockdownService>((ref) {
  return TrustedUserAgentLockdownService(ref);
});
