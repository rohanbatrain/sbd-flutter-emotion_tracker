import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final serverDomainProvider = StateNotifierProvider<ServerDomainNotifier, String>((ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  return prefsAsync.maybeWhen(
    data: (prefs) => ServerDomainNotifier(prefs),
    orElse: () => ServerDomainNotifier(null),
  );
});

final serverProtocolProvider = StateNotifierProvider<ServerProtocolNotifier, String>((ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  return prefsAsync.maybeWhen(
    data: (prefs) => ServerProtocolNotifier(prefs),
    orElse: () => ServerProtocolNotifier(null),
  );
});

class ServerDomainNotifier extends StateNotifier<String> {
  final SharedPreferences? prefs;
  static const String _key = 'server_domain';

  ServerDomainNotifier(this.prefs) : super('dev-app-sbd.rohanbatra.in') {
    _load();
  }

  Future<void> _load() async {
    if (prefs != null) {
      final domain = prefs!.getString(_key);
      if (domain != null && domain.isNotEmpty) state = domain;
    }
  }

  Future<void> setDomain(String domain) async {
    state = domain;
    if (prefs != null) {
      await prefs!.setString(_key, domain);
    }
  }
}

class ServerProtocolNotifier extends StateNotifier<String> {
  final SharedPreferences? prefs;
  static const String _key = 'server_protocol';

  ServerProtocolNotifier(this.prefs) : super('https') {
    _load();
  }

  Future<void> _load() async {
    if (prefs != null) {
      final protocol = prefs!.getString(_key);
      if (protocol != null && protocol.isNotEmpty) state = protocol;
    }
  }

  Future<void> setProtocol(String protocol) async {
    state = protocol;
    if (prefs != null) {
      await prefs!.setString(_key, protocol);
    }
  }
}
