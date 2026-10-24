import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
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
  // URL server. Bisa diganti tanpa edit kode lewat:
  //   flutter run --dart-define=API_BASE=https://xxxx/studytrip_api
  static const _base = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://studytrip.free.je/studytrip_api',
  );
  static String get baseUrl => _base;

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'token';

  static Future<String?> get token => _storage.read(key: _tokenKey);
  static Future<void> saveToken(String t) =>
      _storage.write(key: _tokenKey, value: t);
  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

  static String? fileUrl(String? path) =>
      (path == null || path.isEmpty) ? null : '$baseUrl/$path';

  // ---- Tantangan anti-bot hosting gratis (aes.js) ----
  static String? _antiBotCookie;

  static bool _isChallenge(String body) =>
      body.contains('/aes.js') && body.contains('toNumbers(');

  static List<int> _hexToBytes(String h) => [
    for (var i = 0; i < h.length; i += 2)
      int.parse(h.substring(i, i + 2), radix: 16),
  ];

  static bool _solveChallenge(String body) {
    try {
      final m = RegExp(r'toNumbers\("([0-9a-fA-F]+)"\)')
          .allMatches(body)
          .toList();
      if (m.length < 3) return false;
      final a = _hexToBytes(m[0].group(1)!);
      final b = _hexToBytes(m[1].group(1)!);
      final c = _hexToBytes(m[2].group(1)!);
      final aes = enc.Encrypter(
        enc.AES(
          enc.Key(Uint8List.fromList(a)),
          mode: enc.AESMode.cbc,
          padding: null,
        ),
      );
      final out = aes.decryptBytes(
        enc.Encrypted(Uint8List.fromList(c)),
        iv: enc.IV(Uint8List.fromList(b)),
      );
      _antiBotCookie = out
          .map((x) => x.toRadixString(16).padLeft(2, '0'))
          .join();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Uri _uri(String path) {
    final u = '$baseUrl/$path';
    if (_antiBotCookie == null) return Uri.parse(u);
    return Uri.parse(u.contains('?') ? '$u&i=1' : '$u?i=1');
  }

  /// Header untuk Image.network (foto profil) supaya lolos tantangan yang sama.
  static Map<String, String> get imageHeaders =>
      _antiBotCookie == null ? const {} : {'Cookie': '__test=$_antiBotCookie'};
  // -----------------------------------------------------

  static Future<Map<String, String>> _headers(bool auth) async {
    final h = {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    if (_antiBotCookie != null) h['Cookie'] = '__test=$_antiBotCookie';
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
      // Kena tantangan anti-bot? Selesaikan, lalu kirim ulang sekali.
      if (_isChallenge(r.body) && _solveChallenge(r.body)) {
        r = await request().timeout(const Duration(seconds: 15));
      }
    } catch (_) {
      throw ApiException('Tidak dapat terhubung ke server', 0);
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      final b = r.body;
      throw ApiException(
        'Respon tidak valid: ${b.substring(0, b.length > 200 ? 200 : b.length)}',
        r.statusCode,
      );
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
          _uri(path),
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
        return http.get(_uri(path), headers: await _headers(auth));
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
      final req = http.MultipartRequest('POST', _uri(path));
      req.headers['Authorization'] = 'Bearer ${await token}';
      req.headers['ngrok-skip-browser-warning'] = 'true';
      if (_antiBotCookie != null) {
        req.headers['Cookie'] = '__test=$_antiBotCookie';
      }
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
