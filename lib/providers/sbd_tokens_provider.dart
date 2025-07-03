import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/providers/shared_prefs_provider.dart';

class SbdTokensState {
  final int? balance;
  final bool isLoading;
  final String? error;
  final List<dynamic>? transactions;

  SbdTokensState({
    this.balance,
    this.isLoading = false,
    this.error,
    this.transactions,
  });

  SbdTokensState copyWith({
    int? balance,
    bool? isLoading,
    String? error,
    List<dynamic>? transactions,
  }) {
    return SbdTokensState(
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      transactions: transactions ?? this.transactions,
    );
  }
}

class SbdTokensNotifier extends StateNotifier<SbdTokensState> {
  final Ref ref;
  SbdTokensNotifier(this.ref) : super(SbdTokensState(isLoading: false));

  Future<String?> _getToken() async {
    final storage = ref.read(secureStorageProvider);
    return await storage.read(key: 'access_token');
  }

  String _getBaseUrl() {
    final protocol = ref.read(serverProtocolProvider);
    final domain = ref.read(serverDomainProvider);
    return '$protocol://$domain';
  }

  Future<void> fetchBalance({String? username}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');
      final baseUrl = _getBaseUrl();
      final url = username != null && username.isNotEmpty
          ? Uri.parse('$baseUrl/sbd_tokens/$username')
          : Uri.parse('$baseUrl/sbd_tokens');
      final res = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        state = state.copyWith(balance: data['sbd_tokens'], isLoading: false, error: null);
      } else if (res.statusCode == 401) {
        state = state.copyWith(isLoading: false, error: 'Session expired. Please log in again.');
      } else {
        state = state.copyWith(isLoading: false, error: jsonDecode(res.body)['detail']?.toString() ?? 'Failed to fetch balance');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> sendTokens({required String toUser, required int amount}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');
      final baseUrl = _getBaseUrl();
      final url = Uri.parse('$baseUrl/sbd_tokens/send');
      final res = await http.post(url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'to_user': toUser,
          'amount': amount,
        }),
      );
      if (res.statusCode == 200) {
        state = state.copyWith(isLoading: false, error: null);
        await fetchBalance();
        return true;
      } else {
        final err = jsonDecode(res.body);
        state = state.copyWith(isLoading: false, error: err['detail']?.toString() ?? 'Failed to send tokens');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> fetchTransactions({String? username, int skip = 0, int limit = 50}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');
      final baseUrl = _getBaseUrl();
      final userPath = username != null && username.isNotEmpty ? '/$username' : '';
      final url = Uri.parse('$baseUrl/sbd_tokens/transactions$userPath?skip=$skip&limit=$limit');
      final res = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        state = state.copyWith(transactions: data['transactions'], isLoading: false, error: null);
      } else {
        state = state.copyWith(isLoading: false, error: jsonDecode(res.body)['detail']?.toString() ?? 'Failed to fetch transactions');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final sbdTokensProvider = StateNotifierProvider<SbdTokensNotifier, SbdTokensState>((ref) {
  return SbdTokensNotifier(ref);
});
