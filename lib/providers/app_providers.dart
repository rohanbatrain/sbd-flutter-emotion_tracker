import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/shared_prefs_provider.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'dart:convert';
import 'package:emotion_tracker/providers/user_agent_util.dart';
import 'package:emotion_tracker/utils/http_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Navigation service provider
class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void navigateTo(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  void navigateToAndClearStack(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  void goBack() {
    if (navigatorKey.currentState?.canPop() == true) {
      navigatorKey.currentState?.pop();
    }
  }

  BuildContext? get currentContext => navigatorKey.currentContext;
}

final navigationServiceProvider = Provider<NavigationService>((ref) {
  return NavigationService();
});

// Auth state provider for managing login/signup state
class AuthState {
  final bool isLoggedIn;
  final String? userEmail;
  final String? accessToken;
  final bool isInitialized; // Track if we've checked for existing auth

  const AuthState({
    this.isLoggedIn = false,
    this.userEmail,
    this.accessToken,
    this.isInitialized = false,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userEmail,
    String? accessToken,
    bool? isInitialized,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userEmail: userEmail ?? this.userEmail,
      accessToken: accessToken ?? this.accessToken,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _secureStorage;
  late final SharedPreferences _prefs;

  AuthNotifier(this._secureStorage) : super(const AuthState()) {
    _initializeAuth();
  }

  // Check for existing authentication on app startup
  Future<void> _initializeAuth() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Check if we have stored authentication data
      final accessToken = await _secureStorage.read(key: 'access_token');
      final userEmail = await _secureStorage.read(key: 'user_email');
      final isVerified = _prefs.getBool('is_verified') ?? false;
      final expiresAtString = _prefs.getString('expires_at');
      
      // Check if token exists and is not expired
      bool isValidToken = false;
      if (accessToken != null && accessToken.isNotEmpty) {
        if (expiresAtString != null) {
          try {
            final expiresAt = DateTime.parse(expiresAtString);
            final now = DateTime.now();
            isValidToken = now.isBefore(expiresAt);
          } catch (e) {
            // Invalid date format, consider token invalid
            isValidToken = false;
          }
        } else {
          // No expiry data, assume token is valid for now
          // You might want to validate with server here
          isValidToken = true;
        }
      }
      
      if (isValidToken && isVerified) {
        // User has valid authentication, restore session
        state = state.copyWith(
          isLoggedIn: true,
          userEmail: userEmail,
          accessToken: accessToken,
          isInitialized: true,
        );
      } else {
        // No valid authentication or not verified, clear any stale data
        if (!isValidToken) {
          await _clearStoredAuth();
        }
        state = state.copyWith(isInitialized: true);
      }
    } catch (e) {
      // Error during initialization, assume not logged in
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<void> login(String usernameOrEmail) async {
    // This method is called after successful API login
    // The actual API call happens in the login screen
    
    // Get the latest user data from secure storage
    final userEmail = await _secureStorage.read(key: 'user_email');
    final accessToken = await _secureStorage.read(key: 'access_token');
    
    state = state.copyWith(
      isLoggedIn: true,
      userEmail: userEmail ?? usernameOrEmail,
      accessToken: accessToken,
    );
  }

  Future<void> signup(String username, String email, String password) async {
    // This method is called after successful API signup
    // The actual API call happens in the signup screen
    
    final accessToken = await _secureStorage.read(key: 'access_token');
    
    state = state.copyWith(
      isLoggedIn: true,
      userEmail: email,
      accessToken: accessToken,
    );
  }

  Future<void> logout() async {
    // Clear all stored authentication data
    await _clearStoredAuth();
    
    // Reset state
    state = const AuthState(isInitialized: true);
  }

  Future<void> _clearStoredAuth() async {
    try {
      // Clear secure storage
      await _secureStorage.deleteAll();
      
      // Clear shared preferences auth-related data
      await _prefs.remove('issued_at');
      await _prefs.remove('expires_at');
      await _prefs.remove('is_verified');
      
      // You might want to keep some non-sensitive settings like theme preferences
      // So we're not calling _prefs.clear() here
    } catch (e) {
      // Error clearing storage, but continue with logout
    }
  }

  // Method to refresh token if needed
  Future<bool> refreshTokenIfNeeded() async {
    try {
      final expiresAtString = _prefs.getString('expires_at');
      if (expiresAtString != null) {
        final expiresAt = DateTime.parse(expiresAtString);
        final now = DateTime.now();
        
        // If token expires in less than 5 minutes, consider refreshing
        final shouldRefresh = expiresAt.difference(now).inMinutes < 5;
        
        if (shouldRefresh) {
          // Here you would implement token refresh logic
          // For now, we'll just return false to indicate refresh is needed
          return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final secureStorage = ref.read(secureStorageProvider);
  return AuthNotifier(secureStorage);
});

/// Provides the full API base URL (e.g., https://dev-app-sbd.rohanbatra.in)
final apiBaseUrlProvider = Provider<String>((ref) {
  final protocol = ref.watch(serverProtocolProvider);
  final domain = ref.watch(serverDomainProvider);
  return '$protocol://$domain';
});

/// Provides the health check endpoint (e.g., https://dev-app-sbd.rohanbatra.in/health)
final healthCheckEndpointProvider = Provider<String>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return '$baseUrl/health';
});

/// Function to perform login POST request
Future<Map<String, dynamic>> loginWithApi(WidgetRef ref, String usernameOrEmail, String password) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  final url = Uri.parse('$baseUrl/auth/login');
  try {
    final userAgent = await getUserAgent();
    // Determine if input is email or username
    final emailRegExp = RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}?$');
    final isEmail = emailRegExp.hasMatch(usernameOrEmail);
    final body = isEmail
        ? {'email': usernameOrEmail, 'password': password}
        : {'username': usernameOrEmail, 'password': password};
    final response = await HttpUtil.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': userAgent,
        'X-User-Agent': userAgent,
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      await _processAndStoreAuthData(ref, result, loginEmail: isEmail ? usernameOrEmail : null);
      return result;
    } else if (response.statusCode == 403 && response.body.contains('Email not verified')) {
      // Special case: email not verified
      // Server should respond with: raise HTTPException(status_code=403, detail="Email not verified")
      // This ensures we only trigger email verification for actual unverified emails, not wrong passwords
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      await _processAndStoreAuthData(ref, responseBody, loginEmail: isEmail ? usernameOrEmail : null);
      return {'error': 'email_not_verified', ...responseBody};
    } else {
      throw Exception('Login failed: ${response.statusCode} ${response.body}');
    }
  } catch (e) {
    // Only catch network and Cloudflare errors here, let authentication errors pass through
    if (e is CloudflareTunnelException) {
      throw Exception('CLOUDFLARE_TUNNEL_DOWN: ${e.message}');
    } else if (e is NetworkException) {
      throw Exception('NETWORK_ERROR: ${e.message}');
    } else if (e.toString().contains('Login failed:')) {
      // Re-throw login/authentication errors as-is (don't wrap them)
      rethrow;
    }
    throw Exception('Could not connect to the server. Please check your domain/IP and try again.');
  }
}

Future<void> _processAndStoreAuthData(WidgetRef ref, Map<String, dynamic> result, {String? loginEmail}) async {
  final secureStorage = ref.read(secureStorageProvider);
  
  // Store tokens and other data
  await secureStorage.write(key: 'access_token', value: result['access_token'] ?? '');
  await secureStorage.write(key: 'token_type', value: result['token_type'] ?? '');
  await secureStorage.write(key: 'client_side_encryption', value: result['client_side_encryption']?.toString() ?? 'false');
  await secureStorage.write(key: 'user_role', value: result['role'] ?? 'user');
  
  // Store user details
  if (result['username'] != null && result['username'].isNotEmpty) {
    await secureStorage.write(key: 'user_username', value: result['username']);
  }
  if (result['first_name'] != null && result['first_name'].isNotEmpty) {
    await secureStorage.write(key: 'user_first_name', value: result['first_name']);
  }
  if (result['last_name'] != null && result['last_name'].isNotEmpty) {
    await secureStorage.write(key: 'user_last_name', value: result['last_name']);
  }

  // Store email (handle case where login is via email)
  if (loginEmail != null && loginEmail.isNotEmpty) {
      await secureStorage.write(key: 'user_email', value: loginEmail);
  } else if (result['email'] != null && result['email'].isNotEmpty) {
    await secureStorage.write(key: 'user_email', value: result['email']);
  }

  // Store data in SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('issued_at', result['issued_at']?.toString() ?? '');
  await prefs.setString('expires_at', result['expires_at']?.toString() ?? '');
  await prefs.setBool('is_verified', result['is_verified'] ?? false);
}

/// Function to validate password strength
bool isPasswordStrong(String password) {
  final lengthCheck = password.length >= 8;
  final upperCheck = password.contains(RegExp(r'[A-Z]'));
  final lowerCheck = password.contains(RegExp(r'[a-z]'));
  final digitCheck = password.contains(RegExp(r'\d'));
  final specialCheck = password.contains(RegExp(r'[!@#\$&*~%^()_\-+=\[\]{}|;:,.<>?/]'));
  return lengthCheck && upperCheck && lowerCheck && digitCheck && specialCheck;
}

/// Function to perform registration POST request
Future<Map<String, dynamic>> registerWithApi(
  WidgetRef ref,
  String username,
  String email,
  String password,
  {bool? clientSideEncryption}
) async {
  if (!isPasswordStrong(password)) {
    throw Exception('Password must be at least 8 characters long and contain uppercase, lowercase, digit, and special character.');
  }
  final baseUrl = ref.read(apiBaseUrlProvider);
  final url = Uri.parse('$baseUrl/auth/register');
  try {
    final userAgent = await getUserAgent();
    final body = <String, dynamic>{
      'username': username,
      'email': email,
      'password': password,
      'user_agent': userAgent, // custom user agent
    };
    if (clientSideEncryption != null) {
      body['client_side_encryption'] = clientSideEncryption;
    }
    final response = await HttpUtil.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': userAgent,
        'X-User-Agent': userAgent,
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Registration failed: ${response.statusCode} ${response.body}');
    }
  } catch (e) {
    if (e is CloudflareTunnelException) {
      throw Exception('CLOUDFLARE_TUNNEL_DOWN: ${e.message}');
    } else if (e is NetworkException) {
      throw Exception('NETWORK_ERROR: ${e.message}');
    }
    throw Exception('Could not connect to the server. Please check your domain/IP and try again.');
  }
}

