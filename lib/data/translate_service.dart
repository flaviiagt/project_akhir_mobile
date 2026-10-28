import 'dart:convert';
import 'dart:typed_data';

import 'gemini_service.dart';

/// Terjemahan tulisan asing dari FOTO. Berdiri sendiri (tidak ikut riwayat
/// chat). Prompt dan API key ada di server (Edge Function `studybuddy`).
class TranslateService {
  TranslateService._();
  static final TranslateService instance = TranslateService._();

  Future<String> translateImage(
    Uint8List bytes, {
    String mimeType = 'image/jpeg',
  }) async {
    try {
      return await AiBackend.call({
        'mode': 'translate',
        'image': base64Encode(bytes),
        'mime': mimeType,
      });
    } on AiBackendException catch (e) {
      return e.code == 'empty'
          ? 'Maaf, aku tidak bisa membaca foto itu. Coba foto ulang lebih jelas.'
          : e.userMessage;
    }
  }
}
