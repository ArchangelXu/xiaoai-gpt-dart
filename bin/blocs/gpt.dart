import 'dart:io';

import 'package:uuid/uuid.dart';

import '../network/base.dart';
import '../network/gpt.dart';
import '../utils/logger.dart';
import '../utils/preferences.dart';
import 'base.dart';
import 'config.dart';

class GptBloc extends BaseBloc {
  static const String _tokenFileName = "token.txt";
  static const String _pandoraPackageName = "pandora-chatgpt";
  static final GptBloc _instance = GptBloc._internal();

  static GptBloc get instance => _instance;

  String? _conversationId;
  String? _model;
  late String _parentMessageId;

  final Uuid _uuid = Uuid();

  GptBloc._internal() {
    _model = preferences.getString(Preferences.keyGptModel);
    _conversationId = preferences.getString(Preferences.keyConversationId);
    _parentMessageId = preferences.getString(Preferences.keyParentMessageId) ??
        _generateMessageId();
  }

  Future<String?> ask(String prompt) async {
    if (_model == null) {
      _model = await _getModel();
      if (_model != null) {
        logger.i("获取到GPT model：$_model");
        preferences.putString(Preferences.keyGptModel, _model);
      } else {
        logger.e("未指定GPT model");
        return null;
      }
    }
    String messageId = _generateMessageId();
    Map data = await network.askGpt(
      model: _model!,
      prompt: "$prompt${ConfigBloc.instance.gptPromptPostfix ?? ""}",
      messageId: messageId,
      conversationId: _conversationId,
      parentMessageId: _parentMessageId,
    );
    _parentMessageId = data['message']['id'];
    bool newConversation = _conversationId == null;
    _conversationId = data['conversation_id'];
    if (newConversation) {
      _renameConversation();
    }
    preferences.putString(Preferences.keyConversationId, _conversationId);
    preferences.putString(Preferences.keyParentMessageId, _parentMessageId);
    String response = (data['message']['content']['parts'] as List<dynamic>)
        .map((e) => e.toString())
        .join("");
    return response;
  }

  String _generateMessageId() => _uuid.v4();

  Future<void> _renameConversation() async {
    String title = _generateConversationTitle();
    if (await network.editConversationTitle(_conversationId!, title)) {
      logger.i("新对话命名为：$title");
    } else {
      logger.w("新对话命名失败");
    }
  }

  String _generateConversationTitle() {
    var now = DateTime.now();
    return "${now.year}年${now.month}月${now.day}日";
  }

  Future<String?> _getModel() async {
    return await network.getModel();
  }

  Future<bool> initPandoraService() async {
    logger.i("初始化Pandora服务...");
    if (!await _writeTokenFile()) {
      return false;
    }
    if (!await _isPipInstalled()) {
      if (!await _installPip()) {
        logger.e("安装pip失败");
        return false;
      }
    }
    if (!await _isPandoraInstalled()) {
      if (!await _installPandora()) {
        logger.e("安装pandora失败");
        return false;
      }
    }
    if (!_startPandoraServer()) {
      return false;
    }
    logger.i("Pandora服务初始化完成");
    return true;
  }

  Future<bool> _writeTokenFile() async {
    try {
      File file = File(_tokenFileName);
      file.writeAsStringSync(ConfigBloc.instance.gptToken!);
    } catch (e, s) {
      logger.e("写入token文件失败", e, s);
      return false;
    }
    return true;
  }

  bool _startPandoraServer() {
    try {
      _executeCommand(
        "nohup pandora --server ${ConfigBloc.instance.gptHost} --token_file $_tokenFileName --verbose",
        runInShell: true,
      );
    } catch (e, s) {
      logger.e("启动pandora服务失败", e, s);
      return false;
    }
    return true;
  }

  Future<bool> _isPipInstalled() async {
    ProcessResult result = await _executeCommand("pip --help");
    return result.exitCode == 0;
  }

  Future<bool> _installPip() async {
    ProcessResult result;
    try {
      result =
          await _executeCommand("wget https://bootstrap.pypa.io/get-pip.py");
      if (result.exitCode != 0) {
        return false;
      }
    } catch (e, s) {
      logger.e("wget失败。请使用其他方式自行安装pip", e, s);
      return false;
    }
    result = await _executeCommand("python get-pip.py");
    return result.exitCode == 0;
  }

  Future<bool> _isPandoraInstalled() async {
    ProcessResult result =
        await _executeCommand("pip show $_pandoraPackageName");
    return result.exitCode == 0;
  }

  Future<bool> _installPandora() async {
    ProcessResult result =
        await _executeCommand("pip install $_pandoraPackageName");
    return result.exitCode == 0;
  }

  Future<ProcessResult> _executeCommand(String cmd,
      {bool runInShell = false}) async {
    logger.d("executing '$cmd'...");
    var split = cmd.split(" ");
    List<String> arguments;
    if (split.length > 1) {
      arguments = split.skip(1).toList();
    } else {
      arguments = [];
    }
    String command = split[0];
    logger.d("cmd = $command args = $arguments");
    ProcessResult result =
        await Process.run(command, arguments, runInShell: runInShell);
    _logProcess(result);
    return result;
  }

  void _logProcess(ProcessResult result) {
    if (result.stdout.toString().trim().isNotEmpty) {
      logger.d("stdout:\n${result.stdout}");
    }
    if (result.stderr.toString().trim().isNotEmpty) {
      logger.d("stderr:\n${result.stderr}");
    }
    logger.d("finished, code = ${result.exitCode}");
  }
}
