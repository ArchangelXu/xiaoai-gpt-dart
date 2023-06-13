import 'dispose_bag.dart';

abstract class DisposableBloc {
  final DisposeBag disposeBag = DisposeBag();

  void dispose() {
    disposeBag.dispose();
  }
}
