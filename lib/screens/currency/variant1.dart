import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/currency_provider.dart';
import 'package:emotion_tracker/providers/ad_provider.dart';
import 'dart:async';

class CurrencyScreenV1 extends ConsumerStatefulWidget {
  const CurrencyScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<CurrencyScreenV1> createState() => _CurrencyScreenV1State();
}

class _CurrencyScreenV1State extends ConsumerState<CurrencyScreenV1>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _coinBounceController;
  late Animation<double> _coinBounceAnimation;
  bool _showRewardSuccess = false;
  AdNotifier? _adNotifier;
  Timer? _cooldownTimer;
  Duration _cooldownRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _coinBounceController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _coinBounceAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _coinBounceController,
      curve: Curves.elasticOut,
    ));

    // Initialize ad provider and load rewarded ad
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adNotifier = ref.read(adProvider.notifier);
      _adNotifier?.loadRewardedAd();
      _startCooldownTimerIfNeeded();
    });
  }

  void _startCooldownTimerIfNeeded() {
    final currencyData = ref.read(currencyProvider);
    final now = DateTime.now();
    final lastAdWatched = currencyData.lastAdWatched;
    final cooldown = lastAdWatched != null ? now.difference(lastAdWatched) : Duration(seconds: 15);
    if (cooldown.inSeconds < 15) {
      _cooldownRemaining = Duration(seconds: 15) - cooldown;
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _cooldownRemaining = _cooldownRemaining - Duration(seconds: 1);
          if (_cooldownRemaining.isNegative || _cooldownRemaining == Duration.zero) {
            _cooldownTimer?.cancel();
            _cooldownRemaining = Duration.zero;
          }
        });
      });
    } else {
      _cooldownRemaining = Duration.zero;
      _cooldownTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _coinBounceController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _watchAd() async {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    
    if (!currencyNotifier.canEarnMore) {
      _showDailyLimitDialog();
      return;
    }

    // Check if rewarded ad is ready
    if (_adNotifier?.isRewardedAdReady != true) {
      _showAdNotReadyDialog();
      return;
    }

    // Show rewarded ad
    await _adNotifier?.showRewardedAd(
      onUserEarnedReward: (reward) {
        // User earned reward, add coins
        _handleAdReward();
      },
      onAdClosed: () {
        // Ad was closed, preload next ad
        _adNotifier?.loadRewardedAd();
      },
    );
  }

  void _handleAdReward() async {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    setState(() {
      _showRewardSuccess = true;
    });
    await currencyNotifier.addCoins(50);
    currencyNotifier.updateLastAdWatched();
    _startCooldownTimerIfNeeded();
    _confettiController.forward();
    _coinBounceController.forward();
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showRewardSuccess = false;
        });
        _confettiController.reset();
        _coinBounceController.reset();
      }
    });
  }

  void _showAdNotReadyDialog() {
    final theme = ref.read(currentThemeProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('Ad Not Ready', style: theme.textTheme.titleLarge),
        content: Text(
          'The ad is still loading. Please try again in a moment.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Try to load the ad again
              _adNotifier?.loadRewardedAd();
            },
            child: Text('OK', style: TextStyle(color: theme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showDailyLimitDialog() {
    final theme = ref.read(currentThemeProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('Daily Limit Reached', style: theme.textTheme.titleLarge),
        content: Text(
          'You\'ve reached your daily earning limit. Come back tomorrow for more SBD tokens!',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: theme.primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final currencyData = ref.watch(currencyProvider);
    final adState = ref.watch(adProvider); // <-- watch ad state reactively
    final isRewardedAdReady = ref.watch(rewardedAdReadyProvider);
    final now = DateTime.now();
    final lastAdWatched = currencyData.lastAdWatched;
    final cooldown = lastAdWatched != null ? now.difference(lastAdWatched) : Duration(seconds: 15);
    final isCooldownActive = cooldown.inSeconds < 15 || _cooldownRemaining > Duration.zero;
    final displayCooldown = _cooldownRemaining > Duration.zero ? _cooldownRemaining : (Duration(seconds: 15) - cooldown);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              // Custom App Bar
              SafeArea(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: theme.primaryColor),
                      ),
                      Expanded(
                        child: Text(
                          'Earn SBD Tokens',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 48),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Earn More SBD Tokens',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),

                      // Current Balance Card
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.psychology,
                                color: theme.primaryColor,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Balance',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    currencyData.formattedBalanceWithSymbol,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      // Watch Ad Button
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isCooldownActive || !isRewardedAdReady ? null : _watchAd,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isCooldownActive
                              ? Text(
                                  'Wait ${displayCooldown.inMinutes}:${(displayCooldown.inSeconds % 60).toString().padLeft(2, '0')} to watch again',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : !isRewardedAdReady
                                  ? Text(
                                      'Loading Ad...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : Text(
                                      'Watch Ad to Earn +50 SBD',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Daily Progress
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Earnings',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: currencyData.todayEarned / currencyData.dailyLimit,
                              backgroundColor: theme.primaryColor.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'You\'ve earned ${currencyData.todayEarned} / ${currencyData.dailyLimit} SBD tokens today',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),

                      // Stats Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              theme,
                              'Lifetime Earned',
                              currencyData.formattedLifetimeWithSymbol,
                              Icons.trending_up,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              theme,
                              'Avg. Daily Earnings',
                              '${currencyData.averageDailyEarnings.toStringAsFixed(1)} SBD',
                              Icons.show_chart,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Why ads info
                      Center(
                        child: TextButton(
                          onPressed: () => _showWhyAdsDialog(theme),
                          child: Text(
                            'Why ads?',
                            style: TextStyle(
                              color: theme.primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      
                      // Debug/Testing Reset Counter (only in debug mode)
                      /*
                      if (kDebugMode) ...[
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.bug_report,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Debug Mode - Testing Tools',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _resetDailyCounter,
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.orange),
                                      ),
                                      child: Text(
                                        'Reset Daily Counter',
                                        style: TextStyle(color: Colors.orange),
                                      ),
                                    ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _reloadAds,
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.orange),
                                      ),
                                      child: Text(
                                        'Reload Ads',
                                        style: TextStyle(color: Colors.orange),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      */
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Reward Success Overlay
          if (_showRewardSuccess) _buildRewardOverlay(theme, currencyData),
        ],
      ),
    );
  }

  Widget _buildRewardOverlay(ThemeData theme, CurrencyData currencyData) {
    final now = DateTime.now();
    final lastAdWatched = currencyData.lastAdWatched;
    final cooldown = lastAdWatched != null ? now.difference(lastAdWatched) : Duration(seconds: 15);
    final isCooldownActive = cooldown.inSeconds < 15 || _cooldownRemaining > Duration.zero;
    final displayCooldown = _cooldownRemaining > Duration.zero ? _cooldownRemaining : (Duration(seconds: 15) - cooldown);
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(32),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated brain icon
              AnimatedBuilder(
                animation: _coinBounceAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _coinBounceAnimation.value,
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.psychology,
                        color: theme.primaryColor,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),

              Text(
                'You\'ve Earned +50 SBD!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),

              Text(
                'via AdMob',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isCooldownActive ? null : _watchAd,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.primaryColor),
                      ),
                      child: isCooldownActive
                          ? Text(
                              'Wait ${displayCooldown.inMinutes}:${(displayCooldown.inSeconds % 60).toString().padLeft(2, '0')} to watch again',
                              style: TextStyle(color: theme.primaryColor),
                            )
                          : Text(
                              'Watch Another',
                              style: TextStyle(color: theme.primaryColor),
                            ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showRewardSuccess = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      child: Text('Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.primaryColor, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showWhyAdsDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('Why Ads?', style: theme.textTheme.titleLarge),
        content: Text(
          'Ads help us keep the app free and support ongoing development. Your engagement helps us continue improving your experience!',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Got it!', style: TextStyle(color: theme.primaryColor)),
          ),
        ],
      ),
    );
  }

  // Debug helper methods (only available in debug mode)
  void _resetDailyCounter() async {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    await currencyNotifier.resetDailyEarnings();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Daily counter reset! You can now earn ads again.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _reloadAds() {
    _adNotifier?.loadRewardedAd();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ads reloaded! Rewarded ad should be ready soon.'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}