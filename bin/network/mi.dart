import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../services/mi.dart';
import 'base.dart';

extension MiApi on Network {
  static const _userAgent =
      "APP/com.xiaomi.mihome APPV/6.0.103 iosPassportSDK/3.9.0 iOS/14.4 miHSTS";

  // Those responses start with a god damn prefix: &&&START&&&, like:
  // &&&START&&&{'code':0, 'result':xxx}
  // Who the hell come with an idea like that???
  Map<String, dynamic> _deserializer(String raw) =>
      json.decode(raw.substring(11));

  Future<Map> serviceLogin(
      String serviceName, Map<String, dynamic> cookies) async {
    return getResponseObject<Map>(
      HttpMethod.get,
      buildXMUri(
          ssl: true,
          host: "account.xiaomi.com",
          path: "pass/serviceLogin",
          params: {'sid': serviceName, '_json': "true"}),
      extraHeaders: {
        'Cookie': cookies.entries.map((e) => "${e.key}=${e.value}").join(";"),
        'User-Agent': _userAgent
      },
      rawDeserializer: _deserializer,
    );
  }

  Future<Map> serviceAuth(
    Map<String, dynamic> data,
    Map<String, dynamic> cookies,
  ) async {
    return getResponseObject<Map>(
      HttpMethod.post,
      buildXMUri(
        ssl: true,
        host: "account.xiaomi.com",
        path: "pass/serviceLoginAuth2",
      ),
      bodyFields: data,
      extraHeaders: {
        'Cookie': cookies.entries.map((e) => "${e.key}=${e.value}").join(";"),
        "Content-Type": "application/x-www-form-urlencoded",
        'User-Agent': _userAgent,
      },
      rawDeserializer: _deserializer,
    );
  }

  Future<String?> serviceToken({
    required String location,
    required int nonce,
    required String ssecurity,
  }) async {
    var uri = Uri.parse(location);
    var nsec = 'nonce=$nonce&$ssecurity';
    var clientSign = base64.encode(sha1.convert(nsec.codeUnits).bytes);
    uri = uri.replace(
        queryParameters: {}
          ..addAll(uri.queryParameters)
          ..['clientSign'] = Uri.encodeFull(clientSign));
    Map<String, dynamic>? headers = await getResponseHeaders(
      HttpMethod.get,
      uri,
    );
    String cookies = headers?['set-cookie'];
    // Sometimes the cookies be like:
    // userId=xxx; Path=/; Domain=sts.api.io.mi.com,cUserId=xxx;
    // Path=/; Domain=sts.api.io.mi.com,serviceToken=xxx;
    // Path=/; Domain=sts.api.io.mi.com
    // the serviceToken comes after a comma... So we get it by subString()
    cookies = cookies
        .substring(cookies.indexOf("serviceToken") + "serviceToken".length);
    cookies = cookies.substring(0, cookies.indexOf(";"));
    return cookies.substring(cookies.indexOf("=") + 1).trim();
  }

  Future<Map> getConversations({
    required String hardware,
    required DateTime dateTime,
    required Map<String, dynamic> cookies,
  }) async {
    return getResponseObject<Map>(
      HttpMethod.get,
      buildXMUri(
          ssl: true,
          host: "userprofile.mina.mi.com",
          path: "device_profile/v2/conversation",
          params: {
            'source': "dialogu",
            'hardware': hardware,
            'timestamp': dateTime.millisecondsSinceEpoch,
            'limit': 2,
          }),
      extraHeaders: {
        'Cookie': cookies.entries.map((e) => "${e.key}=${e.value}").join(";"),
        'User-Agent': _userAgent,
      },
      deserializer: (data) => data,
    );
  }

  Future<dynamic> textToSpeech({
    required String deviceId,
    required String text,
    required Map<String, dynamic> cookies,
  }) async {
    return _ubusRequest(
      deviceId: deviceId,
      method: "text_to_speech",
      path: "mibrain",
      message: {"text": text},
      cookies: cookies,
    );
  }

  Future<List<Map>?> minaDeviceList({
    required Map<String, dynamic> cookies,
  }) async {
    Map data = await _minaRequest(
        path: "/admin/v2/device_list",
        cookies: cookies,
        queryParams: {'master': 0});
    if (data['code'] != 0) {
      return null;
    }
    return (data['data'] as List<dynamic>).map((e) => e as Map).toList();
  }

