import 'dart:async';

class StreamSubscriptions {
  final List<StreamSubscription> subscriptions = <StreamSubscription>[];

  void add(StreamSubscription subscription) {
    subscriptions.add(subscription);
  }

  void addAll(Iterable<StreamSubscription> subs) {
    subscriptions.addAll(subs);
  }

  void cancel() {
    subscriptions.forEach((subscription) {
      subscription.cancel();
    });
  }
}
