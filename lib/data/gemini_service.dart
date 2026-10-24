import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

/// Service untuk menghubungkan StudyBuddy AI dengan Google Gemini API
class GeminiService {
  static final GeminiService instance = GeminiService._internal();

  GeminiService._internal();

  static const String _prefKey = 'gemini_api_key';

  GenerativeModel? _model;
  ChatSession? _chatSession;
  String? _currentApiKey;

  static const String _systemPrompt = '''
Kamu adalah StudyBuddy AI, asisten pintar dan ramah untuk mahasiswa dan pelajar Indonesia yang sedang melakukan study trip atau studi di Inggris (UK) maupun luar negeri.

Tugas dan keahlianmu:
1. Menjelaskan regulasi visa student UK (misal: batasan jam kerja part-time 20 jam/minggu saat term-time, aturan full-time saat libur resmi, larangan self-employed).
2. Panduan administrasi kesehatan seperti aktivasi NHS (National Health Service), pembayaran IHS, dan pendaftaran GP (General Practice).
3. Pengambilan BRP (Biometric Residence Permit) / eVisa dan kewajiban lapor diri ke KBRI (Peduli WNI).
4. Rekomendasi biaya hidup, akomodasi, transportasi mahasiswa (Oyster card, Student Railcard), dan tips adaptasi budaya.
5. Mengatur anggaran dan gaya hidup hemat untuk mahasiswa rantau.

Gaya jawaban:
- Gunakan Bahasa Indonesia yang ramah, santun, jelas, dan menyemangati.
- Format dengan poin-poin/bullet list yang rapi agar mudah dibaca di layar HP.
- Jika ada hal hukum/regulasi ketat, selalu sarankan untuk konfirmasi ulang ke International Student Office kampus terkait.
''';

  /// Mendapatkan API key yang aktif:
  /// 1. SharedPreferences (jika user pernah menyimpan di dialog aplikasi)
  /// 2. String.fromEnvironment / config.dart (jika di-pass via compile argument)
  /// 3. env.json via rootBundle (Flutter Asset)
  /// 4. env.json via File I/O langsung di disk (Desktop runtime)
  Future<String> getActiveApiKey() async {
    // 1. Cek SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_prefKey)?.trim();
    if (savedKey != null && savedKey.isNotEmpty) {
      return savedKey;
    }

    // 2. Cek compile-time define
    final configKey = kGeminiApiKey.trim();
    if (configKey.isNotEmpty) {
      return configKey;
    }

    // 3. Cek env.json lewat rootBundle (Asset)
    try {
      final jsonStr = await rootBundle.loadString('env.json');
      final dynamic map = jsonDecode(jsonStr);
      if (map is Map && map['GEMINI_API_KEY'] != null) {
        final key = map['GEMINI_API_KEY'].toString().trim();
        if (key.isNotEmpty) return key;
      }
    } catch (_) {}

    // 4. Cek env.json via file langsung di filesystem (Desktop Windows / Mac / Linux)
    if (!kIsWeb) {
      try {
        final f = File('env.json');
        if (f.existsSync()) {
          final content = await f.readAsString();
          final dynamic map = jsonDecode(content);
          if (map is Map && map['GEMINI_API_KEY'] != null) {
            final key = map['GEMINI_API_KEY'].toString().trim();
            if (key.isNotEmpty) return key;
          }
        }
      } catch (_) {}
    }

    return '';
  }

  /// Menyimpan API key kustom ke SharedPreferences
  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, trimmed);
    }
    // Reset session agar dibuat ulang dengan key baru
    _model = null;
    _chatSession = null;
    _currentApiKey = null;
  }

  /// Menginisialisasi session chat dengan Gemini
  Future<bool> _initChatSession() async {
    final apiKey = await getActiveApiKey();
    if (apiKey.isEmpty) {
      return false;
    }

    if (_chatSession != null && _currentApiKey == apiKey) {
      return true;
    }

    _currentApiKey = apiKey;
    _model = GenerativeModel(
      model: 'gemini-3.8-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_systemPrompt),
    );
    _chatSession = _model!.startChat();
    return true;
  }

  /// Reset percakapan chat
  void resetChat() {
    if (_model != null) {
      _chatSession = _model!.startChat();
    } else {
      _chatSession = null;
    }
  }

  /// Mengirim pesan ke Gemini dan mendapatkan jawaban
  Future<String> sendMessage(String userMessage) async {
    final hasKey = await _initChatSession();
    if (!hasKey) {
      return '⚠️ API Key Gemini belum dipasang!\n\n'
          'Silakan masukkan Gemini API Key kamu melalui ikon pengaturan ⚙️ di pojok kanan atas, atau masukkan ke file lib/config.dart.\n\n'
          'Kamu bisa mendapatkan API key gratis di: https://aistudio.google.com/';
    }

    try {
      final response = await _chatSession!.sendMessage(
        Content.text(userMessage),
      );
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return 'Maaf, Gemini tidak memberikan respon teks. Silakan coba ajukan pertanyaan lagi.';
      }
      return text;
    } on GenerativeAIException catch (e) {
      final msg = e.message;
      if (msg.contains('API_KEY_INVALID') || msg.contains('invalid API key')) {
        return '❌ API Key Gemini tidak valid. Silakan periksa kembali API Key kamu di menu pengaturan (ikon ⚙️).';
      }
      if (msg.contains('Quota exceeded') || msg.contains('RESOURCE_EXHAUSTED')) {
        return '⏳ Kuota API Gemini kamu sedang habis atau mencapai batas limit. Tunggu beberapa saat sebelum mencoba lagi.';
      }
      return 'Terjadi kendala pada Gemini AI:\n$msg';
    } catch (e) {
      return 'Gagal terhubung ke Gemini AI: $e\n\nPastikan koneksi internet kamu aktif.';
    }
  }
}
