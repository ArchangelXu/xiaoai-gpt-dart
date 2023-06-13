import 'blocs/config.dart';
import 'blocs/gpt.dart';
import 'blocs/mi.dart';

bool isDebug = false;

Future<void> main(List<String> arguments) async {
  assert(() {
    isDebug = true;
    return true;
  }());
  if (ConfigBloc.instance.miUsername == null ||
      ConfigBloc.instance.miPassword == null) {
    return;
  }
  await MiBloc.instance.init();
  if (await GptBloc.instance.initPandoraService()) {
    MiBloc.instance.startListening();
  }
}
