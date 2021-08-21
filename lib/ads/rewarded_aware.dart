/// Created by Haoyi on 6/1/21

part of "ads_bloc.dart";

typedef showAdsLoadingDelegate = Future Function(BuildContext context, {Duration duration, Stream<bool> closeStream, String scene});

mixin RewardedAware on AdsBloc {
  RewardedAdsHandler? rewardedAdsHandler;

  bool _latestUserRewarded = false;

  void onRewardedAdDisplayed(AdsEventPayload payload) {
    print("onRewardedAdDisplayed");
  }

  void onRewardedAdClicked(AdsEventPayload payload) {
    print("onRewardedAdClicked");
  }

  void onRewardedAdHidden(AdsEventPayload payload) {
    print("onRewardedAdHidden");
  }

  void onRewardedAdDisplayFailed(AdsEventPayload payload) {}

  void onRewardedAdStarted(AdsEventPayload payload) {}

  void onRewardedAdLoaded(AdsEventPayload payload) {}

  void onRewardedAdLoadFailed(AdsEventPayload payload) {}

  void onUserRewarded(AdsEventPayload payload) {}

  void bindRewardedAd() {
    final handlerDelegate = RewardsAdsHandlerDelegate(
        onAdLoadedCallback: (payload) {
          onRewardedAdLoaded(payload);
        },
        onAdClickedCallback: onRewardedAdClicked,
        onAdHiddenCallback: (payload) {
          print("AdsHandlerDelegate rewarded onAdHidden");
          final completer = _pendingCompleter;
          if (completer != null && !completer.isCompleted) {
            completer.complete(AdsResult.build(AdType.rewarded, _latestUserRewarded ? AdCause.success : AdCause.rewardedFailed));
            _pendingCompleter = null;
          }
          onRewardedAdHidden(payload);
          _latestUserRewarded = false;
        },
        onAdDisplayFailedCallback: (payload) {
          final completer = _pendingCompleter;
          if (completer != null && !completer.isCompleted) {
            completer.complete(AdsResult.build(AdType.rewarded, AdCause.displayFailed));
            _pendingCompleter = null;
          }
          onRewardedAdDisplayFailed(payload);
        },
        onAdLoadFailedCallback: (payload) {
          onRewardedAdLoadFailed(payload);
        },
        onAdDisplayedCallback: onRewardedAdDisplayed,
        onAdRewardedCallback: (payload) {
          print("AdsHandlerDelegate onUserRewarded");
          _latestUserRewarded = true;
          // final completer = _pendingCompleter;
          // if (completer != null && !completer.isCompleted) {
          //   completer.complete(AdsResult.success(AdType.rewarded));
          //   _pendingCompleter = null;
          // }
          // onUserRewarded(payload);
        });
    rewardedAdsHandler = handlerDelegate;
    adsService.addRewardedAdsHandler(handlerDelegate);
  }

  bool isLoadedRewardedAds() {
    return adsService.isLoadedRewardedAds() || ((this is InterstitialAware) && (this as InterstitialAware).isLoadedInterstitialAds());
  }

  void unbindRewardedAd() {
    final handlerDelegate = rewardedAdsHandler;
    if (handlerDelegate != null) {
      adsService.removeRewardedAdsHandler(handlerDelegate);
    }
    rewardedAdsHandler = null;
  }

  Future<AdsResult> showRewardedAd({required BuildContext context, required String scene, showAdsLoadingDelegate? showAdsLoading}) async {
    final adType = AdType.rewarded;
    bool showLoading = false;
    bool result = false;
    int retry = 0;
    do {
      if (!adsService.isLoadedRewardedAds()) {
        print("[$retry]adsService.isLoadedRewardedAds():${adsService.isLoadedRewardedAds()}");
        // 如果最后请求rewards广告的最近时间大于30秒
        final elapsedTime = adsService.elapsedTimeInMillisSinceStartLoadRewardAds();
        if (elapsedTime > 30 * 1000) {
          // 如果请求广告时间已经超过60秒且当前不处于delay状态，这时将会重制广告对象
          if (elapsedTime > 60 * 1000 && !adsService.isLoadingRewardAdsDelayed()) {
            adsService.resetRewardedAds();
            adsService.loadRewardAds();
            Analytics.logEventEx("rads_rebuild");
            LogUtils.recordLog("reset rewarded ads");
          } else {
            // 否则强制reload一次
            adsService.reloadRewardAds(force: true);
            LogUtils.recordLog("force reload");
          }
        }
        showLoading = true;
        await showAdsLoading?.call(context, duration: Duration(seconds: 5), closeStream: adsService.observeRewardAdsLoaded(), scene: scene);
      }

// 这里如果show 失败了，底层会清掉loaded标记
      result = await adsService.showRewarded(scene).catchError((error, stacktrace) {
        LogUtils.d("show rewarded video error! $error $stacktrace");
        return false;
      });
      retry++;
    } while (!result && !showLoading && retry < 1);
// 如果返回结果为false，并且用户没有看到过loading页面
// retry<1的判断是防止showRewarded没有正常清loaded造成的死循环

    if (result) {
      print("showRewardedAd ads success!");
      _pendingCompleter?.complete(AdsResult.build(adType, AdCause.canceled));
      _pendingCompleter = Completer();
      return _pendingCompleter!.future;
    } else {
      print("showRewardedAd ads failed! $this");
      if (this is InterstitialAware) {
        print("show fallback");
        return await (this as InterstitialAware).showFallbackInterstitialAd(scene: "fallback_$scene");
      }
      return AdsResult.build(adType, AdCause.requestFailed);
    }
  }
}
