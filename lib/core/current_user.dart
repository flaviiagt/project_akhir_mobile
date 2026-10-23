import 'package:shared_preferences/shared_preferences.dart';

/// Akun yang sedang login. Semua data lokal (checklist, itinerary, catatan,
/// skor quiz, pengaturan) difilter dengan kunci ini, jadi akun A dan B
/// tidak pernah saling melihat data.
class CurrentUser {
  CurrentUser._();
  static const _prefKey = 'current_user_key';
  static String? _id;

  /// Kunci akun (id dari server, atau email jika id tidak ada). Null = belum login.
  static String? get id => _id;

  /// Dipanggil sekali saat aplikasi dibuka, supaya mode offline tetap
  /// tahu siapa pemilik data lokal (lihat splash_page.dart).
  static Future<void> restore() async {
    try {
      final p = await SharedPreferences.getInstance();
      _id = p.getString(_prefKey);
    } catch (_) {
      _id = null;
    }
  }

  /// Dipanggil setelah login atau me() berhasil. [user] = map 'user' dari server.
  static Future<void> set(Map<String, dynamic> user) async {
    final raw = user['id'] ?? user['user_id'] ?? user['email'];
    final key = raw?.toString().trim().toLowerCase() ?? '';
    if (key.isEmpty) return;
    _id = key;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_prefKey, key);
    } catch (_) {}
  }

  static Future<void> clear() async {
    _id = null;
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_prefKey);
    } catch (_) {}
  }
}
