import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';

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

final timezoneProvider = StateNotifierProvider<TimezoneNotifier, String>((ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  return prefsAsync.maybeWhen(
    data: (prefs) => TimezoneNotifier(prefs),
    orElse: () => TimezoneNotifier(null),
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

class TimezoneNotifier extends StateNotifier<String> {
  final SharedPreferences? prefs;
  static const String _key = 'user_timezone';

  TimezoneNotifier(this.prefs) : super('') {
    // Do not call _load or set state here to avoid build errors
  }

  Future<void> load() async {
    if (prefs == null) return;
    final tz = prefs!.getString(_key);
    if (tz != null && tz.isNotEmpty && state != tz) {
      state = tz;
    }
  }

  Future<void> setTimezone(String timezone) async {
    if (state != timezone) {
      // Defer state update to after build to avoid setState during build errors
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (state != timezone) state = timezone;
      });
    }
    if (prefs != null) {
      await prefs!.setString(_key, timezone);
    }
  }
}