  Future<List<Map>?> miioDeviceList({
    required String ssecurity,
    required Map<String, dynamic> cookies,
  }) async {
    Map data = await _miioRequest(
        path: "/home/device_list",
        ssecurity: ssecurity,
        cookies: cookies,
        data: {'getVirtualModel': false, 'getHuamiDevices': 0});
    if (data['code'] != 0) {
      return null;
    }
    return (data['result']['list'] as List<dynamic>)
        .map((e) => e as Map)
        .toList();
  }

  Future<Map> _miRequest({
    required Uri uri,
    required String serviceId,
    Map<String, dynamic>? data,
    required Map<String, dynamic> cookies,
    Map<String, dynamic>? headers,
  }) async {
    return getResponseObject<Map>(
      data == null ? HttpMethod.get : HttpMethod.post,
      uri,
      extraHeaders: {
        'Cookie': cookies.entries.map((e) => "${e.key}=${e.value}").join(";"),
        "Content-Type": "application/x-www-form-urlencoded",
        'User-Agent': _userAgent,
      }..addAll(headers ?? {}),
      // body: data,
      bodyFields: data,
      deserializer: (data) => data,
    );
  }

  Future<dynamic> _minaRequest({
    required String path,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
    required Map<String, dynamic> cookies,
  }) async {
    if (data != null) {
      data['requestId'] = "app_ios_${MiService.randomString(30)}";
    } else {
      queryParams ??= {};
      queryParams['requestId'] = "app_ios_${MiService.randomString(30)}";
    }
    return _miRequest(
      uri: buildXMUri(
        ssl: true,
        host: "api2.mina.mi.com",
        path: path,
        params: queryParams,
      ),
      serviceId: MiService.minaServiceId,
      data: data,
      cookies: cookies,
    );
  }

  String _signMiioNonce(String ssecurity, String nonce) {
    Digest digest = sha256.convert([
      ...base64.decode(ssecurity),
      ...base64.decode(nonce),
    ]);
    return base64.encode(digest.bytes);
  }

  Map<String, dynamic> _signMiioData(
      String path, dynamic data, String ssecurity) {
    //加空格和python的json字符串保持一致...
    String jsonData = data is String
        ? data
        : json.encode(data).replaceAll(":", ": ").replaceAll(",", ", ");
    List<int> randomBytes =
        List<int>.generate(8, (index) => Random.secure().nextInt(256));
    int timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    Uint8List timestampBytes = Uint8List(4)
      ..buffer.asByteData().setUint32(0, timestamp);
    List<int> nonce =
        base64.encode([...randomBytes, ...timestampBytes]).codeUnits;
    String snonce = _signMiioNonce(ssecurity, String.fromCharCodes(nonce));
    String msg = '$path&$snonce&${String.fromCharCodes(nonce)}&data=$jsonData';
    List<int> sign =
        Hmac(sha256, base64.decode(snonce)).convert(utf8.encode(msg)).bytes;
    String signature = base64.encode(sign);
    return {
      '_nonce': String.fromCharCodes(nonce),
      'data': jsonData,
      'signature': signature
    };
  }

  Future<dynamic> _miioRequest({
    required String path,
    required String ssecurity,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
    required Map<String, dynamic> cookies,
  }) async {
    return _miRequest(
      uri: buildXMUri(
        ssl: true,
        host: "api.io.mi.com",
        path: "/app$path",
        params: queryParams,
      ),
      headers: {
        'User-Agent':
            'iOS-14.4-6.0.103-iPhone12,3--D7744744F7AF32F0544445285880DD63E47D9BE9-8816080-84A3F44E137B71AE-iPhone',
        'x-xiaomi-protocal-flag-cli': 'PROTOCAL-HTTP2',
      },
      serviceId: MiService.miioServiceId,
      data: _signMiioData(path, data, ssecurity),
      cookies: cookies,
    );
  }

  Future<dynamic> _ubusRequest({
    required String deviceId,
    required String method,
    required String path,
    required Map<String, dynamic> message,
    required Map<String, dynamic> cookies,
  }) async {
    return _minaRequest(path: "/remote/ubus", cookies: cookies, data: {
      'deviceId': deviceId,
      'message': json.encode(message),
      'method': method,
      'path': path,
    });
  }
}
