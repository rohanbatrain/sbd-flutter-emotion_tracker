import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/utils/http_util.dart';
import 'package:emotion_tracker/providers/shared_prefs_provider.dart';
import 'package:emotion_tracker/providers/user_agent_util.dart';

class TrustedUserAgentLockdownService {
  final Ref ref;
  TrustedUserAgentLockdownService(this.ref);

  String get _baseUrl {
    final protocol = ref.read(serverProtocolProvider);
    final domain = ref.read(serverDomainProvider);
    return '$protocol://$domain';
  }

  Uri _buildUri(String path) {
    if (path.startsWith('http')) return Uri.parse(path);
    return Uri.parse('$_baseUrl$path');
  }

  Future<String?> _getAccessToken() async {
    final storage = ref.read(secureStorageProvider);
    return await storage.read(key: 'access_token');
  }

  Future<Map<String, dynamic>> getStatus() async {
    final token = await _getAccessToken();
    if (token == null) throw Exception('Not authenticated');
    final url = _buildUri('/auth/trusted-user-agents/lockdown-status');
    final userAgent = await getUserAgent();
    final response = await HttpUtil.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'User-Agent': userAgent,
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch status: ${response.body}');
    }
  }

  Future<void> requestLockdown({required String action, required List<String> trustedUserAgents}) async {
    final token = await _getAccessToken();
    if (token == null) throw Exception('Not authenticated');
    final url = _buildUri('/auth/trusted-user-agents/lockdown-request');
    final userAgent = await getUserAgent();
    final response = await HttpUtil.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'User-Agent': userAgent,
      },
      body: jsonEncode({
        'action': action,
        'trusted_user_agents': trustedUserAgents,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Request failed: ${response.body}');
    }
  }

  Future<void> confirmLockdown(String code) async {
    final token = await _getAccessToken();
    if (token == null) throw Exception('Not authenticated');
    final url = _buildUri('/auth/trusted-user-agents/lockdown-confirm');
    final userAgent = await getUserAgent();
    final response = await HttpUtil.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'User-Agent': userAgent,
      },
      body: jsonEncode({'code': code}),
    );
    if (response.statusCode != 200) {
      throw Exception('Confirmation failed: ${response.body}');
    }
  }
}

final trustedUserAgentLockdownServiceProvider = Provider((ref) => TrustedUserAgentLockdownService(ref));
