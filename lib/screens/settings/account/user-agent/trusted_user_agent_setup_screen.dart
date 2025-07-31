import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/trusted_user_agent_lockdown_service.dart';
import 'package:emotion_tracker/providers/user_agent_util.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/core/session_manager.dart';
import 'package:emotion_tracker/core/exceptions.dart' as core_exceptions;
import 'package:flutter/services.dart';

class TrustedUserAgentSetupScreen extends ConsumerStatefulWidget {
  final bool enableMode; // true = enable, false = disable
  final String currentUserAgent;
  final List<String>? initialTrustedUserAgents;
  const TrustedUserAgentSetupScreen({
    Key? key,
    required this.enableMode,
    required this.currentUserAgent,
    this.initialTrustedUserAgents,
  }) : super(key: key);

  @override
  ConsumerState<TrustedUserAgentSetupScreen> createState() => _TrustedUserAgentSetupScreenState();
}

class _TrustedUserAgentSetupScreenState extends ConsumerState<TrustedUserAgentSetupScreen> {
  late List<String> trustedUserAgents;
  bool isLoading = false;
  String? error;
  final TextEditingController codeController = TextEditingController();
  final TextEditingController uaController = TextEditingController();
  bool awaitingConfirmation = false;

  @override
  void initState() {
    super.initState();
    if (widget.enableMode) {
      if (widget.initialTrustedUserAgents != null && widget.initialTrustedUserAgents!.isNotEmpty) {
        trustedUserAgents = widget.initialTrustedUserAgents!;
      } else if (widget.currentUserAgent.isNotEmpty) {
        trustedUserAgents = [widget.currentUserAgent];
      } else {
        trustedUserAgents = [];
      }
    } else {
      trustedUserAgents = widget.initialTrustedUserAgents ?? (widget.currentUserAgent.isNotEmpty ? [widget.currentUserAgent] : []);
    }
  }

  void _addUserAgent() {
    final ua = uaController.text.trim();
    if (ua.isNotEmpty && trustedUserAgents.contains(ua)) {
      setState(() {
        error = 'This User Agent is already in the list.';
      });
      return;
    }
    if (ua.isNotEmpty && !trustedUserAgents.contains(ua)) {
      setState(() {
        trustedUserAgents.add(ua);
        trustedUserAgents = trustedUserAgents.where((ua) => ua.trim().isNotEmpty).toList();
        uaController.clear();
        error = null;
      });
    }
  }

  void _removeUserAgent(String ua) {
    setState(() {
      trustedUserAgents.remove(ua);
    });
  }

  Future<void> _submit() async {
    if (!widget.enableMode) {
      setState(() { isLoading = true; error = null; });
      try {
        final service = ref.read(trustedUserAgentLockdownServiceProvider);
        await service.requestLockdown(
          action: 'disable',
          trustedUserAgents: [],
        );
        setState(() {
          isLoading = false;
          awaitingConfirmation = true;
        });
      } on core_exceptions.UnauthorizedException catch (_) {
        if (mounted) {
          setState(() { error = '__unauthorized_redirect__'; isLoading = false; });
          SessionManager.redirectToLogin(context, message: 'Session expired. Please log in again.');
        }
      } catch (e) {
        setState(() {
          isLoading = false;
          error = e.toString();
        });
      }
      return;
    }
    // Enable mode logic
    trustedUserAgents = trustedUserAgents.where((ua) => ua.trim().isNotEmpty).toList();
    if (trustedUserAgents.isEmpty) {
      setState(() {
        error = 'You must add at least one trusted User Agent to enable lockdown.';
      });
      return;
    }
    setState(() { isLoading = true; error = null; });
    try {
      final service = ref.read(trustedUserAgentLockdownServiceProvider);
      await service.requestLockdown(
        action: 'enable',
        trustedUserAgents: trustedUserAgents,
      );
      setState(() {
        isLoading = false;
        awaitingConfirmation = true;
      });
    } on core_exceptions.UnauthorizedException catch (_) {
      if (mounted) {
        setState(() { error = '__unauthorized_redirect__'; isLoading = false; });
        SessionManager.redirectToLogin(context, message: 'Session expired. Please log in again.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _confirm() async {
    setState(() { isLoading = true; error = null; });
    try {
      final service = ref.read(trustedUserAgentLockdownServiceProvider);
      await service.confirmLockdown(codeController.text.trim());
      setState(() {
        isLoading = false;
        awaitingConfirmation = false;
      });
      if (mounted) {
        final msg = widget.enableMode
          ? 'Trusted User Agent lockdown enabled successfully. Trusted User Agents updated.'
          : 'Trusted User Agent lockdown disabled successfully. Trusted User Agents updated.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        Navigator.of(context).pop();
      }
    } on core_exceptions.UnauthorizedException catch (_) {
      if (mounted) {
        setState(() { error = '__unauthorized_redirect__'; isLoading = false; });
        SessionManager.redirectToLogin(context, message: 'Session expired. Please log in again.');
      }
    } catch (e) {
      String? displayError;
      final errStr = e.toString();
      if (errStr.contains('Confirmation must be from one of the allowed User Agents')) {
        displayError = 'Confirmation failed: You must confirm from one of your trusted User Agents.';
      } else if (errStr.contains('Invalid code')) {
        displayError = 'Confirmation failed: The code you entered is invalid.';
      } else {
        displayError = errStr;
      }
      setState(() {
        isLoading = false;
        error = displayError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisableMode = !widget.enableMode;
    if (isLoading) {
      return const LoadingStateWidget(message: 'Processing...');
    }
    if (error != null) {
      if (error == '__unauthorized_redirect__') {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Center(child: Text('Session expired. Redirecting to login...')),
        );
      }
      return ErrorStateWidget(
        error: error,
        onRetry: _submit,
        customMessage: 'Unable to process Trusted User Agent lockdown. Please try again.',
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.enableMode ? 'Enable Lockdown' : 'Disable Lockdown'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 480,
              child: awaitingConfirmation
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.email, size: 48, color: theme.primaryColor),
                        const SizedBox(height: 16),
                        Text(
                          'A confirmation code has been sent to your email. Please enter it below from one of your trusted User Agents.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: codeController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            child: const Text('Confirm'),
                            onPressed: _confirm,
                          ),
                        ),
                      ],
                    )
                  : isDisableMode
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Disable Trusted User Agent Lockdown',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Disabling is only allowed from one of your trusted User Agents. You will still need to verify this action with a confirmation code sent to your email.',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submit,
                                child: const Text('Disable Lockdown'),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Only these User Agents will be able to confirm and use your account when lockdown is enabled.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 8,
                              children: trustedUserAgents
                                  .where((ua) => ua.trim().isNotEmpty)
                                  .map((ua) => Chip(
                                        label: Text(ua, style: const TextStyle(fontSize: 11)),
                                        onDeleted: () => _removeUserAgent(ua),
                                        deleteIcon: const Icon(Icons.close),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: uaController,
                                    decoration: InputDecoration(
                                      labelText: 'Add User Agent',
                                      hintText: 'Paste or type a User Agent string',
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.text,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _addUserAgent,
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<String>(
                              future: getUserAgent(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Row(
                                    children: [
                                      Text('Current: ', style: theme.textTheme.bodySmall),
                                      Expanded(
                                        child: Text(
                                          snapshot.data!,
                                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 18),
                                        tooltip: 'Copy',
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: snapshot.data!));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('User Agent copied to clipboard')),
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submit,
                                child: const Text('Enable Lockdown'),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
