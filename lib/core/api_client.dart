import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'app_routes.dart';
import 'current_user.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, [this.statusCode = 0]);
  @override
  String toString() => message;
}

class ApiClient {
  // Chrome (web)     : http://localhost/studytrip_api
  // Emulator Android : http://10.0.2.2/studytrip_api
  // HP asli (1 WiFi) : http://192.168.100.134/studytrip_api  (cek IP dengan `ipconfig`)
  static String get baseUrl => kIsWeb
      ? 'http://localhost/studytrip_api'
      : 'http://192.168.100.134/studytrip_api';

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'token';

  static Future<String?> get token => _storage.read(key: _tokenKey);
  static Future<void> saveToken(String t) =>
      _storage.write(key: _tokenKey, value: t);
  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

  static String? fileUrl(String? path) =>
      (path == null || path.isEmpty) ? null : '$baseUrl/$path';

  static Future<Map<String, String>> _headers(bool auth) async {
    final h = {'Content-Type': 'application/json'};
    if (auth) {
      final t = await token;
      if (t != null) h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  static Future<Map<String, dynamic>> _handle(
    Future<http.Response> Function() request, {
    bool auth = false,
    bool redirect = true,
  }) async {
    http.Response r;
    try {
      r = await request().timeout(const Duration(seconds: 15));
    } catch (_) {
      throw ApiException('Tidak dapat terhubung ke server', 0);
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Respon server tidak valid', r.statusCode);
    }

    // Token kedaluwarsa / tidak valid -> kembali ke login
    if (r.statusCode == 401 && auth) {
      await clearToken();
      await CurrentUser.clear();
      if (redirect) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
      throw ApiException('Sesi berakhir, silakan login kembali', 401);
    }

    if (data['success'] != true) {
      throw ApiException(data['message'] ?? 'Terjadi kesalahan', r.statusCode);
    }
    return data;
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
    bool redirect = true,
  }) {
    return _handle(
      () async {
        return http.post(
          Uri.parse('$baseUrl/$path'),
          headers: await _headers(auth),
          body: jsonEncode(body),
        );
      },
      auth: auth,
      redirect: redirect,
    );
  }

  static Future<Map<String, dynamic>> get(
    String path, {
    bool auth = false,
    bool redirect = true,
  }) {
    return _handle(
      () async {
        return http.get(
          Uri.parse('$baseUrl/$path'),
          headers: await _headers(auth),
        );
      },
      auth: auth,
      redirect: redirect,
    );
  }

  static MediaType _mediaType(String filename) {
    switch (filename.split('.').last.toLowerCase()) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('image', 'jpeg');
    }
  }

  // Upload memakai bytes agar jalan di Android maupun Chrome (tanpa dart:io)
  static Future<Map<String, dynamic>> uploadBytes(
    String path,
    String field,
    List<int> bytes,
    String filename,
  ) {
    return _handle(() async {
      final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/$path'));
      req.headers['Authorization'] = 'Bearer ${await token}';
      req.files.add(
        http.MultipartFile.fromBytes(
          field,
          bytes,
          filename: filename,
          contentType: _mediaType(filename),
        ),
      );
      return http.Response.fromStream(await req.send());
    }, auth: true);
  }
}
