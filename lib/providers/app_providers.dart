import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/shared_prefs_provider.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/providers/transition_provider.dart';
import 'dart:convert';
import 'package:emotion_tracker/providers/user_agent_util.dart';
import 'package:emotion_tracker/utils/http_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

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

  // Enhanced navigation with custom transitions
  Future<T?> navigateWithTransition<T extends Object?>(
    Widget page, {
    TransitionConfig? config,
    String? routeName,
  }) {
    if (navigatorKey.currentState != null) {
      return navigatorKey.currentState!.pushWithTransition<T>(
        page,
        config: config,
        routeName: routeName,
      );
    }
    return Future.value(null);
  }

  Future<T?> navigateAndReplaceWithTransition<T extends Object?, TO extends Object?>(
    Widget page, {
    TransitionConfig? config,
    String? routeName,
    TO? result,
  }) {
    if (navigatorKey.currentState != null) {
      return navigatorKey.currentState!.pushReplacementWithTransition<T, TO>(
        page,
        config: config,
        routeName: routeName,
        result: result,
      );
    }
    return Future.value(null);
  }

  Future<T?> navigateAndClearWithTransition<T extends Object?>(
    Widget page,
    RoutePredicate predicate, {
    TransitionConfig? config,
    String? routeName,
  }) {
    if (navigatorKey.currentState != null) {
      return navigatorKey.currentState!.pushAndRemoveUntilWithTransition<T>(
        page,
        predicate,
        config: config,
        routeName: routeName,
      );
    }
    return Future.value(null);
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

// Common error handling utility for API calls
class _ApiErrorHandler {
  static Exception handleError(dynamic error) {
    if (error is CloudflareTunnelException) {
      return Exception('CLOUDFLARE_TUNNEL_DOWN: ${error.message}');
    } else if (error is NetworkException) {
      return Exception('NETWORK_ERROR: ${error.message}');
    } else if (error.toString().contains('Login failed:') || 
               error.toString().contains('Registration failed:') ||
               error.toString().contains('Failed to resend verification email:')) {
      // Re-throw authentication/API errors as-is (don't wrap them)
      return error as Exception;
    }
    return Exception('Could not connect to the server. Please check your domain/IP and try again.');
  }
}

// Common utility for API request headers
class _ApiHeaders {
  static Future<Map<String, String>> getCommonHeaders() async {
    final userAgent = await getUserAgent();
    return {
      'Content-Type': 'application/json',
      'User-Agent': userAgent,
      'X-User-Agent': userAgent,
    };
  }
}

// Common utility for storing auth data
class _AuthDataStorage {
  static Future<void> storeAuthData(
    WidgetRef ref, 
    Map<String, dynamic> result, {
    String? loginEmail,
  }) async {
    final secureStorage = ref.read(secureStorageProvider);
    
    // Define what goes to secure storage vs shared preferences
    final secureData = {
      'access_token': result['access_token'] ?? '',
      'token_type': result['token_type'] ?? '',
      'client_side_encryption': result['client_side_encryption']?.toString() ?? 'false',
      'user_role': result['role'] ?? 'user',
    };
    
    final userData = {
      'user_username': result['username'],
      'user_first_name': result['first_name'],
      'user_last_name': result['last_name'],
    };
    
    final prefsData = {
      'issued_at': result['issued_at']?.toString() ?? '',
      'expires_at': result['expires_at']?.toString() ?? '',
      'is_verified': result['is_verified'] ?? false,
    };
    
    // Store secure data
    final secureStoreFutures = secureData.entries
        .map((entry) => secureStorage.write(key: entry.key, value: entry.value))
        .toList();
    
    // Store user data (only if not empty)
    for (final entry in userData.entries) {
      if (entry.value != null && entry.value.toString().isNotEmpty) {
        secureStoreFutures.add(secureStorage.write(key: entry.key, value: entry.value.toString()));
      }
    }
    
    // Handle email storage
    if (loginEmail != null && loginEmail.isNotEmpty) {
      secureStoreFutures.add(secureStorage.write(key: 'user_email', value: loginEmail));
    } else if (result['email'] != null && result['email'].toString().isNotEmpty) {
      secureStoreFutures.add(secureStorage.write(key: 'user_email', value: result['email'].toString()));
    }
    
    // Store preferences data
    final prefs = await SharedPreferences.getInstance();
    final prefsFutures = [
      prefs.setString('issued_at', prefsData['issued_at']!),
      prefs.setString('expires_at', prefsData['expires_at']!),
      prefs.setBool('is_verified', prefsData['is_verified']!),
    ];
    
    // Execute all storage operations in parallel
    await Future.wait([
      ...secureStoreFutures,
      ...prefsFutures,
      secureStorage.delete(key: 'temp_user_password'), // Cleanup
    ]);
  }
}

// Common utility for API response validation
class _ApiResponseValidator {
  static Map<String, dynamic> validateAndParseResponse(http.Response response, String operation) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('$operation failed: ${response.statusCode} ${response.body}');
    }
  }
  
  static bool validateAvailabilityResponse(http.Response response, String field) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['available'] == true;
    } else {
      throw Exception('Failed to check $field: ${response.statusCode}');
    }
  }
}

