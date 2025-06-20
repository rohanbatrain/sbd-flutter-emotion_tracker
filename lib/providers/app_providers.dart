import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/shared_prefs_provider.dart';
import 'package:emotion_tracker/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

/// Provides the full API base URL (e.g., https://example.com)
final apiBaseUrlProvider = Provider<String>((ref) {
  final protocol = ref.watch(serverProtocolProvider);
  final domain = ref.watch(serverDomainProvider);
  return '$protocol://$domain';
});

/// Provides the health check endpoint (e.g., https://example.com/health)
final healthCheckEndpointProvider = Provider<String>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return '$baseUrl/health';
});

/// Function to perform login POST request
Future<Map<String, dynamic>> loginWithApi(WidgetRef ref, String email, String password) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  final url = Uri.parse('$baseUrl/auth/login');
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Login failed: ${response.statusCode} ${response.body}');
    }
  } catch (e) {
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
    final body = <String, dynamic>{
      'username': username,
      'email': email,
      'password': password,
      'registration_app_id': registrationAppId, // from main.dart
    };
    if (clientSideEncryption != null) {
      body['client_side_encryption'] = clientSideEncryption;
    }
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Registration failed: ${response.statusCode} ${response.body}');
    }
  } catch (e) {
    throw Exception('Could not connect to the server. Please check your domain/IP and try again.');
  }
}

/// Function to check username availability
Future<bool> checkUsernameAvailability(WidgetRef ref, String username) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  final url = Uri.parse('$baseUrl/auth/check-username?username=$username');
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['available'] == true;
    } else {
      throw Exception('Failed to check username: \\${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Could not check username. Please check your connection.');
  }
}