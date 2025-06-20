import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:lottie/lottie.dart';

class ClientSideEncryptionScreenV1 extends ConsumerStatefulWidget {
  const ClientSideEncryptionScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<ClientSideEncryptionScreenV1> createState() => _ClientSideEncryptionScreenV1State();
}

class _ClientSideEncryptionScreenV1State extends ConsumerState<ClientSideEncryptionScreenV1> {
  final TextEditingController encryptionKeyController = TextEditingController();
  bool isKeyVisible = false;
  bool isUserTyping = false;

  @override
  void initState() {
    super.initState();
    encryptionKeyController.addListener(_handleTyping);
  }

  void _handleTyping() {
    final typing = encryptionKeyController.text.isNotEmpty;
    if (typing != isUserTyping) {
      setState(() {
        isUserTyping = typing;
      });
    }
  }

  @override
  void dispose() {
    encryptionKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  child: isUserTyping
                      ? Icon(Icons.visibility_off_outlined, key: const ValueKey('no-eye'), size: 64, color: theme.primaryColor.withOpacity(0.7))
                      : Container(
                          key: const ValueKey('eye-lottie'),
                          width: 110,
                          height: 110,
                          child: Lottie.asset(
                            'assets/Animation - 1749057870664.json',
                            fit: BoxFit.contain,
                            repeat: true,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Second Brain Database Account-wide Encryption',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter your personal encryption key to unlock and protect your data. Only you know this key. If lost, your encrypted data cannot be recovered.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: encryptionKeyController,
                  obscureText: !isKeyVisible,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Enter your encryption key',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                    filled: true,
                    fillColor: theme.cardTheme.color,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: theme.primaryColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: Icon(Icons.vpn_key, color: theme.iconTheme.color?.withOpacity(0.7)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isKeyVisible ? Icons.visibility_off : Icons.visibility,
                        color: theme.iconTheme.color?.withOpacity(0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          isKeyVisible = !isKeyVisible;
                        });
                      },
                    ),
                  ),
                  onChanged: (_) => _handleTyping(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final key = encryptionKeyController.text.trim();
                      if (key.length < 16) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Encryption key must be at least 16 characters.'),
                            backgroundColor: theme.colorScheme.error,
                          ),
                        );
                        return;
                      }
                      // Save key securely
                      final secureStorage = ref.read(secureStorageProvider);
                      await secureStorage.write(key: 'client_side_encryption_key', value: key);
                      // Show success and redirect
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Encryption key accepted!'),
                          backgroundColor: theme.colorScheme.secondary,
                        ),
                      );
                      Navigator.of(context).pushReplacementNamed('/verify-email/v1');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: theme.floatingActionButtonTheme.foregroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
