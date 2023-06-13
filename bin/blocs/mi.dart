import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/mi.dart';
import '../network/base.dart';
import '../network/mi.dart';
import '../utils/logger.dart';
import '../utils/preferences.dart';
import 'base.dart';
import 'config.dart';
import 'gpt.dart';

class MiBloc extends BaseBloc {
  static final MiBloc _instance = MiBloc._internal();
  static const String minaServiceId = "micoapi";
  static const String miioServiceId = "xiaomiio";

  static MiBloc get instance => _instance;
  late MiToken _token;
  late MiDevice _device;
  int? _lastTimestamp;
  bool _initialized = false;

  Map<String, dynamic> _getCookies(String serviceId) => {
        'sdkVersion': 3.9,
        'userId': _token.userId,
        'serviceToken': _token.services[serviceId]?.token == null
            ? null
            : '"${_token.services[serviceId]?.token}"',
        'PassportDeviceId': _token.deviceId,
        'deviceId': _token.deviceId,
      }..removeWhere((key, value) => value == null);

  MiBloc._internal() {
    _lastTimestamp = preferences.getInt(Preferences.keyMiLastTimestamp);
    _loadToken();
    _loadDevice();
  }

  Future<void> init() async {
    if (!_initialized) {
      logger.i("初始化小爱音箱服务...");
      await _getDeviceInfo();
      logger.i("小爱音箱服务初始化完成");
      _initialized = true;
    }
  }

  Future<bool> login(String serviceId, {bool forced = false}) async {
    if (!forced &&
        _token.passToken != null &&
        _token.services[serviceId] != null) {
      return true;
    }
    var result =
        (await network.serviceLogin(serviceId, _getCookies(serviceId)));
    if (result['code'] != 0) {
      Map<String, dynamic> params = {};
      params['qs'] = result['qs'];
      params['_sign'] = result['_sign'];
      params['sid'] = result['sid'];
      params['callback'] = Uri.encodeFull(result['callback']);
      params['_json'] = "true";
      params['user'] = ConfigBloc.instance.miUsername!;
      params['hash'] = md5
          .convert(ConfigBloc.instance.miPassword!.codeUnits)
          .toString()
          .toUpperCase();
      result = (await network.serviceAuth(params, _getCookies(serviceId)));
      if (result['code'] != 0) {
        logger.w("登录失败，请检查用户名和密码");
        return false;
      }
    }
    _token.userId = result['userId'];
    _token.passToken = result['passToken'];
    String ssecurity = result['ssecurity'];
    String? token = await network.serviceToken(
        location: result['location'],
        nonce: result['nonce'],
        ssecurity: ssecurity);
    if (token == null) {
      return false;
    }
    _token.services[serviceId] = MiServiceToken(token, ssecurity);
    _saveToken();
    return true;
  }

  Future<void> startListening() async {
    logger.i("等待提问。你可以使用这些提示词作为开头发起提问: ${ConfigBloc.instance.gptPrefix}");
    while (true) {
      String? question;
      try {
        question = await _getLastQuestion();
      } catch (e, s) {
        logger.e("获取对话数据时发生错误", e, s);
      }
      if (question != null) {
        question = question.trim();
        if (question.isNotEmpty) {
          logger.i("收到提问: $question");
          await playText("正在询问GPT，请稍等");
          try {
            String? response = await GptBloc.instance.ask(question);
            if (response == null) {
              await playText("出现错误，退出程序");
              return;
            }
            await playText("以下是GPT的回答：$response");
          } catch (e, s) {
            logger.e("询问GPT时发生错误", e, s);
            await playText("询问GPT时发生错误");
          }
        }
      }
      await Future.delayed(Duration(seconds: 2));
    }
  }

  Future<void> _getDeviceInfo() async {
    if (_device.did == null) {
      await _getDeviceDid();
    }
    if (_device.hardware == null || _device.deviceId == null) {
      await _getDeviceHardware();
    }
  }

  Future<void> _getDeviceHardware() async {
    var devices = await _getMinaDeviceList();
    if (devices == null) {
      logger.e("获取设备列表失败");
      return;
    }
    var device =
        devices.firstWhere((e) => e['miotDID'] == _device.did?.toString());
    if (device == null) {
      logger.e(
          "获取设备信息失败。找不到Did是 ${_device.did} 的设备，设备列表：${devices.map((e) => e['miotDID']).toList()}");
      return;
    }
    _device.hardware = device['hardware'];
    _device.deviceId = device['deviceID'];
    _saveDevice();
    logger.i(
        "获取到设备：${ConfigBloc.instance.miDeviceName}，型号：${_device.hardware}，deviceID：${_device.deviceId}");
  }

