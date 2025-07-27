import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/ad_provider.dart';
import 'package:emotion_tracker/providers/avatar_unlock_provider.dart';
import 'package:emotion_tracker/providers/custom_avatar.dart';

class AvatarDetailDialog extends ConsumerStatefulWidget {
  final Avatar avatar;
  final String adId;
  final VoidCallback? onAvatarBought;

  const AvatarDetailDialog({
    Key? key,
    required this.avatar,
    required this.adId,
    this.onAvatarBought,
  }) : super(key: key);

  @override
  _AvatarDetailDialogState createState() => _AvatarDetailDialogState();
}

class _AvatarDetailDialogState extends ConsumerState<AvatarDetailDialog> {
  late Future<AvatarUnlockInfo> _unlockInfoFuture;
  bool _hasRefreshed = false;

  @override
  void initState() {
    super.initState();
    _unlockInfoFuture = ref
        .read(avatarUnlockProvider)
        .getAvatarUnlockInfo(widget.avatar.id);
  }

  void _refreshUnlockInfo() {
    if (!_hasRefreshed) {
      setState(() {
        _unlockInfoFuture = ref
            .read(avatarUnlockProvider)
            .getAvatarUnlockInfo(widget.avatar.id);
        _hasRefreshed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final bannerAd = (defaultTargetPlatform != TargetPlatform.linux)
        ? ref.watch(bannerAdProvider(widget.adId))
        : null;
    final isBannerAdReady = (defaultTargetPlatform != TargetPlatform.linux)
        ? ref.watch(adProvider.notifier).isBannerAdReady(widget.adId)
        : false;
    final avatarUnlockService = ref.watch(avatarUnlockProvider);

    const double avatarSize = 120;
    const double dialogCornerRadius = 20;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: avatarSize / 2),
            padding: const EdgeInsets.only(
              top: avatarSize / 2 + 16,
              left: 24,
              right: 24,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(dialogCornerRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.avatar.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FutureBuilder<AvatarUnlockInfo>(
                  future: _unlockInfoFuture,
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final isUnlocked = info?.isUnlocked ?? false;
                    final unlockTime = info?.unlockTime;
                    final now = DateTime.now().toUtc();
                    Duration? timeLeft;
                    Duration? timeSinceUnlock;
                    if (isUnlocked && unlockTime != null) {
                      final expiry = unlockTime.add(const Duration(hours: 1));
                      timeLeft = expiry.difference(now);
                      if (timeLeft.isNegative) timeLeft = Duration.zero;
                      timeSinceUnlock = now.difference(unlockTime);
                      if (timeSinceUnlock.isNegative)
                        timeSinceUnlock = Duration.zero;
                    }
                    final canShowRentButton =
                        !isUnlocked ||
                        (timeSinceUnlock != null &&
                            timeSinceUnlock.inMinutes >= 55);
                    if (isUnlocked && timeLeft != null && !canShowRentButton) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Card(
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
                                Icon(
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
                                  '${timeLeft.inMinutes > 0 ? '${timeLeft.inMinutes} min' : '${timeLeft.inSeconds} sec'}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 8),
                FutureBuilder<AvatarUnlockInfo>(
                  future: _unlockInfoFuture,
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final isUnlocked = info?.isUnlocked ?? false;
                    final unlockTime = info?.unlockTime;
                    final now = DateTime.now().toUtc();
                    Duration? timeLeft;
                    Duration? timeSinceUnlock;
                    if (isUnlocked && unlockTime != null) {
                      final expiry = unlockTime.add(const Duration(hours: 1));
                      timeLeft = expiry.difference(now);
                      if (timeLeft.isNegative) timeLeft = Duration.zero;
                      timeSinceUnlock = now.difference(unlockTime);
                      if (timeSinceUnlock.isNegative)
                        timeSinceUnlock = Duration.zero;
                    }
                    final canShowRentButton =
                        !isUnlocked ||
                        (timeSinceUnlock != null &&
                            timeSinceUnlock.inMinutes >= 55);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!(info?.isUnlocked ?? false))
                          Row(
                            children: [
                              if (canShowRentButton &&
                                  widget.avatar.rewardedAdId != null &&
                                  widget.avatar.rewardedAdId!.isNotEmpty)
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await avatarUnlockService
                                          .showAvatarUnlockAd(
                                            context,
                                            widget.avatar.id,
                                            onAvatarUnlocked: () {
                                              _refreshUnlockInfo();
                                            },
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
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text('Rent (Ad)'),
                                  ),
                                ),
                              if (canShowRentButton &&
                                  widget.avatar.rewardedAdId != null &&
                                  widget.avatar.rewardedAdId!.isNotEmpty)
                                const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(avatarUnlockProvider)
                                          .buyAvatar(context, widget.avatar.id);
                                      _refreshUnlockInfo();
                                      if (widget.onAvatarBought != null) {
                                        widget.onAvatarBought!();
                                      }
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
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    'Buy (${widget.avatar.price} SBD)',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        // Show Buy button if rented (unlocked and timeLeft > 0), instead of Rented
                        if (isUnlocked &&
                            timeLeft != null &&
                            timeLeft > Duration.zero)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(avatarUnlockProvider)
                                      .buyAvatar(context, widget.avatar.id);
                                  _refreshUnlockInfo();
                                  if (widget.onAvatarBought != null) {
                                    widget.onAvatarBought!();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Text('Buy (${widget.avatar.price} SBD)'),
                            ),
                          ),
                        if (isUnlocked &&
                            (timeLeft == null || timeLeft <= Duration.zero))
                          Padding(
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        if (canShowRentButton &&
                            widget.avatar.rewardedAdId != null &&
                            widget.avatar.rewardedAdId!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 16.0,
                              left: 4.0,
                              right: 4.0,
                            ),
                            child: Text(
                              'Watch an ad to rent this avatar for 1 hour.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (!canShowRentButton && bannerAd != null) ...[
                          if (!isBannerAdReady) ...[
                            FutureBuilder<void>(
                              future: Future(() async {
                                if (bannerAd.responseInfo == null)
                                  await bannerAd.load();
                              }),
                              builder: (context, snapshot) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 28.0),
                                  child: SizedBox(
                                    width: bannerAd.size.width.toDouble(),
                                    height: bannerAd.size.height.toDouble(),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ] else ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 28.0),
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: bannerAd.size.width.toDouble(),
                                  height: bannerAd.size.height.toDouble(),
                                  child: AdWidget(ad: bannerAd),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: AvatarDisplay(avatar: widget.avatar, size: avatarSize),
            ),
          ),
          Positioned(
            top: (avatarSize / 2) + 5,
            right: 5,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
