import 'dart:convert';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/providers/two_fa_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class Enable2FAScreenV1 extends ConsumerStatefulWidget {
  const Enable2FAScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<Enable2FAScreenV1> createState() => _Enable2FAScreenV1State();
}

class _Enable2FAScreenV1State extends ConsumerState<Enable2FAScreenV1> {
  bool _is2faEnabled = false;
  bool _isLoading = true;
  String? _qrCodeUrl;
  String? _qrCodeData; // This will now hold the provisioning_uri
  String? _totpSecret; // To hold the totp_secret
  List<String> _backupCodes = [];
  bool _showBackupCodes = false;
  String? _errorMessage;
  final TextEditingController _verificationCodeController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _load2faStatus();
  }

  @override
  void dispose() {
    _verificationCodeController.dispose();
    super.dispose();
  }

  void _load2faStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final status = await ref.read(twoFAServiceProvider).get2FAStatus();
      if (mounted) {
        setState(() {
          _is2faEnabled = status['enabled'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load 2FA status: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _authenticate(BuildContext context) async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to enable/disable 2FA',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      return didAuthenticate;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication error: ${e.toString()}')),
        );
      }
      return false;
    }
  }

  void _handleToggle2FA(bool value) async {
    if (value) {
      // Enabling 2FA
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        final result = await ref.read(twoFAServiceProvider).setup2FA();
        // Store backup codes from setup endpoint if present
        if (result['backup_codes'] != null) {
          final codes = List<String>.from(result['backup_codes']);
          final secureStorage = ref.read(secureStorageProvider);
          await secureStorage.write(
            key: 'user_2fa_backup_codes',
            value: jsonEncode(codes),
          );
          _backupCodes = codes;
        }
        if (mounted) {
          setState(() {
            _qrCodeUrl = result['qr_code_url'];
            _qrCodeData = result['provisioning_uri'];
            _totpSecret = result['totp_secret'];
            _is2faEnabled = true; // Keep the toggle on
            _isLoading = false;
          });
        }
      } on UnauthorizedException {
        _handleUnauthorized();
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = "Failed to setup 2FA: ${e.toString()}";
            _isLoading = false;
            _is2faEnabled = false; // Revert toggle on error
          });
        }
      }
    } else {
      // Disabling 2FA
      final authenticated = await _authenticate(context);
      if (!authenticated) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await ref.read(twoFAServiceProvider).disable2FA();
        final secureStorage = ref.read(secureStorageProvider);
        await secureStorage.write(key: 'user_2fa_enabled', value: 'false');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _is2faEnabled = false;
            _qrCodeUrl = null;
            _showBackupCodes = false;
            _backupCodes = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('2FA disabled successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = "Failed to disable 2FA: ${e.toString()}";
            _isLoading = false;
          });
        }
      }
    }
  }

  void _verifyAndCompleteSetup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ref
          .read(twoFAServiceProvider)
          .verify2FA(_verificationCodeController.text);
      final secureStorage = ref.read(secureStorageProvider);
      await secureStorage.write(key: 'user_2fa_enabled', value: 'true');
      // Store backup codes securely for one-time view
      if (result['backup_codes'] != null) {
        final codes = List<String>.from(result['backup_codes']);
        await secureStorage.write(
          key: 'user_2fa_backup_codes',
          value: jsonEncode(codes),
        );
        // Set codes in state immediately for instant UI update
        _backupCodes = codes;
      }

      if (mounted) {
        setState(() {
          _showBackupCodes = true;
          _isLoading = false;
          _qrCodeUrl = null; // Hide QR code section
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Verification failed: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadBackupCodes() async {
    final secureStorage = ref.read(secureStorageProvider);
    final codesJson = await secureStorage.read(key: 'user_2fa_backup_codes');
    if (codesJson != null) {
      setState(() {
        _backupCodes = List<String>.from(jsonDecode(codesJson));
      });
    }
  }

  Future<void> _deleteBackupCodes() async {
    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.delete(key: 'user_2fa_backup_codes');
    setState(() {
      _backupCodes = [];
      _showBackupCodes = false;
    });
  }

  void _handleUnauthorized() {
    if (!mounted) return;
    final navigationService = ref.read(navigationServiceProvider);
    navigationService.navigateToAndClearStack('/auth/v1');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your session has expired. Please log in again.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Two-Factor Authentication',
        showHamburger: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading && _qrCodeUrl == null && !_showBackupCodes
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_is2faEnabled) ...[
                      Text(
                        'Enable Two-Factor Authentication',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Two-factor authentication (2FA) adds an extra layer of security to your account. When enabled, you'll need to enter a verification code from your authenticator app in addition to your password when you sign in.",
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Enable 2FA',
                              style: theme.textTheme.titleMedium),
                          Switch(
                            value: _is2faEnabled,
                            onChanged: _isLoading ? null : _handleToggle2FA,
                            activeColor: theme.primaryColor,
                            activeTrackColor: _isLoading && _is2faEnabled
                                ? Colors.orange.withOpacity(0.5)
                                : theme.primaryColor.withOpacity(0.5),
                            inactiveThumbColor: theme.textTheme.bodyLarge?.color
                                ?.withOpacity(0.6),
                            inactiveTrackColor: theme.dividerColor,
                          ),
                        ],
                      ),
                    ),
                    if (_is2faEnabled)
                      _buildEnabled2faSection(theme)
                    else
                      _buildDisabled2faSection(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDisabled2faSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          'How to Set Up 2FA',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "1. Download an authenticator app like Authy or Google Authenticator.\n"
          "2. Scan the QR code below with your authenticator app.\n"
          "3. Enter the verification code from your app to complete the setup.",
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Center(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.asset(
                'assets/2fa.png', // Placeholder
                width: MediaQuery.of(context).size.width * 0.7,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnabled2faSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: Center(
        child: _isLoading
            ? Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Processing...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              )
            : _showBackupCodes
                ? _buildBackupCodesSection(theme)
                : _buildVerificationSection(theme),
      ),
    );
  }

  Widget _buildVerificationSection(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Scan the QR Code with your authenticator app',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor)),
          child: _buildQrCodeWidget(),
        ),
        const SizedBox(height: 24),
        if (_qrCodeData != null) ...[
          Text(
            'Or copy the setup URI:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: _qrCodeData),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Setup URI',
                    border: const OutlineInputBorder(),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Copy to clipboard',
                child: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _qrCodeData!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Setup URI copied to clipboard!')),
                    );
                  },
                ),
              ),
              Tooltip(
                message: 'Open in Authenticator App',
                child: IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () async {
                    final uri = Uri.parse(_qrCodeData!);
                    // Use url_launcher to open in external app
                    try {
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open authenticator app.')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (_totpSecret != null) ...[
          Text(
            'Or enter this secret key manually:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: _totpSecret),
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Secret Key',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _totpSecret!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Secret key copied to clipboard!')),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        Text(
          'Enter the 6-digit code from your app below.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _verificationCodeController,
          decoration: const InputDecoration(
            labelText: 'Verification Code',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _verifyAndCompleteSetup,
          child: const Text('Verify & Complete Setup'),
        ),
      ],
    );
  }

  Widget _buildBackupCodesSection(ThemeData theme) {
    // Load backup codes from secure storage if not already loaded
    if (_backupCodes.isEmpty) {
      _loadBackupCodes();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, color: Colors.green, size: 50),
        const SizedBox(height: 16),
        Text(
          '2FA Enabled Successfully!',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        Text(
          'Save these backup codes in a secure place. They can be used to access your account if you lose your device.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _backupCodes.isNotEmpty
              ? Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  alignment: WrapAlignment.center,
                  children: _backupCodes
                      .map((code) => Chip(
                            label: Text(code,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            backgroundColor: theme.scaffoldBackgroundColor,
                          ))
                      .toList(),
                )
              : Column(
                  children: [
                    Text(
                      'No backup codes available.\n\n'
                      'Backup codes are only shown the first time you set up 2FA.\n'
                      'If you need new codes, use the "Regenerate Backup Codes" option.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Regenerate Backup Codes'),
                      onPressed: () async {
                        setState(() { _isLoading = true; _errorMessage = null; });
                        try {
                          final result = await ref.read(twoFAServiceProvider).regenerateBackupCodes();
                          final codes = List<String>.from(result['backup_codes'] ?? []);
                          final secureStorage = ref.read(secureStorageProvider);
                          await secureStorage.write(
                            key: 'user_2fa_backup_codes',
                            value: jsonEncode(codes),
                          );
                          setState(() {
                            _backupCodes = codes;
                            _isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Backup codes regenerated!')),
                          );
                        } catch (e) {
                          setState(() {
                            _isLoading = false;
                            _errorMessage = 'Failed to regenerate backup codes: ${e.toString()}';
                          });
                        }
                      },
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            await _deleteBackupCodes();
          },
          child: const Text('Done'),
        )
      ],
    );
  }

  Widget _buildQrCodeWidget() {
    if (_qrCodeUrl == null) {
      return const Text('QR Code not available.');
    }

    if (_qrCodeUrl!.startsWith('data:image')) {
      try {
        final parts = _qrCodeUrl!.split(',');
        if (parts.length != 2) {
          return const Text('Invalid QR Code data URI.');
        }
        final imageData = base64.decode(parts[1]);
        return Image.memory(
          imageData,
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        );
      } catch (e) {
        return const Text('Failed to decode QR code.');
      }
    } else {
      return Image.network(
        _qrCodeUrl!,
        width: 150,
        height: 150,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          return progress == null ? child : const CircularProgressIndicator();
        },
        errorBuilder: (context, error, stackTrace) {
          return Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              const Text('Failed to load QR Code.'),
            ],
          );
        },
      );
    }
  }
}
