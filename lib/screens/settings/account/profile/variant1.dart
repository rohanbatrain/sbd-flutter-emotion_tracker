import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/providers/custom_avatar.dart';
import 'package:emotion_tracker/providers/avatar_unlock_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:emotion_tracker/providers/user_agent_util.dart';

class ProfileScreenV1 extends ConsumerStatefulWidget {
  const ProfileScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreenV1> createState() => _ProfileScreenV1State();
}

class _ProfileScreenV1State extends ConsumerState<ProfileScreenV1> {
  String firstName = '';
  String lastName = '';
  String username = '';
  String userEmail = '';
  String selectedAvatarId = 'person'; // Default avatar
  bool isLoading = true;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final secureStorage = ref.read(secureStorageProvider);
      // Get user data from secure storage
      final email = await secureStorage.read(key: 'user_email') ?? '';
      final firstNameData = await secureStorage.read(key: 'user_first_name') ?? '';
      final lastNameData = await secureStorage.read(key: 'user_last_name') ?? '';
      final usernameData = await secureStorage.read(key: 'user_username') ?? '';
      // Try to get current avatar from backend
      String avatarId = await _getCurrentAvatar() ?? await secureStorage.read(key: 'user_avatar_id') ?? 'person';
      setState(() {
        userEmail = email;
        firstName = firstNameData;
        lastName = lastNameData;
        username = usernameData;
        selectedAvatarId = avatarId;
        // Set controller values
        firstNameController.text = firstNameData;
        lastNameController.text = lastNameData;
        usernameController.text = usernameData;
        emailController.text = email;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveUserData() async {
    try {
      final secureStorage = ref.read(secureStorageProvider);
      
      // Save to secure storage (sensitive data)
      await secureStorage.write(key: 'user_first_name', value: firstNameController.text);
      await secureStorage.write(key: 'user_last_name', value: lastNameController.text);
      await secureStorage.write(key: 'user_username', value: usernameController.text);
      await secureStorage.write(key: 'user_email', value: emailController.text);
      await secureStorage.write(key: 'user_avatar_id', value: selectedAvatarId);
      
      // Update local state
      setState(() {
        firstName = firstNameController.text;
        lastName = lastNameController.text;
        username = usernameController.text;
        userEmail = emailController.text;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<String?> _getAuthToken() async {
    final secureStorage = ref.read(secureStorageProvider);
    return await secureStorage.read(key: 'access_token');
  }

  Future<void> _setCurrentAvatar(String avatarId) async {
    final token = await _getAuthToken();
    if (token == null) return;
    final userAgent = await getUserAgent();
    final baseUrl = ref.read(apiBaseUrlProvider);
    final url = Uri.parse('$baseUrl/avatars/current');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'User-Agent': userAgent,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'avatar_id': avatarId}),
    );
    // ignore: unused_local_variable
    final _ = response;
    // Optionally handle errors here
  }

  // ignore: unused_element
  Future<String?> _getCurrentAvatar() async {
    final token = await _getAuthToken();
    if (token == null) return null;
    final userAgent = await getUserAgent();
    final baseUrl = ref.read(apiBaseUrlProvider);
    final url = Uri.parse('$baseUrl/avatars/current');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'User-Agent': userAgent,
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['avatar_id'] as String?;
    }
    return null;
  }

  Future<void> _showAvatarSelectionDialog() async {
    // Show preloader above everything
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.2),
      transitionDuration: Duration.zero,
      pageBuilder: (context, _, __) => const Center(child: CircularProgressIndicator()),
    );

    // Wait a frame to ensure preloader is visible before dialog
    await Future.delayed(const Duration(milliseconds: 50));

    // Await unlock info before showing dialog
    final avatarUnlockService = ref.read(avatarUnlockProvider);
    Set<String> unlockedAvatars;
    try {
      unlockedAvatars = await avatarUnlockService.getMergedUnlockedAvatars();
    } catch (_) {
      unlockedAvatars = {'person'};
    }

    // Close preloader
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();

    // If no avatars except default
    if (unlockedAvatars.isEmpty || (unlockedAvatars.length == 1 && unlockedAvatars.contains('person'))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You don\'t have any rented/owned avatars. Please purchase or rent them from the shop for this app.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // Show dialog with unlocked avatars
    final newAvatarId = await showDialog<String>(
      context: context,
      builder: (context) => AvatarSelectionDialog(
        currentAvatarId: selectedAvatarId,
        unlockedAvatars: unlockedAvatars,
      ),
    );

    if (newAvatarId != null && newAvatarId != selectedAvatarId) {
      final secureStorage = ref.read(secureStorageProvider);
      await secureStorage.write(key: 'user_avatar_id', value: newAvatarId);
      await _setCurrentAvatar(newAvatarId); // Sync with backend
      setState(() {
        selectedAvatarId = newAvatarId;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Avatar updated!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog({
    required String title,
    required String currentValue,
    required TextEditingController controller,
    required String fieldName,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) async {
    controller.text = currentValue;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text('Edit $title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: keyboardType,
                maxLength: maxLength,
                decoration: InputDecoration(
                  labelText: title,
                  hintText: fieldName == 'user_username' 
                      ? 'Enter username (3-50 chars, a-z, 0-9, _, -)' 
                      : fieldName == 'user_email'
                          ? 'Enter your email address'
                          : 'Enter your $title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primaryColor, width: 2),
                  ),
                  counterText: '', // Always hide counter
                  prefixText: fieldName == 'user_username' ? '@' : null,
                ),
                autofocus: true,
              ),
              if (fieldName == 'user_username')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Username must be 3-50 characters long and contain only lowercase letters, numbers, underscores, and hyphens.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
              ),
              onPressed: () {
                controller.text = currentValue; // Reset to original value
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Save'),
              onPressed: () async {
                // Use centralized validation
                String value = controller.text.trim();
                String? error;
                
                if (fieldName == 'user_username') {
                  error = InputValidator.validateUsername(value);
                } else if (fieldName == 'user_email') {
                  error = InputValidator.validateEmail(value);
                } else if (fieldName == 'user_first_name' || fieldName == 'user_last_name') {
                  if (value.isEmpty) {
                    error = '$title cannot be empty';
                  } else if (value.length > 50) {
                    error = '$title cannot exceed 50 characters';
                  }
                }
                
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: theme.colorScheme.error,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }
                
                controller.text = value;
                Navigator.of(context).pop();
                await _saveUserData();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: theme.primaryColor,
          foregroundColor: theme.colorScheme.onPrimary,
          title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final displayName = username.isNotEmpty ? '@$username' : 'User';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Banner at the top
          Container(
            height: 160,
            width: double.infinity,
            color: Colors.black,
          ),
          // Main content with overlap
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 0, left: 24, right: 24, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 100), // Space for banner and overlap
                // Overlapping avatar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: _showAvatarSelectionDialog,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: _buildAvatarCircle(theme, size: 60), // Increased size
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  child: Text(
                    displayName,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 32),
                // First Name Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: Icon(Icons.person, color: theme.primaryColor),
                    title: Text(
                      'First Name',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      firstName.isNotEmpty ? firstName : 'Not set',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: firstName.isNotEmpty 
                            ? theme.textTheme.bodyMedium?.color 
                            : theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () => _showEditDialog(
                      title: 'First Name',
                      currentValue: firstName,
                      controller: firstNameController,
                      fieldName: 'user_first_name',
                      maxLength: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Last Name Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: Icon(Icons.person_outline, color: theme.primaryColor),
                    title: Text(
                      'Last Name',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      lastName.isNotEmpty ? lastName : 'Not set',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: lastName.isNotEmpty 
                            ? theme.textTheme.bodyMedium?.color 
                            : theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () => _showEditDialog(
                      title: 'Last Name',
                      currentValue: lastName,
                      controller: lastNameController,
                      fieldName: 'user_last_name',
                      maxLength: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Add more profile info here as needed
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCircle(ThemeData theme, {double size = 54}) {
    // If no avatar or only default, show icon
    if (selectedAvatarId == 'person' || selectedAvatarId.isEmpty) {
      return CircleAvatar(
        radius: size,
        backgroundColor: theme.primaryColor.withOpacity(0.15),
        child: Icon(Icons.person, size: size + 10, color: theme.primaryColor),
      );
    } else {
      return CircleAvatar(
        radius: size,
        backgroundColor: theme.primaryColor.withOpacity(0.15),
        child: AvatarDisplay(
          avatar: getAvatarById(selectedAvatarId),
          size: size + 10,
          staticIconColor: theme.primaryColor,
        ),
      );
    }
  }
}
