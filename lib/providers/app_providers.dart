import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/shared_prefs_provider.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'dart:convert';
import 'package:emotion_tracker/providers/user_agent_util.dart';
import 'package:emotion_tracker/utils/http_util.dart';

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

  const AuthState({
    this.isLoggedIn = false,
    this.userEmail,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userEmail,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> login(String email, String password) async {
    // Simulate login process
    await Future.delayed(const Duration(milliseconds: 500));
    
    // In a real app, you'd validate credentials here
    state = state.copyWith(isLoggedIn: true, userEmail: email);
  }

  Future<void> signup(String username, String email, String password) async {
    // Simulate signup process
    await Future.delayed(const Duration(milliseconds: 500));
    
    // In a real app, you'd create the account here
    state = state.copyWith(isLoggedIn: true, userEmail: email);
  }

  Future<void> logout() async {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
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
      // Store user_email in secure storage
      final secureStorage = ref.read(secureStorageProvider);
      if (isEmail) {
        await secureStorage.write(key: 'user_email', value: usernameOrEmail);
      } else if (result['email'] != null) {
        await secureStorage.write(key: 'user_email', value: result['email']);
      }
      return result;
    } else if (response.statusCode == 403 && response.body.contains('Email not verified')) {
      // Special case: email not verified
      // Server should respond with: raise HTTPException(status_code=403, detail="Email not verified")
      // This ensures we only trigger email verification for actual unverified emails, not wrong passwords
      return {'error': 'email_not_verified', ...jsonDecode(response.body)};
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

/// Function to resend verification email
Future<void> resendVerificationEmail(WidgetRef ref, {String? email, String? username}) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  final url = Uri.parse('$baseUrl/auth/resend-verification-email');
  
  try {
    final userAgent = await getUserAgent();
    final storage = ref.read(secureStorageProvider);
    
    // Determine what identifier to use
    String? userEmail = email;
    String? userUsername = username;
    
    // If no email provided, try to get it from storage
    if (userEmail == null || userEmail.isEmpty) {
      userEmail = await storage.read(key: 'user_email');
    }
    
    // If still no identifier, throw error
    if ((userEmail == null || userEmail.isEmpty) && (userUsername == null || userUsername.isEmpty)) {
      throw Exception('NO_EMAIL_FOUND: No email or username found. Please enter your email or username.');
    }
    
    // Prepare request body
    Map<String, dynamic> body = {};
    if (userEmail != null && userEmail.isNotEmpty) {
      body['email'] = userEmail;
    } else if (userUsername != null && userUsername.isNotEmpty) {
      body['username'] = userUsername;
    }
    
    final response = await HttpUtil.post(
      url,
      headers: {
        'User-Agent': userAgent,
        'X-User-Agent': userAgent,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    
    if (response.statusCode != 200) {
      // Gracefully handle too many requests error
      if (response.statusCode == 429 || response.body.contains('Too many requests')) {
        throw Exception('TOO_MANY_REQUESTS: Too many requests. Please try again later.');
      }
      // Handle IP blacklisted error
      if (response.body.contains('blacklisted') || response.body.contains('excessive abuse')) {
        throw Exception('IP_BLACKLISTED: Your IP has been temporarily blacklisted due to excessive abuse. Please try again later.');
      }
      throw Exception('Failed to resend verification email: ${response.body}');
    }
  } catch (e) {
    // Re-throw special exceptions without wrapping them
    if (e.toString().contains('NO_EMAIL_FOUND:') || 
        e.toString().contains('TOO_MANY_REQUESTS:') || 
        e.toString().contains('IP_BLACKLISTED:')) {
      rethrow;
    }
    
    if (e is CloudflareTunnelException) {
      throw Exception('CLOUDFLARE_TUNNEL_DOWN: ${e.message}');
    } else if (e is NetworkException) {
      throw Exception('NETWORK_ERROR: ${e.message}');
    }
    
    throw Exception('Could not resend verification email. $e');
  }
}