// Common utility for input validation
class InputValidator {
  // Email validation patterns
  static final RegExp _emailRegExp = RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$');
  static final RegExp _emailRegExpCaseInsensitive = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  
  // Username validation pattern
  static final RegExp _usernameRegExp = RegExp(r'^[a-z0-9_-]{3,50}$');
  static final RegExp _usernamePatternRegExp = RegExp(r'^[a-z0-9_-]+$');
  
  // Domain validation pattern
  static final RegExp _domainRegExp = RegExp(r'^[a-zA-Z0-9.-]+(:[0-9]{1,5})?$');
  
  // Password strength patterns
  static final RegExp _upperCaseRegExp = RegExp(r'[A-Z]');
  static final RegExp _lowerCaseRegExp = RegExp(r'[a-z]');
  static final RegExp _digitRegExp = RegExp(r'\d');
  static final RegExp _specialCharRegExp = RegExp(r'[!@#\$&*~%^()_\-+=\[\]{}|;:,.<>?/]');
  
  static bool isEmail(String input) => _emailRegExp.hasMatch(input.toLowerCase());
  
  static bool isEmailCaseInsensitive(String input) => _emailRegExpCaseInsensitive.hasMatch(input);
  
  static bool isValidUsername(String username) => _usernameRegExp.hasMatch(username.toLowerCase());
  
  static bool hasValidUsernamePattern(String username) => _usernamePatternRegExp.hasMatch(username.toLowerCase());
  
  static bool isValidDomain(String domain) => _domainRegExp.hasMatch(domain) && domain.isNotEmpty;
  
  static bool isPasswordStrong(String password) {
    final lengthCheck = password.length >= 8;
    final upperCheck = _upperCaseRegExp.hasMatch(password);
    final lowerCheck = _lowerCaseRegExp.hasMatch(password);
    final digitCheck = _digitRegExp.hasMatch(password);
    final specialCheck = _specialCharRegExp.hasMatch(password);
    return lengthCheck && upperCheck && lowerCheck && digitCheck && specialCheck;
  }
  
  // Validation with detailed error messages
  static String? validateEmail(String email, {bool caseSensitive = false}) {
    if (email.isEmpty) return 'Email cannot be empty';
    final isValid = caseSensitive ? isEmailCaseInsensitive(email) : isEmail(email);
    return isValid ? null : 'Please enter a valid email address';
  }
  
  static String? validateUsername(String username) {
    if (username.isEmpty) return 'Username cannot be empty';
    if (username.length < 3) return 'Username must be at least 3 characters';
    if (username.length > 50) return 'Username must be less than 50 characters';
    if (!hasValidUsernamePattern(username)) {
      return 'Only lowercase letters, numbers, dash (-), and underscore (_)';
    }
    return null;
  }
  
  static String? validatePassword(String password) {
    if (password.isEmpty) return 'Password cannot be empty';
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!_upperCaseRegExp.hasMatch(password)) return 'Password must contain an uppercase letter';
    if (!_lowerCaseRegExp.hasMatch(password)) return 'Password must contain a lowercase letter';
    if (!_digitRegExp.hasMatch(password)) return 'Password must contain a digit';
    if (!_specialCharRegExp.hasMatch(password)) return 'Password must contain a special character';
    return null;
  }
  
  static String? validateDomain(String domain) {
    if (domain.isEmpty) return 'Please enter a domain or IP';
    if (!isValidDomain(domain)) {
      return 'Please enter a valid domain, IP, or domain:port (no spaces or special characters)';
    }
    return null;
  }
}

// Common utility for UI feedback
class UIHelper {
  static void showErrorSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  static void showInfoSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

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
      // Initialize SharedPreferences and read auth data in parallel
      final futures = await Future.wait([
        SharedPreferences.getInstance(),
        _secureStorage.read(key: 'access_token'),
        _secureStorage.read(key: 'user_email'),
      ]);
      
      _prefs = futures[0] as SharedPreferences;
      final accessToken = futures[1] as String?;
      final userEmail = futures[2] as String?;
      
      // Read remaining data from SharedPreferences (these are fast local reads)
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

