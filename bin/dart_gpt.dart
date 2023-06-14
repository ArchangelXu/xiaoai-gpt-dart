import 'services/config.dart';
import 'services/gpt.dart';
import 'services/mi.dart';

bool isDebug = false;

Future<void> main(List<String> arguments) async {
  assert(() {
    isDebug = true;
    return true;
  }());
  if (ConfigService.instance.miUsername == null ||
      ConfigService.instance.miPassword == null) {
    return;
  }
  await MiService.instance.init();
  if (await GptService.instance.initPandoraService()) {
    MiService.instance.startListening();
  }
}
