import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/shared_prefs_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/utils/http_util.dart';

class ServerSettingsDialog extends ConsumerStatefulWidget {
  final void Function()? onSaved;
  const ServerSettingsDialog({Key? key, this.onSaved}) : super(key: key);

  @override
  ConsumerState<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends ConsumerState<ServerSettingsDialog> {
  TextEditingController? domainController;
  String? errorText;
  String preview = '';
  bool testSuccess = false;
  bool testing = false;

  @override
  void dispose() {
    domainController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final protocol = ref.watch(serverProtocolProvider);
    final domain = ref.watch(serverDomainProvider);
    final healthCheckUrl = ref.watch(healthCheckEndpointProvider);
    domainController ??= TextEditingController(text: domain);
    preview = '$protocol://${domainController!.text.trim().isEmpty ? 'dev-app-sbd.rohanbatra.in' : domainController!.text.trim()}';
    return AlertDialog(
      backgroundColor: theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Padding(
        padding: const EdgeInsets.only(top: 12, left: 4, right: 4, bottom: 0),
        child: Text('Server Configuration', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Protocol', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                      Text(protocol.toUpperCase(), style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                    ],
                  ),
                  Switch.adaptive(
                    value: protocol == 'https',
                    activeColor: theme.primaryColor,
                    inactiveThumbColor: theme.cardColor,
                    inactiveTrackColor: theme.dividerColor.withOpacity(0.2),
                    onChanged: (val) {
                      ref.read(serverProtocolProvider.notifier).setProtocol(val ? 'https' : 'http');
                    },
                  ),
                  Text(protocol == 'https' ? 'HTTPS' : 'HTTP', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('Domain/IP', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: domainController,
              minLines: 1,
              maxLines: 1,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'dev-app-sbd.rohanbatra.in',
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                errorText: errorText,
              ),
              onChanged: (val) {
                setState(() {
                  preview = '$protocol://${val.trim().isEmpty ? 'dev-app-sbd.rohanbatra.in' : val.trim()}';
                  errorText = null;
                  testSuccess = false;
                });
              },
            ),
            const SizedBox(height: 10),
            Text('Preview: $preview', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: testing
                        ? null
                        : () async {
                            setState(() { testing = true; errorText = null; });
                            final inputDomain = domainController!.text.trim();
                            // Allow domain, IP, and optional :port
                            final isValidDomain = RegExp(r'^[a-zA-Z0-9.-]+(:[0-9]{1,5})?$').hasMatch(inputDomain) && inputDomain.isNotEmpty;
                            if (!isValidDomain) {
                              setState(() {
                                testSuccess = false;
                                errorText = 'Please enter a valid domain, IP, or domain:port (no spaces or special characters).';
                                testing = false;
                              });
                              return;
                            }
                            final url = healthCheckUrl.replaceFirst(domain, inputDomain.isEmpty ? 'dev-app-sbd.rohanbatra.in' : inputDomain);
                            try {
                              final response = await HttpUtil.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
                              if (response.statusCode == 200) {
                                setState(() {
                                  testSuccess = true;
                                  errorText = null;
                                  testing = false;
                                });
                              } else {
                                setState(() {
                                  testSuccess = false;
                                  errorText = 'Server responded, but health check failed (code: ${response.statusCode}). Please check your server.';
                                  testing = false;
                                });
                              }
                            } catch (e) {
                              setState(() {
                                testSuccess = false;
                                // Check for Cloudflare tunnel errors
                                if (e is CloudflareTunnelException) {
                                  errorText = 'Cloudflare tunnel is down: ${e.message}';
                                } else if (e is NetworkException) {
                                  errorText = 'Network error: ${e.message}';
                                } else {
                                  errorText = 'Could not connect. Please check your network or server address.';
                                }
                                testing = false;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: testing
                        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
                        : const Text('Test Connection'),
                  ),
                ),
              ],
            ),
            if (testSuccess)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Connection successful', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green)),
              ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(errorText!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
              ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: theme.textTheme.bodyLarge?.color,
            textStyle: theme.textTheme.labelLarge,
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Save'),
          onPressed: () async {
            final domain = domainController!.text.trim();
            final isValidDomain = RegExp(r'^[a-zA-Z0-9.-]+(:[0-9]{1,5})?$').hasMatch(domain) && domain.isNotEmpty;
            if (domain.isEmpty) {
              setState(() { errorText = 'Please enter a domain or IP.'; });
              return;
            }
            if (!isValidDomain) {
              setState(() { errorText = 'Please enter a valid domain, IP, or domain:port (no spaces or special characters).'; });
              return;
            }
            if (!testSuccess) {
              setState(() { errorText = 'Please test connection before saving.'; });
              return;
            }
            await ref.read(serverDomainProvider.notifier).setDomain(domain);
            // protocol is already set via toggle
            if (widget.onSaved != null) widget.onSaved!();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: theme.colorScheme.secondary),
                    SizedBox(width: 12),
                    Text(
                      'Server settings updated successfully!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                backgroundColor: theme.colorScheme.secondary,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}
