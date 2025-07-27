import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/theme_unlock_provider.dart';

class ThemeDetailDialog extends ConsumerStatefulWidget {
  final String themeKey;
  final ThemeData theme;
  final int price;
  final bool isOwned;
  final String? adUnitId;
  final VoidCallback? onThemeUnlocked;
  final VoidCallback? onThemeBought;

  const ThemeDetailDialog({
    Key? key,
    required this.themeKey,
    required this.theme,
    required this.price,
    required this.isOwned,
    this.adUnitId,
    this.onThemeUnlocked,
    this.onThemeBought,
  }) : super(key: key);

  @override
  _ThemeDetailDialogState createState() => _ThemeDetailDialogState();
}

class _ThemeDetailDialogState extends ConsumerState<ThemeDetailDialog> {
  late Future<ThemeUnlockInfo> _unlockInfoFuture;

  @override
  void initState() {
    super.initState();
    _refreshUnlockInfo();
  }

  void _refreshUnlockInfo() {
    setState(() {
      _unlockInfoFuture = ref
          .read(themeUnlockProvider)
          .getThemeUnlockInfo(widget.themeKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final isFree = widget.price == 0;
    final Gradient themeGradient = _getThemeGradient(
      widget.themeKey,
      widget.theme,
    );
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      backgroundColor: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: FutureBuilder<ThemeUnlockInfo>(
          future: _unlockInfoFuture,
          builder: (context, snapshot) {
            final info = snapshot.data;
            final isUnlocked = info?.isUnlocked ?? widget.isOwned;
            final unlockTime = info?.unlockTime;
            final now = DateTime.now().toUtc();
            Duration? timeLeft;
            bool isOwned = false;
            bool isRented = false;
            if (isUnlocked && unlockTime != null) {
              final expiry = unlockTime.add(const Duration(hours: 1));
              timeLeft = expiry.difference(now);
              if (timeLeft.isNegative) timeLeft = Duration.zero;
              isRented = timeLeft > Duration.zero;
            }
            isOwned = isUnlocked && (!isRented);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppThemes.themeNames[widget.themeKey] ?? 'Theme',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: themeGradient,
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (isOwned || isFree)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Owned',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (isRented)
                  Column(
                    children: [
                      Card(
                        color: Colors.green.withOpacity(0.12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.verified,
                                color: Colors.green,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Rented',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Time left: '
                                '${timeLeft!.inMinutes > 0 ? '${timeLeft.inMinutes} min' : '${timeLeft.inSeconds} sec'}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 4.0,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final themeUnlockService = ref.read(
                                themeUnlockProvider,
                              );
                              try {
                                await themeUnlockService.buyTheme(
                                  context,
                                  widget.themeKey,
                                );
                                _refreshUnlockInfo();
                                if (widget.onThemeBought != null)
                                  widget.onThemeBought!();
                                Navigator.of(context).pop();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: theme.colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              'Buy (${widget.price} SBD)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (widget.adUnitId != null &&
                          widget.adUnitId!.isNotEmpty)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final themeUnlockService = ref.read(
                                themeUnlockProvider,
                              );
                              try {
                                await themeUnlockService.showThemeUnlockAd(
                                  context,
                                  widget.themeKey,
                                  onThemeUnlocked: () {
                                    _refreshUnlockInfo();
                                    if (widget.onThemeUnlocked != null)
                                      widget.onThemeUnlocked!();
                                  },
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: theme.colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.secondary
                                  .withOpacity(0.1),
                              foregroundColor: theme.colorScheme.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text('Rent'),
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final themeUnlockService = ref.read(
                              themeUnlockProvider,
                            );
                            try {
                              await themeUnlockService.buyTheme(
                                context,
                                widget.themeKey,
                              );
                              _refreshUnlockInfo();
                              if (widget.onThemeBought != null)
                                widget.onThemeBought!();
                              Navigator.of(context).pop();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: theme.colorScheme.error,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Text('Buy (${widget.price} SBD)'),
                        ),
                      ),
                    ],
                  ),
                  if (widget.adUnitId != null &&
                      widget.adUnitId!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Watch an ad to rent this theme for 1 hour',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Gradient _getThemeGradient(String themeKey, ThemeData fallbackTheme) {
    const gradients = {
      'serenityGreen': LinearGradient(
        colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'pacificBlue': LinearGradient(
        colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'blushRose': LinearGradient(
        colors: [Color(0xFFFFAFBD), Color(0xFFFFC3A0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'cloudGray': LinearGradient(
        colors: [Color(0xFFbdc3c7), Color(0xFF2c3e50)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'sunsetPeach': LinearGradient(
        colors: [Color(0xFFFF9966), Color(0xFFFF5E62)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'midnightLavender': LinearGradient(
        colors: [Color(0xFF232526), Color(0xFF414345)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'crimsonRed': LinearGradient(
        colors: [Color(0xFFcb2d3e), Color(0xFFef473a)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'forestGreen': LinearGradient(
        colors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'goldenYellow': LinearGradient(
        colors: [Color(0xFFf7971e), Color(0xFFffd200)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'deepPurple': LinearGradient(
        colors: [Color(0xFF8e2de2), Color(0xFF4a00e0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'royalOrange': LinearGradient(
        colors: [Color(0xFFf857a6), Color(0xFFFF5858)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    };
    final key = themeKey.replaceAll('Dark', '').replaceAll('Light', '');
    if (gradients.containsKey(themeKey)) return gradients[themeKey]!;
    if (gradients.containsKey(key)) return gradients[key]!;
    return LinearGradient(
      colors: [fallbackTheme.primaryColor, fallbackTheme.colorScheme.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
