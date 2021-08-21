/// Created by Haoyi on 5/10/21

part of "ads_bloc.dart";

class _BannerStatus {
  final LifecycleState lifecycleState;
  final bool adLoaded;

  _BannerStatus(this.lifecycleState, this.adLoaded);
}

mixin BannerAware on AdsBloc {
  late BannerAds bannerAds;

  String get bannerScene => "";
  final BehaviorSubject<bool> adLoadedSubject = BehaviorSubject.seeded(false);

  bool bannerAdIsShow = false;
  bool bannerAdIsLoad = false;

  Stream<bool> get observableLoadBannerWhenReady => Stream.value(true);

  void onBannerAdDisplayed(AdsEventPayload payload) {
    print("onBannerAdDisplayed !");
  }

  void onBannerAdClicked(AdsEventPayload payload) {
    print("onBannerAdClicked !");
  }

  void onBannerAdHidden(AdsEventPayload payload) {
    print("onBannerAdHidden !");
  }

  void onBannerAdDisplayFailed(AdsEventPayload payload) {
    print("onBannerAdDisplayFailed !");
  }

  void onBannerAdStarted(AdsEventPayload payload) {
    print("onBannerAdStarted !");
  }

  @mustCallSuper
  void onBannerAdLoaded(AdsEventPayload payload) {
    print("onBannerAdLoaded !");
    if (adLoadedSubject.value != true) {
      adLoadedSubject.addEx(true);
    }
  }

  void onBannerAdLoadFailed(AdsEventPayload payload) {}

  void initBanner() async {
    if (adsService.isNoAds) {
      return;
    }
    bannerAds = await adsService.createBanner(bannerScene,
        adsHandler: AdsHandlerDelegate(
          onAdLoadedCallback: onBannerAdLoaded,
          onAdLoadFailedCallback: onBannerAdLoadFailed,
          onAdDisplayFailedCallback: onBannerAdDisplayFailed,
          onAdDisplayedCallback: onBannerAdDisplayed,
          onAdClickedCallback: onBannerAdClicked,
          onAdHiddenCallback: onBannerAdHidden,
        ));

    addSubscription(Rx.combineLatest2<bool, bool, bool>(
            adsService.observableInitialized, observableLoadBannerWhenReady, (a, b) => a && b)
        .listen((ready) {
      print("mopub sdk initialize result: $ready");
      if (ready) {
        loadBanner();
      }
    }, onError: (error, stacktrace) {
      LogUtils.e("observable Mopub Sdk initialized error! $error $stacktrace");
    }));

    addSubscription(Rx.combineLatest2<LifecycleState, bool, _BannerStatus>(
        observableLifecycleState,
        adLoadedSubject.stream,
        (lifecycleState, loaded) => _BannerStatus(lifecycleState, loaded)).listen((status) {
      LogUtils.i(
          "observable banner lifecycle state:${status.lifecycleState} adLoaded:${status.adLoaded} $bannerAdIsShow");

      if (status.lifecycleState == LifecycleState.resumed) {
        if (status.adLoaded) {
          showBanner();
        }
      } else {
        Future.delayed(Duration(milliseconds: 100), () {
          print("hideBanner!");
          hideBanner();
        });

      }
    }, onError: (error, stacktrace) {
      LogUtils.e("observable lifecycle state and loaded state error! $error, $stacktrace");
    }));
  }

  void disposeBanner() {
    if (adsService.isNoAds) {
      return;
    }
    bannerAds.dispose();
    adLoadedSubject.close();
  }

  void onBannerResume() {}

  void onBannerPaused() {}

  void hideBanner() {
    if (adsService.isNoAds) {
      return;
    }
    if (bannerAdIsShow) {
      bannerAds.hide();
      bannerAdIsShow = false;
    }
  }

  void loadBanner() {
    if (adsService.isNoAds) {
      return;
    }
    if (!bannerAdIsLoad) {
      print("load mopub banner!!");
      bannerAdIsLoad = true;
      bannerAds.load().then((result) {
        if (result != bannerAdIsLoad) {
          bannerAdIsLoad = result;
        }
      });
    }
  }

  void showBanner() async {
    if (adsService.isNoAds) {
      return;
    }
    if (!bannerAdIsShow) {
      bannerAdIsShow = await bannerAds.show(scene: bannerScene);
    }
  }
}
