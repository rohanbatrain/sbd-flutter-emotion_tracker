// import 'dart:io'; (removed, no longer needed)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  // Removed macOS-specific configuration; use default FlutterSecureStorage for all platforms
  return const FlutterSecureStorage();
});
