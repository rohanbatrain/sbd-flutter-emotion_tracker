import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/providers/shared_prefs_provider.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:emotion_tracker/core/error_state.dart';
import 'package:emotion_tracker/core/global_error_handler.dart';
import 'package:emotion_tracker/core/session_manager.dart';
import 'package:emotion_tracker/providers/api_token_service.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';

final loginHistoryMigratedProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    try {
      final storage = ref.read(secureStorageProvider);
      final token = await storage.read(key: 'access_token');
      if (token == null) {
        throw UnauthorizedException('Authentication token not found');
      }

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
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Session expired. Please log in again.');
      } else if (response.statusCode == 429) {
        throw RateLimitException('Too many requests. Please wait before trying again.');
      } else if (response.statusCode >= 500) {
        throw ApiException('Server error occurred. Please try again later.', response.statusCode);
      } else {
        throw ApiException('Failed to load login history: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  },
);

const _tzAbbreviationMap = {
  'IST': 'Asia/Kolkata',
  'UTC': 'UTC',
  'GMT': 'Europe/London',
  'PST': 'America/Los_Angeles',
  'EST': 'America/New_York',
  'CST': 'America/Chicago',
  'MST': 'America/Denver',
  'JST': 'Asia/Tokyo',
  'CET': 'Europe/Paris',
  'EET': 'Europe/Bucharest',
  // Add more as needed
};

String _mapAbbreviationToIana(String abbr) {
  return _tzAbbreviationMap[abbr.toUpperCase()] ?? abbr;
}

class LoginHistoryScreen extends ConsumerStatefulWidget {
  const LoginHistoryScreen({super.key});

  @override
  ConsumerState<LoginHistoryScreen> createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends ConsumerState<LoginHistoryScreen> with RouteAware {
  RouteObserver<PageRoute>? _routeObserver;
  PageRoute? _pageRoute;
  BannerAd? _preloadedBannerAd;
  bool _bannerLoaded = false;

  @override
  void initState() {
    super.initState();
    // Always refresh on first load
    Future.microtask(() => ref.invalidate(loginHistoryMigratedProvider));
    // Preload the banner ad
    _preloadedBannerAd = BannerAd(
      adUnitId: 'ca-app-pub-2845453539708646/7319663722',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _bannerLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    _routeObserver = ModalRoute.of(context)?.navigator?.widget.observers
        .whereType<RouteObserver<PageRoute>>()
        .firstOrNull;
    _pageRoute = ModalRoute.of(context) as PageRoute?;
    _routeObserver?.subscribe(this, _pageRoute!);
  }

  @override
  void dispose() {
    // Unsubscribe from route observer
    _routeObserver?.unsubscribe(this);
    _preloadedBannerAd?.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when coming back to this screen
    ref.invalidate(loginHistoryMigratedProvider);
    super.didPopNext();
  }

  Color _statusColor(String outcome) =>
      outcome == 'success' ? Colors.green : Colors.red;

  String _formatTimestamp(String ts, String userTz) {
    try {
      // Ensure the timestamp is parsed as UTC if no offset is present
      String safeTs = ts;
      if (!ts.endsWith('Z') && !RegExp(r'[+-]\d{2}:?\d{2}').hasMatch(ts)) {
        safeTs = ts + 'Z';
      }
      final utc = DateTime.parse(safeTs).toUtc();
      String tzName = _mapAbbreviationToIana(userTz);
      if (tzName.isNotEmpty) {
        final location = tz.getLocation(tzName);
        final local = tz.TZDateTime.from(utc, location);
        return DateFormat('dd MMM yyyy • hh:mm a').format(local);
      } else {
        final local = utc.toLocal();
        return DateFormat('dd MMM yyyy • hh:mm a').format(local);
      }
    } catch (_) {
      return ts;
    }
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

  /// Handles retry action for failed requests
  void _handleRetry() {
    ref.invalidate(loginHistoryMigratedProvider);
    GlobalErrorHandler.showErrorSnackbar(
      context,
      'Retrying request...',
      ErrorType.generic,
    );
  }

  /// Shows error-specific help information
  void _showErrorInfo(dynamic error) {
    final errorState = GlobalErrorHandler.processError(error);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(errorState.icon, color: errorState.color),
            const SizedBox(width: 8),
            Text('Help Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Error Type: ${errorState.type.toString().split('.').last}'),
            const SizedBox(height: 8),
            Text(errorState.message),
            const SizedBox(height: 16),
            const Text('Troubleshooting steps:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_getTroubleshootingSteps(errorState.type)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getTroubleshootingSteps(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.unauthorized:
        return '• Check if you are still logged in\n• Try logging out and back in\n• Contact support if issue persists';
      case ErrorType.networkError:
        return '• Check your internet connection\n• Try switching networks\n• Wait and try again';
      case ErrorType.serverError:
        return '• Server may be temporarily down\n• Try again in a few minutes\n• Check server status';
      case ErrorType.rateLimited:
        return '• You are making requests too quickly\n• Wait a few minutes\n• Try again later';
      default:
        return '• Try refreshing the page\n• Check your connection\n• Contact support if needed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncLogins = ref.watch(loginHistoryMigratedProvider);
    final userTz = ref.watch(timezoneProvider);
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
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(loginHistoryMigratedProvider),
        child: asyncLogins.when(
          loading: () => const LoadingStateWidget(message: 'Loading recent logins...'),
          error: (error, stackTrace) {
            // Handle 401 Unauthorized: redirect to /auth/v1
            final errorState = GlobalErrorHandler.processError(error);
            if (errorState.type == ErrorType.unauthorized) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await SessionManager.handleSessionExpiry(context, ref);
                Navigator.of(context).pushReplacementNamed('/auth/v1');
              });
              return const SizedBox.shrink();
            }
            return ErrorStateWidget(
              error: error,
              onRetry: _handleRetry,
              onInfo: () => _showErrorInfo(error),
              customMessage: 'Unable to load login history. Please try again.',
            );
          },
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
                  child: SafeArea(
                    top: false,
                    left: false,
                    right: false,
                    bottom: true,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: recentItems.length,
                      itemBuilder: (ctx, i) {
                        final l = recentItems[i];
                        final color = _statusColor(l['outcome']);
                        final formattedDate = _formatTimestamp(l['timestamp'] ?? '', userTz);
                        final device = _shortUserAgent(l['user_agent'] ?? '');
                        final ip = l['ip_address'] ?? '';
                        final mfa = (l['mfa_status'] ?? false) as bool;

                        return Card(
                          elevation: 2,
                          color: colorScheme.surface,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: Tooltip(
                              message: _platformFromUserAgent(l['user_agent'] ?? ''),
                              child: CircleAvatar(
                                backgroundColor: color,
                                child: _buildPlatformIcon(l['user_agent'] ?? '', color),
                              ),
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
                                  Tooltip(
                                    message: l['user_agent'] ?? '',
                                    child: Chip(
                                      label: Text(device, style: textTheme.labelMedium),
                                      avatar: const Icon(Icons.devices_other, size: 16),
                                      backgroundColor: colorScheme.primary.withOpacity(0.08),
                                      shape: StadiumBorder(),
                                    ),
                                  ),
                                  Chip(
                                    label: Text(_platformFromUserAgent(l['user_agent'] ?? ''), style: textTheme.labelMedium),
                                    avatar: const Icon(Icons.computer, size: 16),
                                    backgroundColor: colorScheme.secondary.withOpacity(0.08),
                                    shape: StadiumBorder(),
                                  ),
                                  Tooltip(
                                    message: 'Copy IP',
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () async {
                                        await Clipboard.setData(ClipboardData(text: ip));
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('IP address copied!'),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      child: Chip(
                                        label: Text(ip, style: textTheme.labelMedium),
                                        avatar: const Icon(Icons.public, size: 16),
                                        backgroundColor: colorScheme.tertiaryContainer.withOpacity(0.08),
                                        shape: StadiumBorder(),
                                      ),
                                    ),
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
                              showModalBottomSheet(
                                context: context,
                                builder: (_) => _LoginDetailsSheet(
                                  login: l,
                                  bannerAd: _bannerLoaded ? _preloadedBannerAd : null,
                                ),
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoginDetailsSheet extends StatelessWidget {
  const _LoginDetailsSheet({required this.login, this.bannerAd});
  final Map<String, dynamic> login;
  final BannerAd? bannerAd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Login details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
              ],
            ),
          ),
          // Banner Ad
          if (bannerAd != null)
            SizedBox(
              height: bannerAd!.size.height.toDouble(),
              child: Center(
                child: SizedBox(
                  width: bannerAd!.size.width.toDouble(),
                  height: bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: bannerAd!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
