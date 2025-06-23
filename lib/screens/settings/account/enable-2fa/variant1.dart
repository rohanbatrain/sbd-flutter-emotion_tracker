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
    final BuildContext? globalContext = ref.read(navigationServiceProvider).currentContext;
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to enable/disable 2FA',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      return didAuthenticate;
    } catch (e) {
      if (mounted && globalContext != null) {
        ScaffoldMessenger.of(globalContext).showSnackBar(
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
          BuildContext? globalContext = ref.read(navigationServiceProvider).currentContext;
          if (globalContext != null) {
            ScaffoldMessenger.of(globalContext).showSnackBar(
              const SnackBar(content: Text('2FA disabled successfully!')),
            );
          }
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
    if (mounted) {
      setState(() {
        _backupCodes = [];
        _showBackupCodes = false;
      });
    }
  }

  void _handleUnauthorized() {
    BuildContext? unauthorizedContext = ref.read(navigationServiceProvider).currentContext;
    if (!mounted) return;
    final navigationService = ref.read(navigationServiceProvider);
    navigationService.navigateToAndClearStack('/auth/v1');
    if (unauthorizedContext != null) {
      ScaffoldMessenger.of(unauthorizedContext).showSnackBar(
        const SnackBar(
          content: Text('Your session has expired. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            : _buildBackupCodesSection(theme),
      ),
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
        Icon(Icons.verified_user, color: theme.primaryColor, size: 60),
        const SizedBox(height: 16),
        Text(
          'Two-Factor Authentication is Active',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your account is protected with 2FA. Keep your backup codes safe.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          'Backup Codes',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
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
              : Text(
                  'No backup codes are currently available. For your security, backup codes are encrypted and cannot be recovered once generated. Please regenerate and securely save them now, as you will not be able to view them again later.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 400;
            return isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Regenerate Backup Codes'),
                        onPressed: _isLoading
                            ? null
                            : () async {
                                setState(() { _isLoading = true; _errorMessage = null; });
                                try {
                                  final result = await ref.read(twoFAServiceProvider).regenerateBackupCodes();
                                  final codes = List<String>.from(result['backup_codes'] ?? []);
                                  final secureStorage = ref.read(secureStorageProvider);
                                  await secureStorage.write(
                                    key: 'user_2fa_backup_codes',
                                    value: jsonEncode(codes),
                                  );
                                  BuildContext? globalContext = ref.read(navigationServiceProvider).currentContext;
                                  if (mounted && globalContext != null) {
                                    setState(() {
                                      _backupCodes = codes;
                                      _isLoading = false;
                                    });
                                    ScaffoldMessenger.of(globalContext).showSnackBar(
                                      const SnackBar(content: Text('Backup codes regenerated!')),
                                    );
                                  }
                                } catch (e) {
                                  String errorMsg = e.toString();
                                  String displayMsg = 'Failed to regenerate backup codes: ';
                                  if (errorMsg.contains('429') || errorMsg.toLowerCase().contains('too many')) {
                                    displayMsg += 'You have made too many requests. Please wait a few minutes before trying again.';
                                  } else {
                                    displayMsg += errorMsg;
                                  }
                                  BuildContext? globalContext = ref.read(navigationServiceProvider).currentContext;
                                  if (mounted && globalContext != null) {
                                    setState(() {
                                      _isLoading = false;
                                      _errorMessage = displayMsg;
                                    });
                                    ScaffoldMessenger.of(globalContext).showSnackBar(
                                      SnackBar(
                                        content: Text(displayMsg),
                                        backgroundColor: Colors.orange,
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          await _deleteBackupCodes();
                          if (mounted) Navigator.of(context).pop();
                        },
                        child: const Text('Done'),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Regenerate Backup Codes'),
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  setState(() { _isLoading = true; _errorMessage = null; });
                                  try {
                                    final result = await ref.read(twoFAServiceProvider).regenerateBackupCodes();
                                    final codes = List<String>.from(result['backup_codes'] ?? []);
                                    final secureStorage = ref.read(secureStorageProvider);
                                    await secureStorage.write(
                                      key: 'user_2fa_backup_codes',
                                      value: jsonEncode(codes),
                                    );
                                    BuildContext? globalContext = ref.read(navigationServiceProvider).currentContext;
                                    if (mounted && globalContext != null) {
                                      setState(() {
                                        _backupCodes = codes;
                                        _isLoading = false;
                                      });
                                      ScaffoldMessenger.of(globalContext).showSnackBar(
                                        const SnackBar(content: Text('Backup codes regenerated!')),
                                      );
                                    }
                                  } catch (e) {
                                    String errorMsg = e.toString();
                                    String displayMsg = 'Failed to regenerate backup codes: ';
                                    if (errorMsg.contains('429') || errorMsg.toLowerCase().contains('too many')) {
                                      displayMsg += 'You have made too many requests. Please wait a few minutes before trying again.';
                                    } else {
                                      displayMsg += errorMsg;
                                    }
                                    BuildContext? globalContext = ref.read(navigationServiceProvider).currentContext;
                                    if (mounted && globalContext != null) {
                                      setState(() {
                                        _isLoading = false;
                                        _errorMessage = displayMsg;
                                      });
                                      ScaffoldMessenger.of(globalContext).showSnackBar(
                                        SnackBar(
                                          content: Text(displayMsg),
                                          backgroundColor: Colors.orange,
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                    }
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _deleteBackupCodes();
                            if (mounted) Navigator.of(context).pop();
                          },
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  );
          },
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