/// Function to check username availability
Future<bool> checkUsernameAvailability(WidgetRef ref, String username) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  final url = Uri.parse('$baseUrl/auth/check-username?username=$username');
  try {
    final userAgent = await getUserAgent();
    final response = await HttpUtil.get(
      url,
      headers: {
        'User-Agent': userAgent,
        'X-User-Agent': userAgent,
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['available'] == true;
    } else {
      throw Exception('Failed to check username: ${response.statusCode}');
    }
  } catch (e) {
    if (e is CloudflareTunnelException) {
      throw Exception('CLOUDFLARE_TUNNEL_DOWN: ${e.message}');
    } else if (e is NetworkException) {
      throw Exception('NETWORK_ERROR: ${e.message}');
    }
    throw Exception('Could not check username. Please check your connection.');
  }
}

/// Function to check email availability
Future<bool> checkEmailAvailability(WidgetRef ref, String email) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  final url = Uri.parse('$baseUrl/auth/check-email?email=$email');
  try {
    final userAgent = await getUserAgent();
    final response = await HttpUtil.get(
      url,
      headers: {
        'User-Agent': userAgent,
        'X-User-Agent': userAgent,
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['available'] == true;
    } else {
      throw Exception('Failed to check email: ${response.statusCode}');
    }
  } catch (e) {
    if (e is CloudflareTunnelException) {
      throw Exception('CLOUDFLARE_TUNNEL_DOWN: ${e.message}');
    } else if (e is NetworkException) {
      throw Exception('NETWORK_ERROR: ${e.message}');
    }
    throw Exception('Could not check email. Please check your connection.');
  }
}