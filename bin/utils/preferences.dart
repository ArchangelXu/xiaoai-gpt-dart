import 'dart:convert';

import 'cache.dart';

Preferences preferences = Preferences._internal();

class Preferences {
  /// 顶层变量，单例模式
  Preferences._internal();

  static const keyConversationId = "keyConversationId";
  static const keyParentMessageId = "keyParentMessageId";
  static const keyMiLastTimestamp = "keyMiLastTimestamp";
  static const keyMiToken = "keyMiToken";
  static const keyMiDevice = "keyMiDevice";
  static const keyGptModel = "keyGptModel";

  String? getString(String key) => FileCache.load((data) => data, key);

  int? getInt(String key) => FileCache.load((data) => int.tryParse(data), key);

  double? getDouble(String key) =>
      FileCache.load((data) => double.tryParse(data), key);

  bool? getBool(String key) =>
      FileCache.load((data) => bool.tryParse(data), key);

  dynamic getJson(String key) =>
      FileCache.load((data) => json.decode(data), key);

  void putString(String key, String? value) {
    if (value == null) {
      FileCache.remove(key);
      return;
    }
    FileCache.save(value, key);
  }

  void putInt(String key, int? value) async {
    if (value == null) {
      FileCache.remove(key);
      return;
    }
    FileCache.save(value.toString(), key);
  }

  void putDouble(String key, double? value) async {
    if (value == null) {
      FileCache.remove(key);
      return;
    }
    FileCache.save(value.toString(), key);
  }

  void putBool(String key, bool? value) async {
    if (value == null) {
      FileCache.remove(key);
      return;
    }
    FileCache.save(value.toString(), key);
  }

  void putJson(String key, dynamic value) async {
    if (value == null) {
      FileCache.remove(key);
      return;
    }
    FileCache.save(json.encode(value), key);
  }

  void remove(String key) {
    FileCache.remove(key);
  }

  void clear() {
    FileCache.clear();
  }
}
