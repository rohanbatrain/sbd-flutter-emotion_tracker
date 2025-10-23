
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../secure_storage_provider.dart';
import '../user_agent_util.dart';
import '../shared_prefs_provider.dart';

final familyPurchaseRequestProvider = Provider<FamilyPurchaseRequestService>((ref) {
  return FamilyPurchaseRequestService(ref);
});

class FamilyPurchaseRequestService {
  final Ref ref;
  FamilyPurchaseRequestService(this.ref);

  Future<String?> _getAccessToken() async {
    final storage = ref.read(secureStorageProvider);
    return await storage.read(key: 'access_token');
  }

  Future<String> _getUserAgent() async => await getUserAgent();

  String get _protocol => ref.read(serverProtocolProvider);
  String get _domain => ref.read(serverDomainProvider);

  Uri get _baseUri => Uri.parse('$_protocol://$_domain');

  Future<List<Map<String, dynamic>>> getPurchaseRequests(String familyId) async {
    final accessToken = await _getAccessToken();
    final userAgent = await _getUserAgent();
    final url = _baseUri.replace(
      path: '/family/wallet/purchase-requests',
      queryParameters: {'family_id': familyId},
    );
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'User-Agent': userAgent,
        'X-User-Agent': userAgent,
        'Content-Type': 'application/json',
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(data['detail'] ?? 'Failed to fetch purchase requests.');
    }
  }

  Future<Map<String, dynamic>> approvePurchaseRequest(String requestId) async {
    final accessToken = await _getAccessToken();
    final userAgent = await _getUserAgent();
    final url = _baseUri.replace(path: '/family/wallet/purchase-requests/$requestId/approve');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'User-Agent': userAgent,
        'X-User-Agent': userAgent,
        'Content-Type': 'application/json',
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'Failed to approve purchase request.');
    }
  }

  Future<Map<String, dynamic>> denyPurchaseRequest(String requestId, {String? reason}) async {
    final accessToken = await _getAccessToken();
    final userAgent = await _getUserAgent();
    final url = _baseUri.replace(path: '/family/wallet/purchase-requests/$requestId/deny');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'User-Agent': userAgent,
        'X-User-Agent': userAgent,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'reason': reason}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'Failed to deny purchase request.');
    }
  }
}
