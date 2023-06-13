import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

import '../utils/disposable/bloc.dart';
import '../utils/logger.dart';

class BaseBloc extends DisposableBloc {
  final _errors = PublishSubject<dynamic>();
  final _loading = BehaviorSubject<bool>.seeded(false);

  Stream<dynamic> get errors => _errors.stream;

  ValueStream<bool> get loading => _loading.stream;

  @protected
  void setError(dynamic value, {StackTrace? stack}) {
    logger.d("${runtimeType.toString()}: $value stack=$stack");
    if (!_errors.isClosed) {
      _errors.add(value);
    }
  }

  @protected
  void setLoading(bool value) {
    if (!_loading.isClosed) {
      _loading.add(value);
    }
  }

  @override
  void dispose() {
    _errors.close();
    _loading.close();
    super.dispose();
  }
}
