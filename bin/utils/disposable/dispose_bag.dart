import 'dart:async';

class DisposeBag {
  final List<StreamSubscription> _subscriptions = [];

  void add(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  void dispose() {
    for (var element in _subscriptions) {
      // element.asFuture();
      element.cancel();
    }
  }
}
