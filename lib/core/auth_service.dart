import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../services/notification_service.dart';
import 'api_client.dart';
import 'current_user.dart';

class AuthService {
  static const _s = FlutterSecureStorage();
  static final _localAuth = LocalAuthentication();

  static bool isValidEmail(String? v) =>
      v != null && RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

  // ---------- Auth ----------
  static Future<void> register(
    String name,
    String email,
    String password,
  ) async {
    await ApiClient.post('register.php', {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final Map<String, dynamic> r;
    try {
      r = await ApiClient.post('login.php', {
        'email': email,
        'password': password,
      });
    } on ApiException catch (e) {
      // Pesan seragam supaya tidak membocorkan apakah email terdaftar
      if (e.statusCode == 400 || e.statusCode == 401 || e.statusCode == 404) {
        throw ApiException('Email atau password salah', e.statusCode);
      }
      rethrow;
    }
    await ApiClient.saveToken(r['token']);
    await CurrentUser.set(r['user']); // Anggota 2: kunci data lokal per akun

    // Jika akun yang login berbeda dari akun biometrik, hapus data biometrik lama
    final bioEmail = await _s.read(key: 'bio_email');
    if (bioEmail != null && bioEmail.toLowerCase() != email.toLowerCase()) {
      await disableBiometric();
    }
    return r['user'];
  }

  static Future<Map<String, dynamic>> me({bool redirect = true}) async {
    final r = await ApiClient.get('me.php', auth: true, redirect: redirect);
    final user = r['user'] as Map<String, dynamic>;
    await CurrentUser.set(user); // Anggota 2: kunci data lokal per akun
    return user;
  }

  static Future<void> logout() async {
    await ApiClient.clearToken();
    await CurrentUser.clear(); // Anggota 2: data lokal akun ini tidak lagi terlihat
    await NotificationService.instance.cancelAll();
  }

  // ---------- Biometrik ----------
  static Future<bool> biometricAvailable() async {
    if (kIsWeb) return false; // biometrik tidak tersedia di browser
    try {
      return await _localAuth.isDeviceSupported() &&
          await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isBiometricEnabled() async =>
      await _s.read(key: 'bio_enabled') == '1';

  static Future<bool> authenticateBiometric() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Verifikasi identitas untuk masuk ke StudyTrip',
        options: const AuthenticationOptions(
          biometricOnly: true,
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
