import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/providers/shared_prefs_provider.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final loginHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final storage = ref.read(secureStorageProvider);
  final token = await storage.read(key: 'access_token');
  if (token == null) throw Exception('Not authenticated');

  final protocol = ref.read(serverProtocolProvider);
  final domain = ref.read(serverDomainProvider);
  final url = Uri.parse('$protocol://$domain/auth/recent-logins');

  final response = await http.get(
    url,
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['logins']);
  } else {
    throw Exception('Failed to load login history');
  }
});

class LoginHistoryScreen extends ConsumerWidget {
  const LoginHistoryScreen({super.key});

  Color _statusColor(String outcome) =>
      outcome == 'success' ? Colors.green : Colors.red;

  String _formatTimestamp(String ts) {
    final dt = DateTime.tryParse(ts)?.toLocal();
    return dt == null
        ? ts
        : DateFormat('dd MMM yyyy • hh mm a').format(dt); // 27 Jun 2025 • 08 16 PM
  }

  String _shortUserAgent(String ua) {
    if (ua.isEmpty) return 'unknown';
    // `curl/8.14.1` → curl,  `emotion_tracker/1.0.0 …` → emotion_tracker
    return ua.split(RegExp(r'[ /]')).first;
  }

  String _platformFromUserAgent(String ua) {
    final lower = ua.toLowerCase();
    if (lower.contains('android')) return 'Android';
    if (lower.contains('linux')) return 'Linux';
    if (lower.contains('windows')) return 'Windows';
    if (lower.contains('macos') || lower.contains('darwin')) return 'macOS';
    if (lower.contains('ios')) return 'iOS';
    if (lower.contains('curl')) return 'Shell';
    if (lower.contains('emotion_tracker')) return 'Emotion Tracker';
    return 'Unknown';
  }

  Widget _buildPlatformIcon(String userAgent, Color color) {
    final ua = userAgent.toLowerCase();
    if (ua.contains('curl')) {
      return const Icon(Icons.terminal, color: Colors.white);
    } else if (ua.contains('android')) {
      return const Icon(Icons.android, color: Colors.white);
    } else if (ua.contains('linux')) {
      // No penguin in Material, fallback to code icon
      return const Icon(Icons.code, color: Colors.white);
    } else {
      return const Icon(Icons.login, color: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLogins = ref.watch(loginHistoryProvider);
    final theme = ref.watch(currentThemeProvider);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Login(s)'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 1,
      ),
      backgroundColor: colorScheme.background,
      body: asyncLogins.when(
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        error: (err, _) =>
            Center(child: Text('⚠️  Something went wrong\n$err', style: textTheme.bodyLarge?.copyWith(color: colorScheme.error))),
        data: (logins) {
          final items = logins.where((e) => e['outcome'] == 'success').toList();
          if (items.isEmpty) {
            return Center(child: Text('No recent logins found.', style: textTheme.bodyLarge));
          }

          // Show only the 10 most recent successful logins
          final recentItems = items.take(10).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_clock, color: colorScheme.primary, size: 26),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        '10 most recent logins for your Second Brain Database account',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: recentItems.length,
                  itemBuilder: (ctx, i) {
                    final l = recentItems[i];
                    final color = _statusColor(l['outcome']);
                    final formattedDate = _formatTimestamp(l['timestamp'] ?? '');
                    final device = _shortUserAgent(l['user_agent'] ?? '');
                    final ip = l['ip_address'] ?? '';
                    final mfa = (l['mfa_status'] ?? false) as bool;

                    return Card(
                      elevation: 2,
                      color: colorScheme.surface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color,
                          child: _buildPlatformIcon(l['user_agent'] ?? '', color),
                        ),
                        title: Text(
                          formattedDate,
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: -8,
                            children: [
                              Chip(
                                label: Text(device, style: textTheme.labelMedium),
                                avatar: const Icon(Icons.devices_other, size: 16),
                                backgroundColor: colorScheme.primary.withOpacity(0.08),
                                shape: StadiumBorder(),
                              ),
                              Chip(
                                label: Text(_platformFromUserAgent(l['user_agent'] ?? ''), style: textTheme.labelMedium),
                                avatar: const Icon(Icons.computer, size: 16),
                                backgroundColor: colorScheme.secondary.withOpacity(0.08),
                                shape: StadiumBorder(),
                              ),
                              Chip(
                                label: Text(ip, style: textTheme.labelMedium),
                                avatar: const Icon(Icons.public, size: 16),
                                backgroundColor: colorScheme.tertiaryContainer.withOpacity(0.08),
                                shape: StadiumBorder(),
                              ),
                              if (mfa)
                                Chip(
                                  label: const Text('MFA'),
                                  avatar: const Icon(Icons.security, size: 16),
                                  backgroundColor: colorScheme.error.withOpacity(0.08),
                                  shape: StadiumBorder(),
                                ),
                            ],
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l['outcome'],
                            style: textTheme.labelLarge?.copyWith(
                              color: color, fontWeight: FontWeight.bold),
                          ),
                        ),
                        onTap: () {
                          // Optional: show a bottom sheet with full details
                          showModalBottomSheet(
                            context: context,
                            builder: (_) => _LoginDetailsSheet(login: l),
                            backgroundColor: colorScheme.surface,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoginDetailsSheet extends StatelessWidget {
  const _LoginDetailsSheet({required this.login});
  final Map<String, dynamic> login;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Login details',
              style:
                  Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
          const SizedBox(height: 12),
          ...login.entries
              .where((e) => e.value != null && e.value.toString().trim().isNotEmpty)
              .map((e) => Row(
                    children: [
                      Text('${e.key}: ',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Expanded(child: Text(e.value?.toString() ?? '')),
                    ],
                  )),
          const SizedBox(height: 12),
        ]),
      );
}
