import 'dart:convert';
import 'package:emotion_tracker/screens/settings/account/enable-2fa/2fa_enabled_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/two_fa_service.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen to start 2FA setup (shows QR, secret, provisioning URI, input for TOTP code)
class TwoFASetupScreen extends ConsumerStatefulWidget {
  const TwoFASetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TwoFASetupScreen> createState() => _TwoFASetupScreenState();
}

class _TwoFASetupScreenState extends ConsumerState<TwoFASetupScreen> {
  String? qrCodeUrl;
  String? provisioningUri;
  String? totpSecret;
  bool isLoading = true;
  String? error;
  final TextEditingController codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startSetup();
  }

  Future<void> _startSetup() async {
    setState(() { isLoading = true; error = null; });
    try {
      final data = await ref.read(twoFAServiceProvider).setup2FA();
      setState(() {
        qrCodeUrl = data['qr_code_data']; // changed from 'qr_code_url' to 'qr_code_data'
        provisioningUri = data['provisioning_uri'];
        totpSecret = data['totp_secret'];
        isLoading = false;
      });
    } on UnauthorizedException catch (_) {
      if (mounted) {
        setState(() {
          error = '__unauthorized_redirect__';
          isLoading = false;
        });
        Navigator.of(context).pushNamedAndRemoveUntil('auth/login/v1', (route) => false);
      }
    } catch (e) {
      setState(() { error = e.toString(); isLoading = false; });
    }
  }

  void _onVerify() async {
    final code = codeController.text.trim();
    if (code.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the 6-digit code from your authenticator app.')),
        );
      }
      return;
    }
    setState(() { isLoading = true; error = null; });
    try {
      final result = await ref.read(twoFAServiceProvider).verify2FA(code);
      if (result['backup_codes'] != null) {
        // Show backup codes screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => TwoFABackupCodesScreen(backupCodes: List<String>.from(result['backup_codes'])))
        );
      } else {
        // Go to enabled screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TwoFAEnabledScreen())
        );
      }
    } on UnauthorizedException catch (_) {
      if (mounted) {
        setState(() {
          error = '__unauthorized_redirect__';
          isLoading = false;
        });
        Navigator.of(context).pushNamedAndRemoveUntil('auth/login/v1', (route) => false);
      }
    } catch (e) {
      setState(() { error = e.toString(); isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isLoading) {
      // If session expired, don't show spinner
      if (error == '__unauthorized_redirect__') {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Center(child: Text('Session expired. Redirecting to login...')),
        );
      }
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Two-Factor Authentication'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() {
                isLoading = true;
                error = null;
              });
              _startSetup();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enable Two-Factor Authentication',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (error != null) ...[
                Text(
                  error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),
              if (qrCodeUrl != null)
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Builder(
                        builder: (context) {
                          try {
                            String base64Str = qrCodeUrl!;
                            if (base64Str.startsWith('data:image')) {
                              final idx = base64Str.indexOf('base64,');
                              if (idx != -1) {
                                base64Str = base64Str.substring(idx + 7);
                              }
                            }
                            final bytes = base64Decode(base64Str);
                            return Image.memory(
                              bytes,
                              width: MediaQuery.of(context).size.width * 0.7,
                              fit: BoxFit.contain,
                            );
                          } catch (e) {
                            return Text('Error displaying QR code: $e');
                          }
                        },
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (totpSecret != null) ...[
                const SizedBox(height: 20),
                _ObscurableTextField(
                  label: 'TOTP Secret',
                  value: totpSecret!,
                  icon: Icons.vpn_key,
                  iconColor: Colors.deepPurple,
                  copyTooltip: 'Copy Secret',
                  copySnack: 'Secret copied to clipboard!',
                ),
              ],
              if (provisioningUri != null) ...[
                const SizedBox(height: 16),
                _ObscurableTextField(
                  label: 'Authenticator URI',
                  value: provisioningUri!,
                  icon: Icons.link,
                  iconColor: Colors.blue,
                  copyTooltip: 'Copy URI',
                  copySnack: 'URI copied to clipboard!',
                  openUri: provisioningUri,
                ),
              ],
              const SizedBox(height: 32),
              if (totpSecret != null && provisioningUri != null) ...[
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Enter code from authenticator',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _onVerify,
                    child: const Text('Verify and Continue'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TwoFABackupCodesScreen extends StatelessWidget {
  final List<String> backupCodes;
  const TwoFABackupCodesScreen({required this.backupCodes, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Backup Codes')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: theme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 10),
                          Text(
                            'Save Your Backup Codes',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'These codes can be used to access your account if you lose access to your authenticator app. Each code can be used only once.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: backupCodes.map((c) => Chip(
                                label: SelectableText(
                                  c,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontFamily: 'monospace',
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                backgroundColor: theme.colorScheme.background,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              )).toList(),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  tooltip: 'Copy all codes',
                                  onPressed: () async {
                                    final codes = backupCodes.join('\n');
                                    await Clipboard.setData(ClipboardData(text: codes));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Backup codes copied to clipboard!')),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                Text('Copy all', style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Keep these codes in a safe place. You will not be able to see them again.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const TwoFAEnabledScreen()),
                    );
                  },
                  label: const Text('Done'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ObscurableTextField extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String copyTooltip;
  final String copySnack;
  final String? openUri;

  const _ObscurableTextField({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.copyTooltip,
    required this.copySnack,
    this.openUri,
    Key? key,
  }) : super(key: key);

  @override
  State<_ObscurableTextField> createState() => _ObscurableTextFieldState();
}

class _ObscurableTextFieldState extends State<_ObscurableTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(widget.icon, color: widget.iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: TextEditingController(text: widget.value),
                readOnly: true,
                obscureText: _obscure,
                enableInteractiveSelection: false,
                decoration: InputDecoration(
                  labelText: widget.label,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                style: theme.textTheme.bodyLarge,
              ),
            ),
            IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              tooltip: _obscure ? 'Show' : 'Hide',
              onPressed: () {
                setState(() {
                  _obscure = !_obscure;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: widget.copyTooltip,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: widget.value));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(widget.copySnack)),
                  );
                }
              },
            ),
            if (widget.openUri != null)
              IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: 'Open in Authenticator App',
                onPressed: () async {
                  final uri = Uri.parse(widget.openUri!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not launch authenticator app.')),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
