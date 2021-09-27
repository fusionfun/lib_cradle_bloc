/// Created by Haoyi on 6/1/21

part of "ads_bloc.dart";

typedef ShowAdsLoadingDelegate = Future Function(BuildContext context, {Duration duration, required Stream<bool> closeStream, String scene});

mixin RewardedAware on AdsBloc {
  late RewardedAdsHandler rewardedAdsHandler;

  bool _latestUserRewarded = false;

  RewardedAds? _rads;

  RewardedAds? get rewardedAds {
    if (_rads == null) {
      final ads = adsDelegate.getRewardedAds();
      final handler = rewardedAdsHandler;
      if (ads != null) {
        ads.addHandler(handler);
      }
      _rads = ads;
    }
    return _rads;
  }

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
    rewardedAdsHandler = RewardsAdsHandlerDelegate(
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
    // adsService.addRewardedAdsHandler(handlerDelegate);
  }

  bool isLoadedRewardedAds() {
    final ads = rewardedAds;
    return (ads?.loaded == true) || ((this is InterstitialAware) && (this as InterstitialAware).isLoadedInterstitialAds());
  }

  void unbindRewardedAd() {
    _rads?.removeHandler(rewardedAdsHandler);
    _rads = null;
  }

  RewardedAds _resetRewardedAds(RewardedAds ads, {bool load = true}) {
    ads.dispose();
    final result = adsDelegate.createRewardedAds()
      ..addHandler(rewardedAdsHandler);
    if (load) {
      return result..load();
    } else {
      return result;
    }
  }

  Future<AdsResult> showRewardedAd({required BuildContext context, required String scene, ShowAdsLoadingDelegate? showAdsLoading}) async {
    final adType = AdType.rewarded;
    bool showLoading = false;
    bool result = false;
    int retry = 0;
    RewardedAds rads = rewardedAds ?? InvalidRewardedAds();

    if (rads is InvalidRewardedAds) {
      return AdsResult.build(adType, AdCause.sdkNotInitialized);
    }

    do {
      if (rads.loaded != true) {
        print("[$retry]adsService.isLoadedRewardedAds():${rads.loaded}");
        // 如果最后请求rewards广告的最近时间大于30秒
        final elapsedTime = rads.elapsedTimeInMillisSinceStartLoadAds;
        if (elapsedTime > 30 * 1000) {
          // 如果请求广告时间已经超过60秒且当前不处于delay状态，这时将会重制广告对象
          if (elapsedTime > 60 * 1000 && !rads.isLoadingRewardAdsDelayed) {
            rads = _resetRewardedAds(rads, load: true);
            Analytics.logEventEx("rads_rebuild");
            LogUtils.recordLog("reset rewarded ads");
          } else {
            // 否则强制reload一次
            rads.reload(force: true);
            LogUtils.recordLog("force reload");
          }
        }
        showLoading = true;
        await showAdsLoading?.call(context, duration: Duration(seconds: 5), closeStream: rads.observableLoaded, scene: scene);
      }

      // 这里如果show 失败了，底层会清掉loaded标记
      result = await rads.show(scene: scene).catchError((error, stacktrace) {
        LogUtils.d("show rewarded video error! $error $stacktrace");
        // AnalyticsUtils.logException(ShowRewardedVideoAdsException(errorMsg), stacktrace: stacktrace);
        return false;
      });
    } while (!result && !showLoading && retry++ < 1);
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