  Future<Map<String, dynamic>> loginWithToken(WidgetRef ref, String token) async {
    final result = await loginWithTokenApi(ref, token);
    // Update state if login was successful
    if (result['access_token'] != null) {
      final userEmail = result['email'] ?? result['username'];
      final accessToken = result['access_token'];
      state = state.copyWith(
        isLoggedIn: true,
        userEmail: userEmail,
        accessToken: accessToken,
      );
      // Ensure is_verified is up-to-date from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final isVerified = prefs.getBool('is_verified');
      result['is_verified'] = isVerified;
    }
    return result;
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
Future<Map<String, dynamic>> loginWithApi(
  WidgetRef ref,
  String usernameOrEmail,
  String password, {
  String? twoFaCode,
  String? twoFaMethod,
}) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  final url = Uri.parse('$baseUrl/auth/login');
  try {
    final headers = await _ApiHeaders.getCommonHeaders();
    // Determine if input is email or username
    final isEmail = InputValidator.isEmail(usernameOrEmail);
    final body = <String, dynamic>{
      if (isEmail) 'email': usernameOrEmail else 'username': usernameOrEmail,
      'password': password,
    };

    if (twoFaCode != null && twoFaMethod != null) {
      body['two_fa_code'] = twoFaCode;
      body['two_fa_method'] = twoFaMethod;
    }

    final response = await HttpUtil.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      final result = _ApiResponseValidator.validateAndParseResponse(response, 'Login');
      await _AuthDataStorage.storeAuthData(ref, result, loginEmail: isEmail ? usernameOrEmail : null);
      return result;
    } else if (response.statusCode == 403 && response.body.contains('Email not verified')) {
      // Special case: email not verified
      // Server should respond with: raise HTTPException(status_code=403, detail="Email not verified")
      // This ensures we only trigger email verification for actual unverified emails, not wrong passwords
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      final secureStorage = ref.read(secureStorageProvider);
      if (responseBody['email'] != null) {
        await secureStorage.write(key: 'user_email', value: responseBody['email']);
      }
      if (responseBody['username'] != null) {
        await secureStorage.write(key: 'user_username', value: responseBody['username']);
      }
      await secureStorage.write(key: 'temp_user_password', value: password);
      return {'error': 'email_not_verified', ...responseBody};
    } else {
throw Exception('Login failed: ${response.statusCode} ${response.body}');
    }
  } catch (e) {
    // Only catch network and Cloudflare errors here, let authentication errors pass through
    throw _ApiErrorHandler.handleError(e);
  }
}

/// Function to perform login with token
Future<Map<String, dynamic>> loginWithTokenApi(
  WidgetRef ref,
  String token,
) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  final url = Uri.parse('$baseUrl/auth/validate-token');
  try {
    final headers = await _ApiHeaders.getCommonHeaders();
    headers['Authorization'] = 'Bearer $token';
    final response = await HttpUtil.get(
      url,
      headers: headers,
      // No body needed, token is in Authorization header
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // Store login data using the same logic as normal login
      await _AuthDataStorage.storeAuthData(ref, data);
      return data;
    } else if (response.statusCode == 403 && response.body.contains('Email not verified')) {
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      final secureStorage = ref.read(secureStorageProvider);
      if (responseBody['email'] != null) {
        await secureStorage.write(key: 'user_email', value: responseBody['email']);
      }
      if (responseBody['username'] != null) {
        await secureStorage.write(key: 'user_username', value: responseBody['username']);
      }
      return {'error': 'email_not_verified', ...responseBody};
    } else {
      throw Exception('Token Login failed: ${response.statusCode} ${response.body}');
    }
  } catch (e) {
    throw _ApiErrorHandler.handleError(e);
  }
}

/// Function to perform registration POST request
Future<Map<String, dynamic>> registerWithApi(
  WidgetRef ref,
  String username,
  String email,
  String password,
  {bool? clientSideEncryption}
) async {
  if (!InputValidator.isPasswordStrong(password)) {
    throw Exception('Password must be at least 8 characters long and contain uppercase, lowercase, digit, and special character.');
  }
  final baseUrl = ref.read(apiBaseUrlProvider);
  final url = Uri.parse('$baseUrl/auth/register');
  try {
    final headers = await _ApiHeaders.getCommonHeaders();
    final body = <String, dynamic>{
      'username': username,
      'email': email,
      'password': password,
      'user_agent': headers['User-Agent']!, // reuse user agent from headers
    };
    if (clientSideEncryption != null) {
      body['client_side_encryption'] = clientSideEncryption;
    }
    final response = await HttpUtil.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    final result = _ApiResponseValidator.validateAndParseResponse(response, 'Registration');
    await _AuthDataStorage.storeAuthData(ref, result, loginEmail: email);
    return result;
  } catch (e) {
    throw _ApiErrorHandler.handleError(e);
  }
}

