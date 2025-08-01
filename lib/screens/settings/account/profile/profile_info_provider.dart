import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/providers/user_agent_util.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileInfoState {
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String dob;
  final String gender;
  final String bio;
  final bool isLoading;
  final dynamic error;

  ProfileInfoState({
    this.firstName = '',
    this.lastName = '',
    this.username = '',
    this.email = '',
    this.dob = '',
    this.gender = '',
    this.bio = '',
    this.isLoading = false,
    this.error,
  });

  ProfileInfoState copyWith({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? dob,
    String? gender,
    String? bio,
    bool? isLoading,
    dynamic error,
  }) {
    return ProfileInfoState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ProfileInfoNotifier extends StateNotifier<ProfileInfoState> {
  final Ref ref;
  bool _hasLoadedCache = false;
  ProfileInfoNotifier(this.ref) : super(ProfileInfoState()) {
    // Only load cache on first instantiation
    loadFromCache().then((_) {
      // Optionally, only auto-refresh if cache is empty
      if (state.firstName.isEmpty && state.lastName.isEmpty && state.username.isEmpty) {
        refreshProfileInfo();
      }
    });
  }

  Future<void> loadFromCache() async {
    if (_hasLoadedCache) return;
    _hasLoadedCache = true;
    final secureStorage = ref.read(secureStorageProvider);
    state = state.copyWith(
      firstName: await secureStorage.read(key: 'user_first_name') ?? '',
      lastName: await secureStorage.read(key: 'user_last_name') ?? '',
      username: await secureStorage.read(key: 'user_username') ?? '',
      email: await secureStorage.read(key: 'user_email') ?? '',
      dob: await secureStorage.read(key: 'user_dob') ?? '',
      gender: await secureStorage.read(key: 'user_gender') ?? '',
      bio: await secureStorage.read(key: 'user_bio') ?? '',
      isLoading: false,
      error: null,
    );
  }

  Future<void> refreshProfileInfo() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final secureStorage = ref.read(secureStorageProvider);
      final baseUrl = ref.read(apiBaseUrlProvider);
      final token = await secureStorage.read(key: 'access_token');
      if (token == null) throw Exception('No auth token');
      final userAgent = await getUserAgent();
      final url = Uri.parse('$baseUrl/profile/info');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': userAgent,
          'X-User-Agent': userAgent,
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profile = data['profile'] ?? {};
        // Save to secure storage
        await secureStorage.write(key: 'user_first_name', value: profile['user_first_name'] ?? '');
        await secureStorage.write(key: 'user_last_name', value: profile['user_last_name'] ?? '');
        await secureStorage.write(key: 'user_username', value: profile['user_username'] ?? '');
        await secureStorage.write(key: 'user_email', value: profile['user_email'] ?? '');
        await secureStorage.write(key: 'user_dob', value: profile['user_dob'] ?? '');
        await secureStorage.write(key: 'user_gender', value: profile['user_gender'] ?? '');
        await secureStorage.write(key: 'user_bio', value: profile['user_bio'] ?? '');
        state = state.copyWith(
          firstName: profile['user_first_name'] ?? '',
          lastName: profile['user_last_name'] ?? '',
          username: profile['user_username'] ?? '',
          email: profile['user_email'] ?? '',
          dob: profile['user_dob'] ?? '',
          gender: profile['user_gender'] ?? '',
          bio: profile['user_bio'] ?? '',
          isLoading: false,
          error: null,
        );
      } else {
        throw Exception('Failed to fetch profile info');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> updateProfileInfo({
    required String firstName,
    required String lastName,
    required String dob,
    required String gender,
    required String bio,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final secureStorage = ref.read(secureStorageProvider);
      final baseUrl = ref.read(apiBaseUrlProvider);
      final token = await secureStorage.read(key: 'access_token');
      if (token == null) throw Exception('No auth token');
      final userAgent = await getUserAgent();
      final url = Uri.parse('$baseUrl/profile/update');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': userAgent,
          'X-User-Agent': userAgent,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_first_name': firstName,
          'user_last_name': lastName,
          'user_dob': dob,
          'user_gender': gender,
          'user_bio': bio,
        }),
      );
      if (response.statusCode == 200) {
        // Update secure storage
        await secureStorage.write(key: 'user_first_name', value: firstName);
        await secureStorage.write(key: 'user_last_name', value: lastName);
        await secureStorage.write(key: 'user_dob', value: dob);
        await secureStorage.write(key: 'user_gender', value: gender);
        await secureStorage.write(key: 'user_bio', value: bio);
        // Update state
        state = state.copyWith(
          firstName: firstName,
          lastName: lastName,
          dob: dob,
          gender: gender,
          bio: bio,
          isLoading: false,
          error: null,
        );
      } else {
        throw Exception('Failed to update profile info');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }
}

final profileInfoProvider = StateNotifierProvider<ProfileInfoNotifier, ProfileInfoState>((ref) {
  return ProfileInfoNotifier(ref);
});
