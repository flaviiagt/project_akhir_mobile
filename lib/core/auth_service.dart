import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'api_client.dart';

class AuthService {
  static const _s = FlutterSecureStorage();
  static final _localAuth = LocalAuthentication();

  // true  = boleh memakai PIN/pola/password layar sebagai cadangan (seperti HP umumnya)
  // false = biometrik murni (sidik jari/wajah saja)
  static const allowDeviceCredential = true;

  static bool isValidEmail(String? v) =>
      v != null && RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

  static bool isValidUsername(String? v) =>
      RegExp(r'^[a-z0-9_.]{3,20}$').hasMatch((v ?? '').trim().toLowerCase());

  // ---------- Auth ----------
  static Future<void> register(
    String name,
    String username,
    String email,
    String password,
  ) async {
    await ApiClient.post('register.php', {
      'name': name,
      'username': username.toLowerCase(),
      'email': email,
      'password': password,
    });
  }

  // [identifier] boleh email ATAU username.
  static Future<Map<String, dynamic>> login(
    String identifier,
    String password,
  ) async {
    final Map<String, dynamic> r;
    try {
      r = await ApiClient.post('login.php', {
        'identifier': identifier,
        'password': password,
      });
    } on ApiException catch (e) {
      // Pesan seragam supaya tidak membocorkan apakah akun terdaftar
      if (e.statusCode == 400 || e.statusCode == 401 || e.statusCode == 404) {
        throw ApiException('Email/username atau password salah', e.statusCode);
      }
      rethrow;
    }
    await ApiClient.saveToken(r['token']);

    // Jika akun yang login berbeda dari akun biometrik, hapus data biometrik lama
    final user = r['user'] as Map<String, dynamic>;
    final bioEmail = await _s.read(key: 'bio_email');
    if (bioEmail != null &&
        bioEmail.toLowerCase() != (user['email'] as String).toLowerCase()) {
      await disableBiometric();
    }
    return user;
  }

  static Future<Map<String, dynamic>> me({bool redirect = true}) async {
    final r = await ApiClient.get('me.php', auth: true, redirect: redirect);
    return r['user'];
  }

  static Future<void> logout() => ApiClient.clearToken();

  // ---------- Biometrik ----------
  static Future<bool> biometricAvailable() async {
    if (kIsWeb) return false; // biometrik tidak tersedia di browser
    try {
      if (!await _localAuth.isDeviceSupported()) return false;
      if (allowDeviceCredential) return true; // boleh fallback ke PIN layar
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  // Nama metode sesuai perangkat: "Sidik Jari", "Face ID / Wajah", dst.
  static Future<String> biometricLabel() async {
    if (kIsWeb) return 'Biometrik';
    try {
      final t = await _localAuth.getAvailableBiometrics();
      if (t.contains(BiometricType.face)) return 'Face ID / Wajah';
      if (t.contains(BiometricType.fingerprint)) return 'Sidik Jari';
      if (t.isNotEmpty) return 'Biometrik';
    } catch (_) {}
    return 'Kunci Layar';
  }

  static Future<bool> isBiometricEnabled() async =>
      await _s.read(key: 'bio_enabled') == '1';

  static Future<bool> authenticateBiometric() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Verifikasi identitas untuk masuk ke StudyTrip',
        options: const AuthenticationOptions(
          biometricOnly: !allowDeviceCredential,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // Aktifkan biometrik: kredensial disimpan terenkripsi (Keystore/Keychain).
  static Future<bool> enableBiometric(String email, String password) async {
    if (!await authenticateBiometric()) return false;
    await _s.write(key: 'bio_enabled', value: '1');
    await _s.write(key: 'bio_email', value: email);
    await _s.write(key: 'bio_pass', value: password);
    return true;
  }

  static Future<void> disableBiometric() async {
    await _s.delete(key: 'bio_enabled');
    await _s.delete(key: 'bio_email');
    await _s.delete(key: 'bio_pass');
  }

  // Return user jika sukses, null jika biometrik dibatalkan/gagal.
  static Future<Map<String, dynamic>?> loginWithBiometric() async {
    if (!await authenticateBiometric()) return null;
    final email = await _s.read(key: 'bio_email');
    final pass = await _s.read(key: 'bio_pass');
    if (email == null || pass == null) return null;
    return login(email, pass);
  }
}
