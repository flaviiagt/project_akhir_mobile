import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'current_user.dart';
import 'user_events.dart';

/// Satu sumber data profil (nama + foto) untuk semua tab, supaya foto di
/// app bar selalu sama dengan di halaman Profil. Dimuat dari me.php satu kali,
/// lalu dimuat ulang otomatis saat [profileVersion] naik (setelah edit profil).
class ProfileStore {
  ProfileStore._();
  static final ValueNotifier<Map<String, dynamic>?> user =
      ValueNotifier<Map<String, dynamic>?>(null);
  static String? _forKey;
  static int _stamp = DateTime.now().millisecondsSinceEpoch;
  static Future<void>? _loading;
  static bool _listening = false;

  /// URL foto (dengan penanda versi agar foto baru tidak tertahan cache).
  static String? get photoUrl {
    final base = ApiClient.fileUrl(user.value?['photo'] as String?);
    return base == null ? null : '$base?v=$_stamp';
  }

  static String get name => (user.value?['name'] as String?)?.trim() ?? '';

  static Future<void> load({bool force = false}) {
    if (!_listening) {
      _listening = true;
      profileVersion.addListener(() => load(force: true));
    }
    final key = CurrentUser.id;
    if (key == null) {
      clear();
      return Future.value();
    }
    if (_forKey != key) {
      // akun berganti: jangan tampilkan foto akun sebelumnya
      user.value = null;
      _forKey = null;
    }
    if (force) {
      final prev = _loading ?? Future<void>.value();
      return _loading = prev.then((_) => _fetch(key)).whenComplete(() => _loading = null);
    }
    if (user.value != null) return Future.value();
    return _loading ??= _fetch(key).whenComplete(() => _loading = null);
  }

  static Future<void> _fetch(String key) async {
    try {
      final r = await ApiClient.get('me.php', auth: true, redirect: false);
      if (CurrentUser.id != key) return; // akun berganti saat memuat
      final u = r['user'];
      if (u is Map) {
        _forKey = key;
        _stamp = DateTime.now().millisecondsSinceEpoch;
        user.value = Map<String, dynamic>.from(u);
      }
    } catch (_) {
      // offline / gagal: pakai tampilan bawaan
    }
  }

  static void clear() {
    _forKey = null;
    _loading = null;
    user.value = null;
  }
}
