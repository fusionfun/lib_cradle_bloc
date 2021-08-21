import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_utils/router/router.dart';
import 'package:rxdart/rxdart.dart';

import 'bloc.dart';

/// Created by @RealCradle on 2020/4/30
///

enum LifecycleState { created, paused, resumed }

abstract class LifecycleBloc extends BaseBloc {
  late StreamSubscription<RouteStack> routeStackSubscription;

  final RouteEntry routeEntry;

  final BehaviorSubject<LifecycleState> stateController = BehaviorSubject<LifecycleState>.seeded(LifecycleState.created);

  final BehaviorSubject<Brightness> brightnessController = BehaviorSubject<Brightness>.seeded(Brightness.light);

  LifecycleState currentLifecycleState = LifecycleState.created;

  bool get isResumed => currentLifecycleState == LifecycleState.resumed;

  Stream<LifecycleState> get observableLifecycleState => stateController.stream;

  Brightness get currentPlatformBrightness => brightnessController.value ?? Brightness.light;

  // todo: 首次打开时，由于初始路由的机制，路由回调的顺序会受到回调的影响
  LifecycleBloc({bool test(RouteEntry element)?})
      : this.routeEntry = ((test != null)
            ? GlobalRoutesObserver().firstWhere((element) => test(element), orElse: () => GlobalRoutesObserver().top!)
            : GlobalRoutesObserver().top)! {
    print("[lifecycleBloc CREATE]${routeEntry.routeUri}");
    routeStackSubscription = GlobalRoutesObserver().observableRouteStack.listen((stack) {
      stack.dumpStack(summary: "$this:{${routeEntry.routeUri}]}");

      LifecycleState newState;
      if (stack.isTopEntry(routeEntry)) {
        newState = LifecycleState.resumed;
      } else {
        newState = LifecycleState.paused;
      }
      if (newState != currentLifecycleState) {
        if (newState == LifecycleState.paused) {
          dispatchOnPaused();
        } else {
          dispatchOnResumed();
        }
      }
    }, onError: (error) {
      debugPrint("observe route stack error!");
    });

    final platformBrightness = WidgetsBinding.instance?.window.platformBrightness;
    if (platformBrightness != null) {
      brightnessController.add(platformBrightness);
    }
  }

  bool isTopPath() {
    return GlobalRoutesObserver().isTopEntry(routeEntry);
  }

  void dispatchOnPaused() {
    debugPrint("onPause:${routeEntry.routeUri.path}");

    currentLifecycleState = LifecycleState.paused;
    stateController.add(LifecycleState.paused);
    onPaused();
  }

  void dispatchOnResumed() {
    debugPrint("onResumed:${routeEntry.routeUri.path}");
    currentLifecycleState = LifecycleState.resumed;
    stateController.add(LifecycleState.resumed);
    onResumed();
  }

  void dispatchOnPlatformBrightnessChanged(Brightness? brightness) {
    if (brightness != null && brightness != brightnessController.value) {
      brightnessController.add(brightness);
    }
  }

  @mustCallSuper
  void onPaused() {}

  @mustCallSuper
  void onResumed() {}

  @mustCallSuper
  @override
  void dispose() {
    print("LifecycleBloc dispose $routeEntry");
    routeStackSubscription.cancel();
//    onPaused();
    stateController.close();
    super.dispose();
  }
}
