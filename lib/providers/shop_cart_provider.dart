import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'secure_storage_provider.dart';
import 'user_agent_util.dart';
import 'shared_prefs_provider.dart';

final shopCartProvider = Provider<ShopCartService>((ref) {
  return ShopCartService(ref);
});

class ShopCartService {
  final Ref ref;
  ShopCartService(this.ref);

  Future<String?> _getAccessToken() async {
    final storage = ref.read(secureStorageProvider);
    return await storage.read(key: 'access_token');
  }

  Future<String> _getUserAgent() async => await getUserAgent();

  String get _protocol => ref.read(serverProtocolProvider);
  String get _domain => ref.read(serverDomainProvider);

  Uri get _baseUri => Uri.parse('$_protocol://$_domain');

  Future<List<Map<String, dynamic>>> getCart() async {
    final accessToken = await _getAccessToken();
    final userAgent = await _getUserAgent();
    final url = _baseUri.replace(path: '/shop/cart');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'User-Agent': userAgent,
        'Content-Type': 'application/json',
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == 'success') {
      final cart = data['cart'] as List;
      return cart.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception(data['detail'] ?? 'Failed to fetch cart.');
    }
  }

  Future<Map<String, dynamic>> addToCart({
    required String itemId,
    required String itemType,
    List<Map<String, dynamic>>? currentCart,
    Map<String, List<String>>? bundleContents,
  }) async {
    // Ensure theme itemId is always prefixed
    if (itemType == 'theme' && !itemId.startsWith('emotion_tracker-')) {
      itemId = 'emotion_tracker-' + itemId;
    }

    // Prevent adding single items if a bundle containing them is already in the cart
    if (currentCart != null && bundleContents != null) {
      // Normalize all theme IDs in bundleContents
      final normalizedBundleContents = <String, List<String>>{};
      bundleContents.forEach((bundleId, ids) {
        normalizedBundleContents[bundleId] = ids.map((id) {
          if (id.startsWith('emotion_tracker-')) return id;
          return 'emotion_tracker-' + id;
        }).toList();
      });
      final cartItemIds = <String>{};
      final cartBundleIds = <String>{};
      for (final item in currentCart) {
        switch (item['type']) {
          case 'theme':
            var id = item['theme_id'] ?? '';
            if (!id.startsWith('emotion_tracker-')) {
              id = 'emotion_tracker-' + id;
            }
            cartItemIds.add(id);
            break;
          case 'avatar':
            cartItemIds.add(item['avatar_id'] ?? '');
            break;
          case 'banner':
            cartItemIds.add(item['banner_id'] ?? '');
            break;
          case 'bundle':
            cartBundleIds.add(item['bundle_id'] ?? '');
            break;
        }
      }
      // If adding a bundle, check if any of its items are already in the cart
      if (itemType == 'bundle' && normalizedBundleContents.containsKey(itemId)) {
        final bundleItems = normalizedBundleContents[itemId]!;
        for (final id in bundleItems) {
          if (cartItemIds.contains(id)) {
            throw Exception('You already have an item from this bundle in your cart. Remove it before adding the bundle to avoid wasting tokens.');
          }
        }
      }
      // If adding a single item, check if any bundle in the cart contains it
      if (itemType != 'bundle') {
        String normalizedId = itemId;
        if (itemType == 'theme' && !normalizedId.startsWith('emotion_tracker-')) {
          normalizedId = 'emotion_tracker-' + normalizedId;
        }
        for (final bundleId in cartBundleIds) {
          final bundleItems = (normalizedBundleContents[bundleId] ?? []);
          if (bundleItems.contains(normalizedId)) {
            throw Exception('You already have a bundle in your cart that contains this item. Remove the bundle before adding the single item to avoid wasting tokens.');
          }
        }
      }
    }

    final accessToken = await _getAccessToken();
    final userAgent = await _getUserAgent();
    final url = _baseUri.replace(path: '/shop/cart/add');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'User-Agent': userAgent,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'item_id': itemId,
          'item_type': itemType,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return data['added'] as Map<String, dynamic>;
      } else {
        throw Exception(data['detail'] ?? 'Failed to add to cart.');
      }
    } catch (e) {
      if (itemType == 'theme') {
        throw Exception('Failed to add theme to cart: '
            '${e.toString()}');
      } else {
        rethrow;
      }
    }
  }

  Future<void> removeFromCart({
    required String itemId,
    required String itemType,
  }) async {
    // Ensure theme itemId is always prefixed
    if (itemType == 'theme' && !itemId.startsWith('emotion_tracker-')) {
      itemId = 'emotion_tracker-' + itemId;
    }
    final accessToken = await _getAccessToken();
    final userAgent = await _getUserAgent();
    final url = _baseUri.replace(path: '/shop/cart/remove');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'User-Agent': userAgent,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'item_id': itemId,
        'item_type': itemType,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == 'success') {
      return;
    } else {
      throw Exception(data['detail'] ?? 'Failed to remove from cart.');
    }
  }

  Future<void> clearCart() async {
    final accessToken = await _getAccessToken();
    final userAgent = await _getUserAgent();
    final url = _baseUri.replace(path: '/shop/cart/clear');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'User-Agent': userAgent,
        'Content-Type': 'application/json',
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == 'success') {
      return;
    } else {
      throw Exception(data['detail'] ?? 'Failed to clear cart.');
    }
  }

  Future<Map<String, dynamic>> checkoutCart() async {
    final accessToken = await _getAccessToken();
    final userAgent = await _getUserAgent();
    final url = _baseUri.replace(path: '/shop/cart/checkout');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'User-Agent': userAgent,
        'Content-Type': 'application/json',
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == 'success') {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'Failed to checkout cart.');
    }
  }
}
