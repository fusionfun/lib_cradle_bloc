/// Created by @RealCradle on 2021/8/21

part of "ads_bloc.dart";

mixin AdsDelegate {
  Stream<bool> get observableInitialized;

  bool get isNoAds;

  // banner

  BannerAds createBanner(String scene, {AdsHandler? adsHandler});

  InterstitialAds createInterstitialAds();

  InterstitialAds? getInterstitialAds({dynamic params});

  RewardedAds createRewardedAds();

  RewardedAds? getRewardedAds({dynamic params});

// void loadAds();
//
// Future<AdCause> checkInterstitialScene(String scene);
//
// Future<bool> showInterstitial(String scene);
//
// Future<bool> showRewarded(String scene);
//
// void addInterstitialAdsHandler(AdsHandler adsHandler);
//
// void removeInterstitialAdsHandler(AdsHandler adsHandler);
//
// void addRewardedAdsHandler(RewardedAdsHandler adsHandler);
//
// void removeRewardedAdsHandler(RewardedAdsHandler adsHandler);
//
// Future<AdCause> checkRewardedScene(String scene);
//
// bool isLoadedRewardedAds();
//
// bool isLoadedInterstitialAds();
//
// int getRewardedAdsRetryCount();
//
// int elapsedTimeInMillisSinceStartLoadRewardAds();
//
// bool isLoadingRewardAdsDelayed();
//
// Stream<bool> observeRewardAdsLoaded();
//
// void resetRewardedAds();
//
// void reloadRewardAds({bool force = false});
//
// void loadRewardAds();
}
