import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Ad Unit IDs (Test IDs for development)
class AdUnitIds {
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String adaptiveBannerAdUnitId = 'ca-app-pub-3940256099942544/9214589741';
  static const String appOpenAdUnitId = 'ca-app-pub-3940256099942544/9257395921';
  static const String nativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';
}

// Ad loading states
enum AdLoadingState {
  notLoaded,
  loading,
  loaded,
  failed,
}

// Ad state model
class AdState {
  final Map<String, BannerAd?> bannerAds;
  final Map<String, AdLoadingState> bannerAdStates;
  final InterstitialAd? interstitialAd;
  final AdLoadingState interstitialAdState;
  final RewardedAd? rewardedAd;
  final AdLoadingState rewardedAdState;
  final bool isAdMobInitialized;

  const AdState({
    this.bannerAds = const {},
    this.bannerAdStates = const {},
    this.interstitialAd,
    this.interstitialAdState = AdLoadingState.notLoaded,
    this.rewardedAd,
    this.rewardedAdState = AdLoadingState.notLoaded,
    this.isAdMobInitialized = false,
  });

  AdState copyWith({
    Map<String, BannerAd?>? bannerAds,
    Map<String, AdLoadingState>? bannerAdStates,
    InterstitialAd? interstitialAd,
    AdLoadingState? interstitialAdState,
    RewardedAd? rewardedAd,
    AdLoadingState? rewardedAdState,
    bool? isAdMobInitialized,
  }) {
    return AdState(
      bannerAds: bannerAds ?? this.bannerAds,
      bannerAdStates: bannerAdStates ?? this.bannerAdStates,
      interstitialAd: interstitialAd ?? this.interstitialAd,
      interstitialAdState: interstitialAdState ?? this.interstitialAdState,
      rewardedAd: rewardedAd ?? this.rewardedAd,
      rewardedAdState: rewardedAdState ?? this.rewardedAdState,
      isAdMobInitialized: isAdMobInitialized ?? this.isAdMobInitialized,
    );
  }
}

// Ad Provider
class AdNotifier extends StateNotifier<AdState> {
  AdNotifier() : super(const AdState()) {
    _initializeAdMob();
  }

  Future<void> _initializeAdMob() async {
    try {
      await MobileAds.instance.initialize();
      state = state.copyWith(isAdMobInitialized: true);
      debugPrint('AdMob initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AdMob: $e');
    }
  }

  // Helper to ensure AdMob is initialized before any ad operation
  Future<void> _ensureAdMobInitialized() async {
    if (!state.isAdMobInitialized) {
      await _initializeAdMob();
    }
  }

