import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/webauthn_service.dart';
import 'package:emotion_tracker/models/webauthn_models.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/core/global_error_handler.dart';

import 'package:emotion_tracker/providers/api_token_service.dart' as api_token;

// FutureProvider for fetching passkey credentials
final passkeyCredentialsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final service = ref.read(webAuthnServiceProvider);
  return await service.listCredentials();
});

class PasskeyManagementScreen extends ConsumerStatefulWidget {
  const PasskeyManagementScreen({super.key});

  @override
  ConsumerState<PasskeyManagementScreen> createState() =>
      _PasskeyManagementScreenState();
}

class _PasskeyManagementScreenState
    extends ConsumerState<PasskeyManagementScreen> {
  bool _isRegistering = false;
  final TextEditingController _deviceNameController = TextEditingController();

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncCredentials = ref.watch(passkeyCredentialsProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Manage Passkeys',
        showCurrency: false,
        showHamburger: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(passkeyCredentialsProvider),
        child: asyncCredentials.when(
          loading:
              () =>
                  const LoadingStateWidget(message: 'Loading your passkeys...'),
          error: (error, stackTrace) {
            return ErrorStateWidget(
              error: error,
              onRetry: () => ref.invalidate(passkeyCredentialsProvider),
            );
          },
          data: (credentials) {
            return _buildCredentialsList(context, theme, credentials);
          },
        ),
      ),
      floatingActionButton:
          _isRegistering
              ? null
              : FloatingActionButton.extended(
                onPressed: () => _showAddPasskeyDialog(context),
                backgroundColor: theme.colorScheme.primary,
                icon: const Icon(Icons.add),
                label: const Text('Add Passkey'),
              ),
    );
  }

  Widget _buildCredentialsList(
    BuildContext context,
    ThemeData theme,
    List<Map<String, dynamic>> credentials,
  ) {
    if (credentials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fingerprint_outlined, size: 64, color: theme.hintColor),
            const SizedBox(height: 16),
            Text(
              'No passkeys found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Set up your first passkey to enable secure, passwordless authentication.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: credentials.length,
      itemBuilder: (context, index) {
        final credential = credentials[index];
        return _buildCredentialCard(context, theme, credential);
      },
    );
  }

  Widget _buildCredentialCard(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> credential,
  ) {
    final String? deviceName = credential['device_name'];
    final String? deviceType = credential['device_type'];
    final DateTime? createdAt =
        credential['created_at'] != null
            ? DateTime.tryParse(credential['created_at'])
            : null;
    final DateTime? lastUsedAt =
        credential['last_used_at'] != null
            ? DateTime.tryParse(credential['last_used_at'])
            : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: Icon(_getDeviceIcon(deviceType), color: Colors.white),
        ),
        title: Text(
          deviceName ?? 'Unnamed Device',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (deviceType != null)
                Text(
                  'Type: ${_formatDeviceType(deviceType)}',
                  style: theme.textTheme.bodySmall,
                ),
              if (createdAt != null)
                Text(
                  'Created: ${_formatDate(createdAt)}',
                  style: theme.textTheme.bodySmall,
                ),
              if (lastUsedAt != null)
                Text(
                  'Last used: ${_formatDate(lastUsedAt)}',
                  style: theme.textTheme.bodySmall,
                )
              else
                Text(
                  'Never used',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          onPressed: () => _showDeleteDialog(context, credential),
          tooltip: 'Delete passkey',
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String? deviceType) {
    switch (deviceType?.toLowerCase()) {
      case 'mobile':
      case 'phone':
        return Icons.smartphone;
      case 'tablet':
        return Icons.tablet;
      case 'desktop':
      case 'computer':
        return Icons.computer;
      case 'security_key':
      case 'usb':
        return Icons.usb;
      default:
        return Icons.fingerprint;
    }
  }

  String _formatDeviceType(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'mobile':
      case 'phone':
        return 'Mobile Device';
      case 'tablet':
        return 'Tablet';
      case 'desktop':
      case 'computer':
        return 'Desktop Computer';
      case 'security_key':
      case 'usb':
        return 'Security Key';
      default:
        return deviceType;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddPasskeyDialog(BuildContext context) async {
    // Check WebAuthn support first
    final service = ref.read(webAuthnServiceProvider);
    final isSupported = await service.isWebAuthnSupported();

    if (!mounted || !context.mounted) return;

    if (!isSupported) {
      _showUnsupportedDialog(context);
      return;
    }

    _showDeviceNameDialog(context);
  }

  void _showDeviceNameDialog(BuildContext context) async {
    final theme = Theme.of(context);

    final deviceName = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: theme.cardColor,
            title: Row(
              children: [
                Icon(
                  Icons.fingerprint,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Add New Passkey',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Give this passkey a name to help you identify it later.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _deviceNameController,
                  decoration: InputDecoration(
                    labelText: 'Device Name (Optional)',
                    hintText: 'e.g., iPhone, MacBook, Security Key',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.device_unknown),
                  ),
                  maxLength: 50,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You\'ll be prompted to use your device\'s biometric authentication or security key.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.8,
                            ),
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
                onPressed: () {
                  _deviceNameController.clear();
                  Navigator.pop(ctx, null);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = _deviceNameController.text.trim();
                  _deviceNameController.clear();
                  Navigator.pop(ctx, name.isEmpty ? null : name);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Passkey'),
              ),
            ],
          ),
    );

    if (deviceName != null && mounted && context.mounted) {
      await _registerPasskey(context, deviceName.isEmpty ? null : deviceName);
    }
  }

  void _showUnsupportedDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: theme.cardColor,
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Passkeys Not Supported',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Passkeys are not supported on this device or browser.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To use passkeys, you need:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• A device with biometric authentication (fingerprint, face recognition)\n'
                        '• A compatible browser or app\n'
                        '• A security key (USB, NFC, or Bluetooth)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'OK',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _registerPasskey(
    BuildContext context,
    String? deviceName,
  ) async {
    setState(() {
      _isRegistering = true;
    });

    try {
      final service = ref.read(webAuthnServiceProvider);

      // Begin registration
      final beginResponse = await service.beginRegistration(
        deviceName: deviceName,
      );

      // TODO: In a real implementation, this would call the WebAuthn API
      // to create the credential using the browser's WebAuthn API
      // For now, we'll simulate a successful registration

      // Complete registration (this would normally include the credential data)
      await service.completeRegistration(beginResponse);

      if (context.mounted) {
        // Refresh the credentials list
        ref.invalidate(passkeyCredentialsProvider);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    deviceName != null
                        ? 'Passkey "$deviceName" has been added successfully'
                        : 'Passkey has been added successfully',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final errorState = GlobalErrorHandler.processError(e);

        // Handle session expiry specially
        if (e is api_token.UnauthorizedException) {
          await GlobalErrorHandler.handleUnauthorized(context, ref);
          return;
        }

        // Show error snackbar with retry action for retryable errors
        if (GlobalErrorHandler.isRetryable(errorState)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(errorState.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_getRegistrationErrorMessage(e))),
                ],
              ),
              backgroundColor: errorState.color,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _registerPasskey(context, deviceName),
              ),
            ),
          );
        } else {
          // Show error snackbar without retry for non-retryable errors
          GlobalErrorHandler.showErrorSnackbar(
            context,
            _getRegistrationErrorMessage(e),
            errorState.type,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    Map<String, dynamic> credential,
  ) async {
    final theme = Theme.of(context);
    final String credentialId = credential['id'] ?? '';
    final String deviceName = credential['device_name'] ?? 'Unnamed Device';

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: theme.cardColor,
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Delete Passkey?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete the passkey "$deviceName"?',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This action cannot be undone. You will need to set up the passkey again if you want to use it.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red[700],
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
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete Passkey'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted && context.mounted) {
      await _deletePasskey(context, credentialId, deviceName);
    }
  }

  Future<void> _deletePasskey(
    BuildContext context,
    String credentialId,
    String deviceName,
  ) async {
    try {
      final service = ref.read(webAuthnServiceProvider);
      await service.deleteCredential(credentialId);

      if (context.mounted) {
        // Refresh the credentials list
        ref.invalidate(passkeyCredentialsProvider);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Passkey "$deviceName" has been deleted')),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final errorState = GlobalErrorHandler.processError(e);

        // Handle session expiry specially
        if (e is api_token.UnauthorizedException) {
          await GlobalErrorHandler.handleUnauthorized(context, ref);
          return;
        }

        // Show error snackbar with retry action for retryable errors
        if (GlobalErrorHandler.isRetryable(errorState)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(errorState.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_getDeleteErrorMessage(e))),
                ],
              ),
              backgroundColor: errorState.color,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed:
                    () => _deletePasskey(context, credentialId, deviceName),
              ),
            ),
          );
        } else {
          // Show error snackbar without retry for non-retryable errors
          GlobalErrorHandler.showErrorSnackbar(
            context,
            _getDeleteErrorMessage(e),
            errorState.type,
          );
        }
      }
    }
  }

  String _getRegistrationErrorMessage(dynamic error) {
    if (error is api_token.UnauthorizedException) {
      return 'Your session has expired. Please log in again.';
    }

    if (error is api_token.RateLimitException) {
      return error.message;
    }

    if (error is WebAuthnException) {
      switch (error.statusCode) {
        case 409:
          return 'A passkey is already registered for this device.';
        case 422:
          return 'Invalid passkey data. Please try again.';
        case 429:
          return 'Too many requests. Please wait before trying again.';
        case 500:
        case 502:
        case 503:
        case 504:
          return 'Server error occurred. Please try again later.';
        default:
          return error.message.isNotEmpty
              ? error.message
              : 'Failed to register passkey. Please try again.';
      }
    }

    // Handle network and tunnel errors
    if (error.toString().contains('CLOUDFLARE_TUNNEL_DOWN') ||
        error.toString().contains('Server tunnel is down')) {
      return 'Server is temporarily unavailable. Please try again later.';
    }

    if (error.toString().contains('NETWORK_ERROR') ||
        error.toString().contains('Network error')) {
      return 'Network connection problem. Please check your internet connection.';
    }

    if (error.toString().contains('timeout') ||
        error.toString().contains('timed out')) {
      return 'Request timed out. Please try again.';
    }

    // Generic error message
    return 'Failed to register passkey. Please try again.';
  }

  String _getDeleteErrorMessage(dynamic error) {
    if (error is api_token.UnauthorizedException) {
      return 'Your session has expired. Please log in again.';
    }

    if (error is api_token.RateLimitException) {
      return error.message;
    }

    if (error is WebAuthnException) {
      switch (error.statusCode) {
        case 404:
          return 'Passkey not found. It may have already been deleted.';
        case 403:
          return 'You do not have permission to delete this passkey.';
        case 429:
          return 'Too many requests. Please wait before trying again.';
        case 500:
        case 502:
        case 503:
        case 504:
          return 'Server error occurred. Please try again later.';
        default:
          return error.message.isNotEmpty
              ? error.message
              : 'Failed to delete passkey. Please try again.';
      }
    }

    // Handle network and tunnel errors
    if (error.toString().contains('CLOUDFLARE_TUNNEL_DOWN') ||
        error.toString().contains('Server tunnel is down')) {
      return 'Server is temporarily unavailable. Please try again later.';
    }

    if (error.toString().contains('NETWORK_ERROR') ||
        error.toString().contains('Network error')) {
      return 'Network connection problem. Please check your internet connection.';
    }

    if (error.toString().contains('timeout') ||
        error.toString().contains('timed out')) {
      return 'Request timed out. Please try again.';
    }

    // Generic error message
    return 'Failed to delete passkey. Please try again.';
  }
}
