import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/providers/user_agent_util.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'package:emotion_tracker/providers/shared_prefs_provider.dart';

final bundleUnlockProvider = Provider<BundleUnlockService>((ref) {
  return BundleUnlockService(ref);
});

class BundleUnlockService {
  final Ref ref;
  BundleUnlockService(this.ref);

  /// Attempts to buy a bundle via the /shop/bundles/buy endpoint.
  /// Throws an Exception with a user-friendly message on failure.
  Future<void> buyBundle(BuildContext context, String bundleId) async {
    final storage = ref.read(secureStorageProvider);
    final accessToken = await storage.read(key: 'access_token');
    final protocol = ref.watch(serverProtocolProvider);
    final domain = ref.watch(serverDomainProvider);
    final apiUrl = Uri.parse('$protocol://$domain/shop/bundles/buy');
    final userAgent = await getUserAgent();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('You must be logged in to buy bundles.');
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        apiUrl,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'User-Agent': userAgent,
          'X-User-Agent': userAgent,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'bundle_id': bundleId}),
      );
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      if (response.statusCode == 200) {
        // Success: Optionally update local cache/state here if needed
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bundle purchased successfully!')),
          );
        }
        return;
      }
      // Error handling
      final data = jsonDecode(response.body);
      final detail = data['detail'] ?? 'Unknown error';
      if (response.statusCode == 400 && detail == 'Bundle already owned') {
        throw Exception('You already own this bundle.');
      } else if (response.statusCode == 400 && (detail == 'Not enough SBD tokens' || detail == 'Insufficient SBD tokens or race condition')) {
        throw Exception('You do not have enough SBD tokens.');
      } else if (response.statusCode == 400 && detail == 'Invalid or missing bundle_id') {
        throw Exception('Invalid bundle.');
      } else if (response.statusCode == 403 && detail == 'Shop access denied: invalid client') {
        throw Exception('Shop access denied: invalid client.');
      } else if (response.statusCode == 404 && detail == 'User not found') {
        throw Exception('User not found. Please log in again.');
      } else if (response.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception(detail.toString());
      }
    } catch (e) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      rethrow;
    }
  }

  /// Fetches the list of owned bundle IDs from the server.
  Future<Set<String>> getOwnedBundles() async {
    final storage = ref.read(secureStorageProvider);
    final accessToken = await storage.read(key: 'access_token');
    final protocol = ref.watch(serverProtocolProvider);
    final domain = ref.watch(serverDomainProvider);
    final apiUrl = Uri.parse('$protocol://$domain/shop/bundles/owned');
    final userAgent = await getUserAgent();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('You must be logged in to view owned bundles.');
    }

    final response = await http.get(
      apiUrl,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'User-Agent': userAgent,
        'X-User-Agent': userAgent,
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data['bundles_owned'] is List) {
        final List owned = data['bundles_owned'];
        return owned.map<String>((e) => e['bundle_id'] as String).toSet();
      } else if (data is List) {
        return Set<String>.from(data);
      } else if (data is Map && data['owned_bundles'] is List) {
        return Set<String>.from(data['owned_bundles']);
      }
      throw Exception('Unexpected response format.');
    } else {
      throw Exception('Failed to fetch owned bundles.');
    }
  }
}
