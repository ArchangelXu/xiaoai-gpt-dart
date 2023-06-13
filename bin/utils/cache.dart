import 'dart:io';

import 'logger.dart';

class FileCache {
  static String _getRootPath() {
    Directory root = Directory("file_cache");
    if (!root.existsSync()) {
      root.createSync();
    }
    return root.path;
  }

  static File _getCacheFile(String key) {
    return File("${_getRootPath()}/$key.txt");
  }

  static void save<T>(
    String data,
    String key,
  ) {
    File? file;
    try {
      file = _getCacheFile(key);
      logger.d("save: ${file.path}");

      file.writeAsString(data);
    } catch (e, s) {
      logger.w("save error, path:${file?.path}", e, s);
    }
  }

  static T? load<T>(
    T? Function(String data) resolve,
    String key,
  ) {
    T? data;
    File? file;
    try {
      file = _getCacheFile(key);
      logger.d("load: ${file.path}");
      final exists = file.existsSync();
      if (!exists) {
        return data;
      }

      var contents = file.readAsStringSync();
      if (contents.isEmpty) {
        logger.i("load: ${file.path} is empty $contents");
        return data;
      }

      data = resolve(contents);
    } catch (e, s) {
      logger.w("load error, path:${file?.path}", e, s);
    }
    return data;
  }

  static void remove(String key) {
    File? file;
    try {
      file = _getCacheFile(key);

      logger.d("delete: ${file.path}");
      final exists = file.existsSync();
      if (!exists) {
        return;
      }
      file.deleteSync();
    } catch (e, s) {
      logger.w(
        "remove error, path:${file?.path}",
        e,
        s,
      );
    }
  }

  static void clear() {
    final path = _getRootPath();
    var dir = Directory(path);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    logger.d("clear cache dir: '$path'");
  }
}
