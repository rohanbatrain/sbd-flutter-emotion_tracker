import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/banner_unlock_provider.dart';
import 'package:emotion_tracker/providers/custom_banner.dart';
import 'package:emotion_tracker/providers/ad_provider.dart';

class BannerDetailDialog extends ConsumerStatefulWidget {
  final ProfileBanner banner;
  final String adId;

  const BannerDetailDialog({Key? key, required this.banner, required this.adId})
    : super(key: key);

  @override
  _BannerDetailDialogState createState() => _BannerDetailDialogState();
}

class _BannerDetailDialogState extends ConsumerState<BannerDetailDialog> {
  late Future<BannerUnlockInfo> _unlockInfoFuture;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _refreshUnlockInfo();
    _loadBannerAd();
  }

  void _refreshUnlockInfo() {
    // Invalidate the in-memory cache before fetching new unlock info
    ref.read(bannerUnlockProvider).invalidateBannerCache(widget.banner.id);
    setState(() {
      _unlockInfoFuture = ref
          .read(bannerUnlockProvider)
          .getBannerUnlockInfo(widget.banner.id);
    });
  }

  void _loadBannerAd() {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux) {
      return;
    }
    _bannerAd = BannerAd(
      adUnitId: AdUnitIds.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      backgroundColor: theme.cardColor,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: ProfileBannerDisplay(
                    banner: widget.banner,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black.withOpacity(0.5),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      splashRadius: 20,
                      tooltip: 'Close',
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.banner.name ?? 'Banner',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.banner.description != null &&
                      widget.banner.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.banner.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  FutureBuilder<BannerUnlockInfo>(
                    future: _unlockInfoFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final info = snapshot.data;
                      final isUnlocked = info?.isUnlocked ?? false;
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
                      if (isOwned) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(
                              Icons.verified,
                              color: Colors.white,
                            ),
                            label: const Text('Owned'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary
                                  .withOpacity(0.9),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        );
                      }
                      if (isRented) {
                        return Column(
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
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Time left: ${timeLeft!.inMinutes > 0 ? '${timeLeft.inMinutes} min' : '${timeLeft.inSeconds} sec'}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: theme.hintColor),
                                        overflow: TextOverflow.ellipsis,
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
                                child: ElevatedButton.icon(
                                  icon: const Icon(
                                    Icons.shopping_cart_outlined,
                                  ),
                                  label: Text(
                                    'Buy (${widget.banner.price} SBD)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(bannerUnlockProvider)
                                          .buyBanner(context, widget.banner.id);
                                      _refreshUnlockInfo();
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString()),
                                            backgroundColor:
                                                theme.colorScheme.error,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor:
                                        theme.colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (widget.banner.rewardedAdId != null &&
                                  widget.banner.rewardedAdId!.isNotEmpty)
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await ref
                                          .read(bannerUnlockProvider)
                                          .showBannerUnlockAd(
                                            context,
                                            widget.banner.id,
                                            onBannerUnlocked:
                                                _refreshUnlockInfo,
                                          );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme
                                          .colorScheme
                                          .secondary
                                          .withOpacity(0.1),
                                      foregroundColor:
                                          theme.colorScheme.secondary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text('Rent (Ad)'),
                                  ),
                                ),
                              if (widget.banner.rewardedAdId != null &&
                                  widget.banner.rewardedAdId!.isNotEmpty)
                                const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(bannerUnlockProvider)
                                          .buyBanner(context, widget.banner.id);
                                      _refreshUnlockInfo();
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString()),
                                            backgroundColor:
                                                theme.colorScheme.error,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  label: Text(
                                    'Buy (${widget.banner.price} SBD)',
                                  ),
                                  // icon: const Icon(Icons.shopping_cart_outlined),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor:
                                        theme.colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (widget.banner.rewardedAdId != null &&
                              widget.banner.rewardedAdId!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 12.0,
                                left: 4.0,
                                right: 4.0,
                              ),
                              child: Text(
                                'Watch an ad to rent this banner for 1 hour.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
