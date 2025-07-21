import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/api_token_service.dart';
import 'token_display_dialog.dart';

class CreateTokenDialog extends ConsumerStatefulWidget {
  const CreateTokenDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateTokenDialog> createState() => _CreateTokenDialogState();
}

class _CreateTokenDialogState extends ConsumerState<CreateTokenDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Token description is required';
    }
    if (value.trim().length < 3) {
      return 'Description must be at least 3 characters long';
    }
    if (value.trim().length > 100) {
      return 'Description must be less than 100 characters';
    }
    return null;
  }

  Future<void> _createToken() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(apiTokenServiceProvider);
      final token = await service.createToken(_descriptionController.text.trim());
      
      if (mounted) {
        // Close the create dialog and return the token
        Navigator.of(context).pop(token);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is UnauthorizedException) {
      // Handle session expiry - close dialog and let parent handle navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.logout, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Your session has expired. Please log in again.')),
                ],
              ),
              backgroundColor: Colors.orange[600],
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
      return 'Session expired. Please log in again.';
    }
    
    if (error is RateLimitException) {
      return error.message;
    }
    
    if (error is ApiException) {
      switch (error.statusCode) {
        case 422:
          return 'Invalid token description. Please check your input and try again.';
        case 403:
          return 'You do not have permission to create API tokens.';
        case 409:
          return 'A token with this description already exists. Please use a different description.';
        case 429:
          return 'Too many requests. Please wait before creating another token.';
        case 500:
        case 502:
        case 503:
        case 504:
          return 'Server error occurred. Please try again later.';
        default:
          return error.message.isNotEmpty ? error.message : 'Failed to create token. Please try again.';
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
    
    if (error.toString().contains('timeout') || error.toString().contains('timed out')) {
      return 'Request timed out. Please try again.';
    }
    
    // Generic error message
    return 'Failed to create token. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      backgroundColor: theme.cardColor,
      title: Row(
        children: [
          Icon(
            Icons.key,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Create API Token',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a description for your new API token. This will help you identify it later.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Token Description',
                hintText: 'e.g., Mobile App Integration',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                errorMaxLines: 2,
              ),
              validator: _validateDescription,
              maxLength: 100,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _createToken(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: _isLoading ? theme.hintColor : theme.colorScheme.primary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createToken,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: theme.hintColor,
          ),
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Create Token'),
        ),
      ],
    );
  }
}

/// Shows the create token dialog and returns the created token if successful
Future<ApiToken?> showCreateTokenDialog(BuildContext context) async {
  return await showDialog<ApiToken>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const CreateTokenDialog(),
  );
}