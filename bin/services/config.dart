import 'dart:convert';
import 'dart:io';

import '../utils/logger.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();

  static ConfigService get instance => _instance;
  String? miUsername;
  String? miPassword;
  String? miDeviceName;
  String? gptHost;
  String? gptToken;
  late bool gptIsSsl;
  List<String> gptPrefix = [];
  String? gptPromptPostfix;

  ConfigService._internal() {
    _loadConfig();
  }

  void _loadConfig() {
    try {
      File file = File("config.json");
      String jsonText = file.readAsStringSync();
      Map<String, dynamic> jsonData = json.decode(jsonText);
      miUsername = jsonData['mi_username'];
      miPassword = jsonData['mi_password'];
      miDeviceName = jsonData['mi_device_name'];
      gptHost = jsonData['gpt_host'];
      gptToken = jsonData['gpt_token'];
      gptPromptPostfix = jsonData['gpt_prompt_postfix'] ?? "";
      gptPrefix.addAll(
          (jsonData['gpt_prefix'] as List<dynamic>).map((e) => e.toString()));
    } catch (e, s) {
      logger.e("读取config.json失败", e, s);
      return;
    }
    if (_paramNotSet(miUsername)) {
      logger.e("小米账号用户名未设置");
      return;
    }
    if (_paramNotSet(miPassword)) {
      logger.e("小米账号密码未设置");
      return;
    }
    if (_paramNotSet(miDeviceName)) {
      logger.e("小米设备名称未设置");
      return;
    }
    if (_paramNotSet(gptToken)) {
      logger.e("GPT Access Token未设置");
      return;
    }
    if (_paramNotSet(gptHost)) {
      logger.e("GPT Host未设置");
      return;
    } else {
      gptIsSsl = gptHost!.startsWith("https");
      gptHost = gptHost!.substring(gptHost!.indexOf("//") + "//".length);
    }
    if (gptPrefix.isEmpty) {
      logger.e("提问GPT前缀未设置");
      return;
    }
  }

  bool _paramNotSet(String? param) => param == null || param.trim().isEmpty;
}