/// Function to resend verification email
Future<void> resendVerificationEmail(WidgetRef ref) async {
  final storage = ref.read(secureStorageProvider);
  final email = await storage.read(key: 'user_email');
  final username = await storage.read(key: 'user_username');

  if ((email == null || email.isEmpty) && (username == null || username.isEmpty)) {
    throw Exception('Could not find your email or username to resend verification.');
  }

  final baseUrl = ref.read(apiBaseUrlProvider);
  final url = Uri.parse('$baseUrl/auth/resend-verification-email');

  final body = <String, String>{};
  if (email != null && email.isNotEmpty) {
    body['email'] = email;
  } else if (username != null && username.isNotEmpty) {
    body['username'] = username;
  }

  try {
    final headers = await _ApiHeaders.getCommonHeaders();
    final response = await HttpUtil.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    // Validate response - 200 means success for this endpoint
    if (response.statusCode != 200) {
      throw Exception('Failed to resend verification email: ${response.statusCode} ${response.body}');
    }
  } catch (e) {
    throw _ApiErrorHandler.handleError(e);
  }
}

/// Function to check username availability
Future<bool> checkUsernameAvailability(WidgetRef ref, String username) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  final url = Uri.parse('$baseUrl/auth/check-username?username=$username');
  try {
    final headers = await _ApiHeaders.getCommonHeaders();
    final response = await HttpUtil.get(
      url,
      headers: headers,
    );
    return _ApiResponseValidator.validateAvailabilityResponse(response, 'username');
  } catch (e) {
    throw _ApiErrorHandler.handleError(e);
  }
}

/// Function to check email availability
Future<bool> checkEmailAvailability(WidgetRef ref, String email) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  final url = Uri.parse('$baseUrl/auth/check-email?email=$email');
  try {
    final headers = await _ApiHeaders.getCommonHeaders();
    final response = await HttpUtil.get(
      url,
      headers: headers,
    );
    return _ApiResponseValidator.validateAvailabilityResponse(response, 'email');
  } catch (e) {
    throw _ApiErrorHandler.handleError(e);
  }
}

/// Function to validate a JWT access token (user must be verified and have client-side encryption enabled)
Future<bool> validateAccessToken(WidgetRef ref, String accessToken) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  final url = Uri.parse('$baseUrl/auth/validate-token');
  try {
    final headers = await _ApiHeaders.getCommonHeaders();
    headers['Authorization'] = 'Bearer $accessToken';
    final response = await HttpUtil.get(
      url,
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // Always overwrite these fields on each login
      final secureStorage = ref.read(secureStorageProvider);
      final prefs = await SharedPreferences.getInstance();
      await secureStorage.write(key: 'client_side_encryption', value: data['client_side_encryption']?.toString() ?? '');
      await secureStorage.write(key: 'user_role', value: data['role']?.toString() ?? '');
      await secureStorage.write(key: 'user_username', value: data['username']?.toString() ?? '');
      await secureStorage.write(key: 'user_email', value: data['email']?.toString() ?? '');
      await prefs.setString('issued_at', data['issued_at']?.toString() ?? '');
      await prefs.setString('expires_at', data['expires_at']?.toString() ?? '');
      await prefs.setBool('is_verified', data['is_verified'] == true || data['is_verified'] == 'true');
      return data['token'] == 'valid';
    }
    return false;
  } catch (e) {
    // Treat any error as invalid token
    return false;
  }
}

/// Function to send forgot password reset link (with rate limit handling)
Future<void> sendForgotPasswordResetLink(WidgetRef ref, String email) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  final url = Uri.parse('$baseUrl/auth/forgot-password');
  final headers = await _ApiHeaders.getCommonHeaders();
  final response = await HttpUtil.post(
    url,
    headers: headers,
    body: jsonEncode({'email': email}),
  );
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return;
  } else if (response.statusCode == 429) {
    String message = 'Too many requests. Please wait before trying again.';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] is String) {
        message = body['detail'];
      }
    } catch (_) {}
    throw RateLimitException(message);
  } else {
    throw Exception('Failed to send reset link: \\${response.statusCode} \\${response.body}');
  }
}

/// Function to resend forgot password reset link (calls /resend-verification-email)
Future<void> resendForgotPasswordResetLink(WidgetRef ref, String email) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  final url = Uri.parse('$baseUrl/resend-verification-email');
  final headers = await _ApiHeaders.getCommonHeaders();
  final response = await HttpUtil.post(
    url,
    headers: headers,
    body: jsonEncode({'email': email}),
  );
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return;
  } else if (response.statusCode == 429) {
    String message = 'Too many requests. Please wait before trying again.';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] is String) {
        message = body['detail'];
      }
    } catch (_) {}
    throw RateLimitException(message);
  } else {
    throw Exception('Failed to resend reset link: \\${response.statusCode} \\${response.body}');
  }
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);
  @override
  String toString() => 'RateLimitException: $message';
}