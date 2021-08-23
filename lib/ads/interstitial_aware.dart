/// Created by Haoyi on 5/10/21
///
part of "ads_bloc.dart";

mixin InterstitialAware on AdsBloc {
  InterstitialAds? _iads;

  InterstitialAds? get interstitialAds {
    if (_iads == null) {
      final ads = adsDelegate.getInterstitialAds();
      final handler = interstitialAdsHandler;
      ads?.addHandler(handler);
      _iads = ads;
    }
    return _iads;
  }

  late AdsHandler interstitialAdsHandler;

  final StreamController<AdsEvent> adsEventStreamController = StreamController();

  Stream<AdsEvent> get observableInterstitialAdsEvent => adsEventStreamController.stream;

  void onInterstitialAdDisplayed(AdsEventPayload payload) {
    print("onInterstitialAdDisplayed ${this.hashCode}");
    adsEventStreamController.addEx(payload.event);
  }

  void onInterstitialAdClicked(AdsEventPayload payload) {
    print("onInterstitialAdClicked");
    adsEventStreamController.addEx(payload.event);
  }

  void onInterstitialAdHidden(AdsEventPayload payload) {
    print("onInterstitialAdHidden");
    adsEventStreamController.addEx(payload.event);
  }

  void onInterstitialAdDisplayFailed(AdsEventPayload payload) {
    adsEventStreamController.addEx(payload.event);
  }

  void onInterstitialAdStarted(AdsEventPayload payload) {
    adsEventStreamController.addEx(payload.event);
  }

  void onInterstitialAdLoaded(AdsEventPayload payload) {
    adsEventStreamController.addEx(payload.event);
  }

  void onInterstitialAdLoadFailed(AdsEventPayload payload) {
    adsEventStreamController.addEx(payload.event);
  }

  void bindInterstitialAd() {
    if (adsDelegate.isNoAds) {
      return;
    }
    final handlerDelegate = AdsHandlerDelegate(
        onAdLoadedCallback: onInterstitialAdLoaded,
        onAdClickedCallback: onInterstitialAdClicked,
        onAdHiddenCallback: (payload) {
          print("AdsHandlerDelegate interstitial onAdHidden");
          final completer = _pendingCompleter;
          if (completer != null && !completer.isCompleted) {
            completer.complete(AdsResult.success(AdType.interstitial));
            _pendingCompleter = null;
          }
          onInterstitialAdHidden(payload);
        },
        onAdDisplayFailedCallback: (payload) {
          final completer = _pendingCompleter;
          if (completer != null && !completer.isCompleted) {
            completer.complete(AdsResult.build(AdType.interstitial, AdCause.displayFailed));
            _pendingCompleter = null;
          }
          onInterstitialAdDisplayFailed(payload);
        },
        onAdLoadFailedCallback: (payload) {
          final completer = _pendingCompleter;
          if (completer != null && !completer.isCompleted) {
            completer.complete(AdsResult.build(AdType.interstitial, AdCause.loadFailed));
            _pendingCompleter = null;
          }
          onInterstitialAdLoadFailed(payload);
        },
        onAdDisplayedCallback: onInterstitialAdDisplayed);
    interstitialAdsHandler = handlerDelegate;
  }

  bool isLoadedInterstitialAds() {
    return _iads?.loaded == true;
  }

  void unbindInterstitialAd() {
    adsEventStreamController.close();
    if (adsDelegate.isNoAds) {
      return;
    }
    final handlerDelegate = interstitialAdsHandler;
    _iads?.removeHandler(handlerDelegate);
    _iads = null;
  }

  Future<AdsResult> showInterstitialAd({required String scene, bool ignoreNoAds = false}) async {
    final adType = AdType.interstitial;
    try {
      if (!ignoreNoAds && adsDelegate.isNoAds) {
        return AdsResult.build(AdType.interstitial, AdCause.noAds);
      }

      final iads = interstitialAds;
      if (iads == null) {
        return AdsResult.build(adType, AdCause.sdkNotInitialized);
      }

      final adCause = await iads.checkShow(scene: scene);
      if (adCause == AdCause.success) {
        final result = await iads.show(scene: scene);
        if (result) {
          LogUtils.recordLog("showInterstitial ads success!");
          _pendingCompleter?.complete(AdsResult.build(adType, AdCause.canceled));
          _pendingCompleter = Completer();
          return _pendingCompleter!.future;
        } else {
          return AdsResult.build(adType, AdCause.requestFailed);
        }
      } else {
        LogUtils.recordLog("showInterstitialAd error! $adCause");
        return AdsResult.build(adType, adCause);
      }
    } catch (error, stacktrace) {
      LogUtils.recordLog("showInterstitialAd exception! $error $stacktrace");
      return AdsResult.build(AdType.interstitial, AdCause.internalError);
    }
  }

  Future<AdsResult> showFallbackInterstitialAd({required String scene}) async {
    final adType = AdType.interstitial;
    final iads = interstitialAds;
    if (iads == null) {
      return AdsResult.build(adType, AdCause.sdkNotInitialized);
    }
    try {
      final result = await iads.show(scene: scene);
      if (result) {
        print("showInterstitial ads success!");
        _pendingCompleter?.complete(AdsResult.build(adType, AdCause.canceled));
        _pendingCompleter = Completer();
        return _pendingCompleter!.future;
      } else {
        return AdsResult.build(adType, AdCause.requestFailed);
      }
    } catch (error, stacktrace) {
      LogUtils.w("showFallbackInterstitialAd exception! $error $stacktrace");
      return AdsResult.build(AdType.interstitial, AdCause.internalError);
    }
  }
}