  // Load banner ad with specific ID
  Future<void> loadBannerAd(String adId, {AdSize size = AdSize.banner}) async {
    await _ensureAdMobInitialized();

    // Dispose existing ad if any
    state.bannerAds[adId]?.dispose();

    // Update state to loading
    final newBannerAdStates = Map<String, AdLoadingState>.from(state.bannerAdStates);
    newBannerAdStates[adId] = AdLoadingState.loading;
    state = state.copyWith(bannerAdStates: newBannerAdStates);

    final bannerAd = BannerAd(
      adUnitId: AdUnitIds.bannerAdUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          final newBannerAds = Map<String, BannerAd?>.from(state.bannerAds);
          final newBannerAdStates = Map<String, AdLoadingState>.from(state.bannerAdStates);
          
          newBannerAds[adId] = ad as BannerAd;
          newBannerAdStates[adId] = AdLoadingState.loaded;
          
          state = state.copyWith(
            bannerAds: newBannerAds,
            bannerAdStates: newBannerAdStates,
          );
          debugPrint('Banner ad loaded successfully for ID: $adId');
        },
        onAdFailedToLoad: (ad, error) {
          final newBannerAdStates = Map<String, AdLoadingState>.from(state.bannerAdStates);
          newBannerAdStates[adId] = AdLoadingState.failed;
          
          state = state.copyWith(bannerAdStates: newBannerAdStates);
          ad.dispose();
          debugPrint('Banner ad failed to load for ID $adId: $error');
        },
      ),
    );

    bannerAd.load();
  }

  // Load interstitial ad
  Future<void> loadInterstitialAd() async {
    await _ensureAdMobInitialized();

    if (state.interstitialAdState == AdLoadingState.loading) return;

    state = state.copyWith(interstitialAdState: AdLoadingState.loading);

    await InterstitialAd.load(
      adUnitId: AdUnitIds.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          state = state.copyWith(
            interstitialAd: ad,
            interstitialAdState: AdLoadingState.loaded,
          );
          debugPrint('Interstitial ad loaded successfully');

          ad.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          state = state.copyWith(interstitialAdState: AdLoadingState.failed);
          debugPrint('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  // Show interstitial ad
  Future<void> showInterstitialAd({VoidCallback? onAdClosed}) async {
    if (state.interstitialAd == null) {
      debugPrint('Interstitial ad not ready');
      return;
    }

    state.interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Interstitial ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        state = state.copyWith(
          interstitialAd: null,
          interstitialAdState: AdLoadingState.notLoaded,
        );
        onAdClosed?.call();
        loadInterstitialAd(); // Preload next ad
        debugPrint('Interstitial ad dismissed');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        state = state.copyWith(
          interstitialAd: null,
          interstitialAdState: AdLoadingState.failed,
        );
        debugPrint('Interstitial ad failed to show: $error');
      },
    );

    await state.interstitialAd!.show();
  }

  // Load rewarded ad
  Future<void> loadRewardedAd() async {
    await _ensureAdMobInitialized();

    if (state.rewardedAdState == AdLoadingState.loading) return;

    state = state.copyWith(rewardedAdState: AdLoadingState.loading);

    await RewardedAd.load(
      adUnitId: AdUnitIds.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          state = state.copyWith(
            rewardedAd: ad,
            rewardedAdState: AdLoadingState.loaded,
          );
          debugPrint('Rewarded ad loaded successfully');

          ad.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          state = state.copyWith(rewardedAdState: AdLoadingState.failed);
          debugPrint('Rewarded ad failed to load: $error');
        },
      ),
    );
  }

  // Show rewarded ad
  Future<void> showRewardedAd({
    required Function(RewardItem reward) onUserEarnedReward,
    VoidCallback? onAdClosed,
  }) async {
    if (state.rewardedAd == null) {
      debugPrint('Rewarded ad not ready');
      return;
    }

    state.rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Rewarded ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        state = state.copyWith(
          rewardedAd: null,
          rewardedAdState: AdLoadingState.notLoaded,
        );
        onAdClosed?.call();
        loadRewardedAd(); // Preload next ad
        debugPrint('Rewarded ad dismissed');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        state = state.copyWith(
          rewardedAd: null,
          rewardedAdState: AdLoadingState.failed,
        );
        debugPrint('Rewarded ad failed to show: $error');
      },
    );

    await state.rewardedAd!.show(
      onUserEarnedReward: (Ad ad, RewardItem reward) {
        onUserEarnedReward(reward);
      },
    );
  }

  // Get banner ad by ID
  BannerAd? getBannerAd(String adId) {
    return state.bannerAds[adId];
  }

  // Get banner ad state by ID
  AdLoadingState getBannerAdState(String adId) {
    return state.bannerAdStates[adId] ?? AdLoadingState.notLoaded;
  }

  // Check if banner ad is ready
  bool isBannerAdReady(String adId) {
    return state.bannerAdStates[adId] == AdLoadingState.loaded && 
           state.bannerAds[adId] != null;
  }

  // Check if interstitial ad is ready
  bool get isInterstitialAdReady => 
      state.interstitialAdState == AdLoadingState.loaded && 
      state.interstitialAd != null;

  // Check if rewarded ad is ready
  bool get isRewardedAdReady => 
      state.rewardedAdState == AdLoadingState.loaded && 
      state.rewardedAd != null;

  // Dispose specific banner ad
  void disposeBannerAd(String adId) {
    // Defer state update to avoid modifying provider during widget build
    Future.microtask(() {
      state.bannerAds[adId]?.dispose();
      final newBannerAds = Map<String, BannerAd?>.from(state.bannerAds);
      final newBannerAdStates = Map<String, AdLoadingState>.from(state.bannerAdStates);
      newBannerAds.remove(adId);
      newBannerAdStates.remove(adId);
      state = state.copyWith(
        bannerAds: newBannerAds,
        bannerAdStates: newBannerAdStates,
      );
    });
  }

  // Dispose all ads (helper for DRY)
  void disposeAllAds() {
    // Dispose all banner ads
    for (final ad in state.bannerAds.values) {
      ad?.dispose();
    }
    // Dispose other ads
    state.interstitialAd?.dispose();
    state.rewardedAd?.dispose();
    state = AdState(isAdMobInitialized: state.isAdMobInitialized);
  }

  @override
  void dispose() {
    disposeAllAds();
    super.dispose();
  }
}

// Ad provider
final adProvider = StateNotifierProvider<AdNotifier, AdState>((ref) {
  return AdNotifier();
});

// Convenience providers for specific ad states
final bannerAdProvider = Provider.family<BannerAd?, String>((ref, adId) {
  return ref.watch(adProvider).bannerAds[adId];
});

final bannerAdStateProvider = Provider.family<AdLoadingState, String>((ref, adId) {
  return ref.watch(adProvider).bannerAdStates[adId] ?? AdLoadingState.notLoaded;
});

final interstitialAdReadyProvider = Provider<bool>((ref) {
  final adState = ref.watch(adProvider);
  return adState.interstitialAdState == AdLoadingState.loaded && 
         adState.interstitialAd != null;
});

final rewardedAdReadyProvider = Provider<bool>((ref) {
  final adState = ref.watch(adProvider);
  return adState.rewardedAdState == AdLoadingState.loaded && 
         adState.rewardedAd != null;
});