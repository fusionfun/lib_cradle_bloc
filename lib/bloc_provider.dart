import 'package:flutter/material.dart';

import 'bloc.dart';
import 'lifecycle_bloc.dart';

/// Created by @RealCradle on 2020/4/21
///
///
typedef InitializerCallback<T extends BaseBloc> = void Function(T bloc);

// ignore: must_be_immutable
class BlocProvider<T extends BaseBloc> extends StatefulWidget {
  @deprecated
  final Widget child;
  final T bloc;
  final InitializerCallback<T>? initializer;
  final WidgetBuilder? builder;

  BlocProvider({Key? key, required this.bloc, required this.child, this.builder, this.initializer}) : super(key: key);

  @override
  _BlocProviderState createState() => _BlocProviderState<T>();

  static T? of<T extends BaseBloc>(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_BlocProvider<T>>()
        ?.bloc;
  }
}

class _BlocProviderState<T extends BaseBloc> extends State<BlocProvider<T>> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    widget.initializer?.call(widget.bloc);
    if (widget.bloc is LifecycleBloc) {
      WidgetsBinding.instance?.addObserver(this);
    }
    widget.bloc..contextDelegate = _getContext;
  }

  BuildContext _getContext() {
    print("getContext!! ${context != null}");
    return context;
  }

  @override
  void didChangePlatformBrightness() {
    if (widget.bloc is LifecycleBloc) {
      final lifecycleBloc = widget.bloc as LifecycleBloc;
      lifecycleBloc.dispatchOnPlatformBrightnessChanged(WidgetsBinding.instance?.window.platformBrightness);
    }
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    return _BlocProvider(bloc: widget.bloc, child: widget.builder?.call(context) ?? widget.child);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (widget.bloc is LifecycleBloc) {
      final lifecycleBloc = widget.bloc as LifecycleBloc;
      switch (state) {
        case AppLifecycleState.inactive:
          print("inactive");
          break;
        case AppLifecycleState.resumed:
          print("resumed");
          if (lifecycleBloc.isTopPath()) {
            lifecycleBloc.dispatchOnResumed();
          }
          break;
        case AppLifecycleState.paused:
          print("paused");
          if (lifecycleBloc.isTopPath()) {
            lifecycleBloc.dispatchOnPaused();
          }
          break;
        case AppLifecycleState.detached:
          print("detached");
          break;
      }
    }
  }

  @override
  void dispose() {
    widget.bloc.dispose();
    if (widget.bloc is LifecycleBloc) {
      WidgetsBinding.instance?.removeObserver(this);
    }
    super.dispose();
  }
}

class _BlocProvider<T extends BaseBloc> extends InheritedWidget {
  final T bloc;

  _BlocProvider({
    Key? key,
    required this.bloc,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_BlocProvider old) => bloc != old.bloc;
}
