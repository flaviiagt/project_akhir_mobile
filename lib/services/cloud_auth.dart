import 'package:supabase_flutter/supabase_flutter.dart';

/// Akun Supabase "bayangan" untuk akun PHP: email & password sama.
/// Dipakai supaya data di cloud terikat ke pemilik yang benar (RLS: auth.uid()).
class CloudAuth {
  static SupabaseClient? get _c {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null; // Supabase belum diinisialisasi
    }
  }

  static bool get signedIn => _c?.auth.currentSession != null;

  /// Tidak pernah melempar error: gagal = sinkron cloud dilewati saja.
  static Future<bool> signIn(String email, String password) async {
    final c = _c;
    if (c == null) return false;
    try {
      await c.auth.signInWithPassword(email: email, password: password);
      return true;
    } catch (_) {
      // Akun cloud belum ada -> buatkan.
      try {
        final r = await c.auth.signUp(email: email, password: password);
        return r.session != null; // null = "Confirm email" masih aktif di Supabase
      } catch (_) {
        return false;
      }
    }
  }

  static Future<void> signOut() async {
    try {
      await _c?.auth.signOut();
    } catch (_) {}
  }
}