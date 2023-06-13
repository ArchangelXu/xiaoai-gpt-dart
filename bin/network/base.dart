import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:pretty_json/pretty_json.dart';

import '../utils/logger.dart';

//顶层变量
Network network = Network._internal();

enum HttpMethod { get, post, put, delete, patch }

class Network {
  /// 顶层变量，单例模式
  Network._internal() {
    _prepareHttpClient();
  }

  final HtmlUnescape _unescaper = HtmlUnescape();

  late final http.Client _client;

  Uri buildXMUri({
    required bool ssl,
    required String host,
    required String path,
    Map<String, dynamic>? params,
  }) {
    var queryParameters =
        params?.map((key, value) => MapEntry(key, value.toString()));
    return ssl
        ? Uri.https(host, path, queryParameters)
        : Uri.http(host, path, queryParameters);
  }

  Future<M> getResponseObject<M>(
    HttpMethod method,
    Uri uri, {
    Map<String, dynamic>? extraHeaders,
    Map<String, dynamic>? body,
    Map<String, dynamic>? bodyFields,
    M Function(Map<String, dynamic> data)? deserializer,
    M Function(String raw)? rawDeserializer,
  }) async {
    extraHeaders ??= {};
    dynamic data;
    try {
      data = await _getRawResponse(
        method,
        uri,
        extraHeaders: extraHeaders,
        body: body,
        bodyFields: bodyFields,
      );
    } catch (e) {
      data = e;
    }
    if (data is Exception) {
      return Future.error(data);
    } else {
      if (deserializer == null && rawDeserializer == null) {
        return Future.value(null);
      }
      if (data is Map<String, dynamic>) {
        return Future.value(deserializer?.call(data));
      } else if (data is String) {
        return Future.value(rawDeserializer?.call(data));
      } else {
        return Future.value(null);
      }
    }
  }

  Future<Map<String, dynamic>?> getResponseHeaders(
    HttpMethod method,
    Uri uri,
  ) async {
    try {
      Completer<Map<String, dynamic>> completer = Completer();
      _getRawResponse(
        method,
        uri,
        onResponseHeaders: (headers) {
          completer.complete(headers);
        },
      );
      return completer.future;
    } catch (e) {
      logger.w(e);
      return null;
    }
  }

  Future<dynamic> _getRawResponse<M>(
    HttpMethod method,
    Uri uri, {
    Map<String, dynamic>? extraHeaders,
    Map<String, dynamic>? body,
    Map<String, dynamic>? bodyFields,
    Function(Map<String, dynamic> headers)? onResponseHeaders,
    int redirectCount = 0,
  }) async {
    int id = Random().nextInt(10000);
    _logRequest(id, method, uri, body, bodyFields, extraHeaders: extraHeaders);
    http.StreamedResponse response;
    late String responseBody;
    try {
      http.Request request = http.Request(method.name, uri);
      request.followRedirects = true;
      if (extraHeaders != null) {
        request.headers.addAll(
          extraHeaders.map((key, value) => MapEntry(key, value.toString())),
        );
      }
      if (body != null) {
        request.body = json.encode(body);
      }
      if (bodyFields != null) {
        request.bodyFields =
            bodyFields.map((key, value) => MapEntry(key, value.toString()));
      }
      response = (await _client.send(request));
      responseBody = await response.stream.bytesToString();
      onResponseHeaders?.call(response.headers);
    } catch (e) {
      logger.w(e);
      rethrow;
    }
    dynamic returnedJson;
    try {
      if (responseBody.isNotEmpty) {
        returnedJson = jsonDecode(responseBody);
      }
    } catch (e) {
      if (e is! FormatException) {
        logger.w(e.toString());
      }
    }
    try {
      _logResponse(id, response.statusCode, responseBody, returnedJson);
    } catch (e) {
      logger.w(e.toString());
    }
    if (response.statusCode >= 200 && response.statusCode < 400) {
      if (response.statusCode == 301 || response.statusCode == 302) {
        //redirect
        if (redirectCount >= 5) {
          logger.d("response=${response.reasonPhrase}");
          logger.d("<too many redirects>");
          return null;
        } else {
          String newUrl = responseBody;
          newUrl = newUrl
              .substring(newUrl.indexOf('<a href="') + '<a href="'.length);

          newUrl = newUrl.substring(0, newUrl.indexOf('">here'));
          newUrl = _unescaper.convert(newUrl);
          return _getRawResponse(method, Uri.parse(newUrl),
              extraHeaders: extraHeaders,
              body: body,
              bodyFields: bodyFields,
              redirectCount: redirectCount + 1);
        }
      } else {
        return returnedJson ?? responseBody;
      }
    } else {
      //failed
      logger.d("response=${response.reasonPhrase}");
      return returnedJson;
    }
  }

  void _logResponse(int id, int statusCode, String body, dynamic returnedJson) {
    if (returnedJson == null) {
      logger.d("[RESPONSE $id] HTTP $statusCode\nresponse=$body");
    } else {
      logger.d(
        "[RESPONSE $id] HTTP $statusCode\njson=${returnedJson == null ? "null" : prettyJson(returnedJson)}",
      );
    }
  }

  void _logRequest(
    int id,
    HttpMethod method,
    Uri uri,
    Map<String, dynamic>? body,
    Map<String, dynamic>? bodyFields, {
    Map<String, dynamic>? extraHeaders,
  }) {
    logger.d(
      "[REQUEST  $id] ${method.name.toUpperCase()} url=${uri.toString()},\n"
      " query:${"\n" + prettyJson(uri.queryParameters)},\n"
      " headers:${extraHeaders == null ? "null" : prettyJson(extraHeaders)},\n"
      " body:${body == null ? "null" : ("\n" + prettyJson(body))},\n"
      " bodyFields:${bodyFields == null ? "null" : ("\n" + prettyJson(bodyFields))}",
    );
  }

  void _prepareHttpClient() {
    _client = http.Client();
  }
}
