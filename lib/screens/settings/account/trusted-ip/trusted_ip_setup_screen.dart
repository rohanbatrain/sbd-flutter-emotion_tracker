import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/trusted_ip_lockdown_service.dart';
import 'package:flutter/services.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/core/session_manager.dart';
import 'package:emotion_tracker/core/exceptions.dart' as core_exceptions;

class TrustedIpSetupScreen extends ConsumerStatefulWidget {
  final bool enableMode; // true = enable, false = disable
  final String currentIp;
  final List<String>? initialTrustedIps;
  const TrustedIpSetupScreen({
    Key? key,
    required this.enableMode,
    required this.currentIp,
    this.initialTrustedIps,
  }) : super(key: key);

  @override
  ConsumerState<TrustedIpSetupScreen> createState() => _TrustedIpSetupScreenState();
}

class _TrustedIpSetupScreenState extends ConsumerState<TrustedIpSetupScreen> {
  late List<String> trustedIps;
  bool isLoading = false;
  String? error;
  final TextEditingController codeController = TextEditingController();
  final TextEditingController ipController = TextEditingController();
  bool awaitingConfirmation = false;
  String ipType = 'IPv4';

  @override
  void initState() {
    super.initState();
    if (widget.enableMode) {
      if (widget.initialTrustedIps != null && widget.initialTrustedIps!.isNotEmpty) {
        trustedIps = widget.initialTrustedIps!;
      } else if (widget.currentIp.isNotEmpty) {
        trustedIps = [widget.currentIp];
      } else {
        trustedIps = [];
      }
    } else {
      trustedIps = widget.initialTrustedIps ?? (widget.currentIp.isNotEmpty ? [widget.currentIp] : []);
    }
  }

  void _addIp() {
    final ip = ipController.text.trim();
    final isValid = ipType == 'IPv4'
        ? RegExp(r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$').hasMatch(ip) &&
          ip.split('.').every((octet) => int.tryParse(octet) != null && int.parse(octet) >= 0 && int.parse(octet) <= 255)
        : RegExp(r'^[0-9a-fA-F:]+$').hasMatch(ip) && ip.contains(':');
    if (ip.isNotEmpty && trustedIps.contains(ip)) {
      setState(() {
        error = 'This IP address is already in the list.';
      });
      return;
    }
    if (ip.isNotEmpty && isValid && !trustedIps.contains(ip)) {
      setState(() {
        trustedIps.add(ip);
        trustedIps = trustedIps.where((ip) => ip.trim().isNotEmpty).toList();
        ipController.clear();
        error = null;
      });
    } else if (!isValid && ip.isNotEmpty) {
      setState(() {
        error = ipType == 'IPv4'
            ? 'Please enter a valid IPv4 address.'
            : 'Please enter a valid IPv6 address.';
      });
    }
  }

  void _removeIp(String ip) {
    setState(() {
      trustedIps.remove(ip);
    });
  }

  Future<void> _submit() async {
    if (!widget.enableMode) {
      setState(() { isLoading = true; error = null; });
      try {
        final service = ref.read(trustedIpLockdownServiceProvider);
        await service.requestLockdown(
          action: 'disable',
          trustedIps: [],
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
    trustedIps = trustedIps.where((ip) => ip.trim().isNotEmpty).toList();
    if (trustedIps.isEmpty) {
      setState(() {
        error = 'You must add at least one trusted IP to enable lockdown.';
      });
      return;
    }
    setState(() { isLoading = true; error = null; });
    try {
      final service = ref.read(trustedIpLockdownServiceProvider);
      await service.requestLockdown(
        action: 'enable',
        trustedIps: trustedIps,
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
      final service = ref.read(trustedIpLockdownServiceProvider);
      await service.confirmLockdown(codeController.text.trim());
      setState(() {
        isLoading = false;
        awaitingConfirmation = false;
      });
      if (mounted) {
        final msg = widget.enableMode
          ? 'Trusted IP lockdown enabled successfully. Trusted IPs updated.'
          : 'Trusted IP lockdown disabled successfully. Trusted IPs updated.';
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
      if (errStr.contains('Confirmation must be from one of the allowed IPs')) {
        displayError = 'Confirmation failed: You must confirm from one of your trusted IPs.';
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
        customMessage: 'Unable to process Trusted IP lockdown. Please try again.',
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
                          'A confirmation code has been sent to your email. Please enter it below from one of your trusted IPs.',
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
                            Icon(Icons.shield, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Disable Trusted IP Lockdown',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Disabling is only allowed from one of your trusted IPs. You will still need to verify this action with a confirmation code sent to your email.',
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
                              'Only these IPs will be able to confirm and use your account when lockdown is enabled.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 8,
                              children: trustedIps
                                  .where((ip) => ip.trim().isNotEmpty)
                                  .map((ip) => Chip(
                                        label: Text(ip),
                                        onDeleted: () => _removeIp(ip),
                                        deleteIcon: const Icon(Icons.close),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                DropdownButton<String>(
                                  value: ipType,
                                  items: [
                                    DropdownMenuItem(value: 'IPv4', child: Text('IPv4')),
                                    DropdownMenuItem(value: 'IPv6', child: Text('IPv6')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => ipType = val);
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: ipController,
                                    decoration: InputDecoration(
                                      labelText: 'Add ${ipType == 'IPv4' ? 'IPv4' : 'IPv6'}',
                                      hintText: ipType == 'IPv4'
                                          ? 'e.g. 192.168.1.1'
                                          : 'e.g. 2001:0db8:85a3:0000:0000:8a2e:0370:7334',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.text,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(ipType == 'IPv4'
                                            ? r'[0-9\.]'
                                            : r'[0-9a-fA-F:]'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _addIp,
                                  child: const Text('Add'),
                                ),
                              ],
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
