// core/network/http_client.dart
import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:http/http.dart' as http;
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/services/session_expired_handler.dart';

class AppHttpClient {
  static final CookieJar _cookieJar = CookieJar();
  static final http.Client _client = http.Client();

  static Future<http.Response> get(String url) async {
    final uri = Uri.parse(url);

    final cookies = await _cookieJar.loadForRequest(uri);
    final cookieHeader = cookies.map((c) => '${c.name}=${c.value}').join('; ');

    print('🌐 REQUEST URL: $url');
    print('🍪 SENDING COOKIES: $cookieHeader');

    final response = await _client.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${PrefUtils.getToken()}",
        if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
      },
    );

    print('📥 RESPONSE STATUS: ${response.statusCode}');
    print('📥 RESPONSE SET-COOKIE: ${response.headers['set-cookie']}');

    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      final cookie = Cookie.fromSetCookieValue(setCookie);
      await _cookieJar.saveFromResponse(uri, [cookie]);
      print('✅ COOKIE SAVED: ${cookie.name}=${cookie.value}');
    }

    await SessionExpiredHandler.handleIfUnauthorized(response.statusCode);
    return response;
  }

  static Future<http.Response> post(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(url);

    
    final cookies = await _cookieJar.loadForRequest(uri);
    final cookieHeader = cookies.map((c) => '${c.name}=${c.value}').join('; ');

    
    print('🌐 REQUEST URL: $url');
    print('🍪 SENDING COOKIES: $cookieHeader');

    final response = await _client.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${PrefUtils.getToken()}",
        if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
      },
      body: jsonEncode(body),
    );


    print('📥 RESPONSE STATUS: ${response.statusCode}');
    print('📥 RESPONSE SET-COOKIE: ${response.headers['set-cookie']}');


    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      final cookie = Cookie.fromSetCookieValue(setCookie);
      await _cookieJar.saveFromResponse(uri, [cookie]);
      print('✅ COOKIE SAVED: ${cookie.name}=${cookie.value}');
    }

    await SessionExpiredHandler.handleIfUnauthorized(response.statusCode);
    return response;
  }

  /// DELETE with JSON body (same headers/cookies as [post]).
  static Future<http.Response> delete(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(url);

    final cookies = await _cookieJar.loadForRequest(uri);
    final cookieHeader = cookies.map((c) => '${c.name}=${c.value}').join('; ');

    print('🌐 REQUEST URL: $url (DELETE)');
    print('🍪 SENDING COOKIES: $cookieHeader');

    final response = await _client.delete(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${PrefUtils.getToken()}",
        if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
      },
      body: body == null ? null : jsonEncode(body),
    );

    print('📥 RESPONSE STATUS: ${response.statusCode}');

    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      final cookie = Cookie.fromSetCookieValue(setCookie);
      await _cookieJar.saveFromResponse(uri, [cookie]);
      print('✅ COOKIE SAVED: ${cookie.name}=${cookie.value}');
    }

    await SessionExpiredHandler.handleIfUnauthorized(response.statusCode);
    return response;
  }
}
