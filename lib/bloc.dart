import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_utils/extensions/extensions.dart';

export 'package:flutter_utils/extensions/extensions.dart';

/// Created by @RealCradle on 2020/4/21
///
///

typedef ContextDelegate = BuildContext Function();

abstract class BaseBloc {
  final CompositeSubscription subscriptions = CompositeSubscription();

  ContextDelegate? contextDelegate;

  BuildContext? get context => contextDelegate?.call();

  void addSubscription(StreamSubscription subscription) {
    subscriptions.add(subscription);
  }

  @mustCallSuper
  void dispose() {
    subscriptions.clear();
  }
}
