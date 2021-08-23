import 'dart:async';
import 'dart:io';

import 'package:ads_framework/ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter_analytics/flutter_analytics.dart';
import 'package:flutter_utils/extensions/extensions.dart';
import 'package:flutter_utils/logger/log_utils.dart';

import '../lifecycle_bloc.dart';

/// Created by Haoyi on 5/6/21
part "banner_aware.dart";

part "interstitial_aware.dart";

part "rewarded_aware.dart";

part "ads_service_delegate.dart";

abstract class AdsBloc extends LifecycleBloc {
  AdsDelegate get adsDelegate;

  Completer<AdsResult>? _pendingCompleter;

  AdsBloc() : super() {
    if (this is RewardedAware) {
      (this as RewardedAware).bindRewardedAd();
    }
    if (this is InterstitialAware) {
      (this as InterstitialAware).bindInterstitialAd();
    }
    if (this is BannerAware) {
      (this as BannerAware).initBanner();
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    if (this is BannerAware) {
      (this as BannerAware).disposeBanner();
    }
    if (this is InterstitialAware) {
      (this as InterstitialAware).unbindInterstitialAd();
    }
    if (this is RewardedAware) {
      (this as RewardedAware).unbindRewardedAd();
    }
    super.dispose();
  }

  @override
  @mustCallSuper
  void onResumed() {
    super.onResumed();
  }

  @override
  @mustCallSuper
  void onPaused() {
    super.onPaused();
  }
}