  Future<void> _getDeviceDid() async {
    var devices = await _getMiioDeviceList();
    if (devices == null) {
      logger.e("获取设备列表失败");
      return;
    }
    var device = devices
        .firstWhere((e) => e['name'] == ConfigBloc.instance.miDeviceName);
    if (device == null) {
      logger.e(
          "获取设备ID失败。找不到设备：${ConfigBloc.instance.miDeviceName}，设备列表：${devices.map((e) => e['name']).toList()}");
      return;
    }
    _device.did = int.tryParse(device['did']);
    _saveDevice();
    logger.i("获取到设备：${ConfigBloc.instance.miDeviceName}，did：${_device.did}");
  }

  Future<List?> _getMiioDeviceList() async {
    if (await login(miioServiceId, forced: true)) {
      List<Map>? devices = await network.miioDeviceList(
          cookies: _getCookies(miioServiceId),
          ssecurity: _token.services[miioServiceId]!.ssecurity);
      if (devices != null && devices.isNotEmpty) {
        return devices;
      }
    }
    return null;
  }

  Future<List?> _getMinaDeviceList() async {
    if (await login(minaServiceId, forced: true)) {
      List<Map>? devices =
          await network.minaDeviceList(cookies: _getCookies(minaServiceId));
      if (devices != null && devices.isNotEmpty) {
        return devices;
      }
    }
    return null;
  }

  Future<String?> _getLastQuestion() async {
    if (await login(minaServiceId)) {
      var result = await network.getConversations(
        hardware: _device.hardware!,
        dateTime: DateTime.now(),
        cookies: _getCookies(minaServiceId)
          ..addAll({
            'userId': _token.userId,
            'serviceToken': _token.services[minaServiceId]!.token,
            'deviceId': _device.deviceId,
          }),
      );
      if (result['code'] != 0) {
        _token = MiToken.empty();
        _saveToken();
        logger.w("登录过期");
        await login(minaServiceId);
        return null;
      }
      List<dynamic> records = json.decode(result['data'])['records'];
      if (records.isEmpty) {
        return null;
      }
      var record = records[0];
      if (_lastTimestamp == null) {
        _lastTimestamp = record['time'];
        preferences.putInt(Preferences.keyMiLastTimestamp, _lastTimestamp);
      } else {
        if (_lastTimestamp! < record['time']) {
          _lastTimestamp = record['time'];
          preferences.putInt(Preferences.keyMiLastTimestamp, _lastTimestamp);
        } else {
          return null;
        }
      }
      String query = record['query'];
      bool found = false;
      for (var prefix in ConfigBloc.instance.gptPrefix) {
        if (query.startsWith(prefix)) {
          query = query.replaceFirst(prefix, "");
          found = true;
          break;
        }
      }
      if (found) {
        return query;
      }
      return null;
    }
    return null;
  }

  Future<void> playText(String text) async {
    logger.i("开始播报：$text");
    var resp = await network.textToSpeech(
        deviceId: _device.deviceId!,
        text: text,
        cookies: _getCookies(minaServiceId));
    if (resp['code'] == 0) {
      logger.i("播报成功");
    } else {
      logger.w("播报失败 resp=$resp");
    }
  }

  void _loadToken() {
    bool empty = true;
    try {
      var jsonData = preferences.getJson(Preferences.keyMiToken);
      if (jsonData != null) {
        _token = MiToken.fromJson(jsonData);
        empty = false;
      }
    } catch (e, s) {
      logger.w("load token error", e, s);
    }
    if (empty) {
      _token = MiToken.empty();
      _token.deviceId = randomString(16).toUpperCase();
    }
  }

  void _saveToken() {
    preferences.putJson(Preferences.keyMiToken, _token.toJson());
  }

  void _loadDevice() {
    bool empty = true;
    try {
      var jsonData = preferences.getJson(Preferences.keyMiDevice);
      if (jsonData != null) {
        _device = MiDevice.fromJson(jsonData);
        empty = false;
      }
    } catch (e, s) {
      logger.w("load device error", e, s);
    }
    if (empty) {
      _device = MiDevice();
    }
  }

  void _saveDevice() {
    preferences.putJson(Preferences.keyMiDevice, _device.toJson());
  }

  static String randomString(int len) {
    String data = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    data += data.toLowerCase();
    data += "0123456789";
    String result = "";
    for (int i = 0; i < len; i++) {
      int index = (Random().nextDouble() * data.length).toInt();
      result += data.substring(index, index + 1);
    }
    return result;
  }
}
