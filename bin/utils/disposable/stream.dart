import 'dart:async';

import 'dispose_bag.dart';

extension DisposableStreamSubscription on StreamSubscription {
  StreamSubscription cancelBy(DisposeBag disposeBag) {
    disposeBag.add(this);
    return this;
  }
}
