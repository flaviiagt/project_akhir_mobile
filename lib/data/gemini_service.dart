import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/current_user.dart';

/// Gagal memanggil backend AI. [code] sama dengan kode error Edge Function
/// `studybuddy` (auth, rate_limit, busy, quota, denied, unavailable, empty)
/// ditambah `network` untuk masalah koneksi.
class AiBackendException implements Exception {
  final String code;

  /// Penyebab teknis (untuk diagnosis); hanya ditampilkan pada kode `unknown`.
  final String? detail;
  const AiBackendException(this.code, {this.detail});

  /// Pesan ramah untuk pengguna.
  String get userMessage => switch (code) {
        'auth' =>
          'Fitur AI membutuhkan akun yang tersambung ke cloud. Coba keluar lalu masuk lagi saat internet aktif.',
        'rate_limit' =>
          'Kamu sudah banyak bertanya dalam satu jam terakhir. Coba lagi nanti ya.',
        'busy' => '⏳ Server AI sedang sibuk. Coba kirim ulang beberapa saat lagi ya.',
        'quota' => '⏳ Layanan AI sedang penuh. Coba lagi beberapa saat lagi.',
        'empty' => 'Maaf, StudyBuddy tidak memberikan jawaban. Coba ajukan pertanyaan lagi.',
        'network' =>
          'Gagal terhubung ke StudyBuddy. Pastikan koneksi internet kamu aktif.',
        'timeout' => '⏳ StudyBuddy terlalu lama menjawab. Coba kirim ulang sebentar lagi.',
        'unknown' => 'Terjadi kendala di aplikasi. Detail: ${detail ?? '-'}',
        _ => 'Layanan AI sedang bermasalah. Coba lagi nanti.',
      };

  @override
  String toString() => 'AiBackendException($code)';
}

/// Pintu tunggal ke Edge Function `studybuddy` di Supabase. API key Gemini
/// hanya ada di server (secret Supabase), pengguna tidak perlu memasukkan apa pun.
class AiBackend {
  AiBackend._();

  static Future<String> call(Map<String, Object?> body) async {
    final SupabaseClient client;
    try {
      client = Supabase.instance.client;
    } catch (_) {
      throw const AiBackendException('unavailable'); // Supabase belum diinisialisasi
    }
    if (client.auth.currentSession == null) throw const AiBackendException('auth');

    try {
      final res = await client.functions
          .invoke('studybuddy', body: body)
          .timeout(const Duration(seconds: 60));
      final data = res.data;
      if (data is Map) {
        final text = data['text'];
        if (text is String && text.isNotEmpty) return text;
        if (data['error'] != null) throw AiBackendException(data['error'].toString());
      }
      throw const AiBackendException('unavailable');
    } on AiBackendException {
      rethrow;
    } on FunctionException catch (e) {
      final d = e.details;
      if (d is Map && d['error'] != null) throw AiBackendException(d['error'].toString());
      throw AiBackendException(e.status == 401 ? 'auth' : 'unavailable');
    } on TimeoutException {
      throw const AiBackendException('timeout');
    } on AuthException {
      throw const AiBackendException('auth');
    } catch (e) {
      // Jangan menyamarkan semua error sebagai "masalah internet".
      debugPrint('AiBackend error: ${e.runtimeType}: $e');
      final t = e.toString();
      final isNet = t.contains('SocketException') ||
          t.contains('ClientException') ||
          t.contains('Failed host lookup') ||
          t.contains('Connection') ||
          t.contains('XMLHttpRequest');
      throw AiBackendException(
        isNet ? 'network' : 'unknown',
        detail: '${e.runtimeType}: ${t.length > 140 ? t.substring(0, 140) : t}',
      );
    }
  }
}

/// Chat StudyBuddy AI. Riwayat percakapan disimpan di aplikasi dan dikirim
/// ulang setiap pesan (backend tidak menyimpan percakapan).
class GeminiService {
  static final GeminiService instance = GeminiService._internal();
  GeminiService._internal();

  static const _maxHistory = 20; // 10 tanya-jawab terakhir
  final List<Map<String, String>> _history = [];
  String? _owner;
  bool _restored = false;

  String get _key => 'studybuddy_history_${CurrentUser.id ?? 'anon'}';

  /// Muat riwayat akun yang sedang login (sekali per akun).
  Future<void> _restore() async {
    final owner = CurrentUser.id;
    if (_restored && _owner == owner) return;
    _restored = true;
    _owner = owner;
    _history.clear();
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null) {
        for (final e in jsonDecode(raw) as List) {
          _history.add({'role': e['role'] as String, 'text': e['text'] as String});
        }
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(_history));
    } catch (_) {}
  }

  /// Reset percakapan chat (juga menghapus yang tersimpan).
  void resetChat() {
    _history.clear();
    SharedPreferences.getInstance().then((p) => p.remove(_key)).catchError((_) => false);
  }

  /// Mengirim pesan dan mengembalikan jawaban (atau pesan error yang ramah).
  Future<String> sendMessage(String userMessage) async {
    await _restore();
    final turns = [
      ..._history,
      {'role': 'user', 'text': userMessage},
    ];
    try {
      final answer = await AiBackend.call({
        'mode': 'chat',
        'messages': turns.length > _maxHistory
            ? turns.sublist(turns.length - _maxHistory)
            : turns,
      });
      _history
        ..add({'role': 'user', 'text': userMessage})
        ..add({'role': 'model', 'text': answer});
      while (_history.length > _maxHistory) {
        _history.removeAt(0);
      }
      await _persist();
      return answer;
    } on AiBackendException catch (e) {
      return e.userMessage;
    }
  }
}
