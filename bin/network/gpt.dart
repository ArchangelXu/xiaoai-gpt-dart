import '../blocs/config.dart';
import 'base.dart';

extension GptApi on Network {
  Future<Map> askGpt({
    required String prompt,
    required String model,
    required String? conversationId,
    required String parentMessageId,
    required String messageId,
  }) async {
    return getResponseObject<Map>(
      HttpMethod.post,
      buildXMUri(
        ssl: ConfigBloc.instance.gptIsSsl,
        host: ConfigBloc.instance.gptHost!,
        path: "api/conversation/talk",
      ),
      body: {
        'prompt': prompt,
        'model': model,
        'conversation_id': conversationId,
        'parent_message_id': parentMessageId,
        'message_id': messageId,
        'stream': false,
      },
      extraHeaders: {'Content-Type': "application/json"},
      deserializer: (e) => e,
    );
  }

  Future<String?> getModel() async {
    Map result = await getResponseObject<Map>(
      HttpMethod.get,
      buildXMUri(
        ssl: ConfigBloc.instance.gptIsSsl,
        host: ConfigBloc.instance.gptHost!,
        path: "api/models",
      ),
      extraHeaders: {'Content-Type': "application/json"},
      deserializer: (e) => e,
    );
    return result['models'][0]['slug'];
  }

  Future<bool> editConversationTitle(
    String conversationId,
    String title,
  ) async {
    Map result = await getResponseObject<Map>(
      HttpMethod.patch,
      buildXMUri(
        ssl: ConfigBloc.instance.gptIsSsl,
        host: ConfigBloc.instance.gptHost!,
        path: "api/conversation/$conversationId",
      ),
      body: {'title': title},
      extraHeaders: {'Content-Type': "application/json"},
      deserializer: (e) => e,
    );
    return result['success'] == true;
  }
}
