import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'api_client.dart';
import '../services/cloud_auth.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';
import 'current_user.dart';
import 'profile_store.dart';
import '../widgets/studybuddy_ai_card.dart';

class AuthService {
  static const _s = FlutterSecureStorage();
  static final _localAuth = LocalAuthentication();

  // true  = boleh memakai PIN/pola/password layar sebagai cadangan (seperti HP umumnya)
  // false = biometrik murni (sidik jari)
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

  // [identifier] boleh email atau username.
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
      // Tidak ada koneksi -> coba verifikasi offline
      if (e.statusCode == 0) {
        final offlineUser = await _loginOffline(identifier, password);
        if (offlineUser != null) return {...offlineUser, 'offline': true};
        throw ApiException(
          'Tidak ada koneksi. Login offline hanya bisa untuk akun yang pernah login di HP ini.',
          0,
        );
      }
      // Pesan seragam supaya tidak membocorkan apakah akun terdaftar
      if (e.statusCode == 400 || e.statusCode == 401 || e.statusCode == 404) {
        throw ApiException('Email/username atau password salah', e.statusCode);
      }
      rethrow;
    }
    await ApiClient.saveToken(r['token']);
    final user = r['user'] as Map<String, dynamic>;
    await CurrentUser.set(user); // Anggota 2: kunci data lokal per akun
    await _cacheUser(user); // profil untuk mode offline
    await _saveOffline(user, password); // simpan untuk login offline
    // Cloud: masuk ke Supabase dengan email akun (login boleh pakai username),
    // lalu sinkron. Tidak pernah melempar error.
    await CloudAuth.signIn(
      (user['email'] as String).trim().toLowerCase(),
      password,
    );
    SyncService.instance.requestSync();

    // Jika akun yang login berbeda dari akun biometrik, hapus data biometrik lama
    final bioEmail = await _s.read(key: 'bio_email');
    if (bioEmail != null &&
        bioEmail.toLowerCase() != (user['email'] as String).toLowerCase()) {
      await disableBiometric();
    }
    return user;
  }

  static Future<Map<String, dynamic>> me({bool redirect = true}) async {
    try {
      final r = await ApiClient.get('me.php', auth: true, redirect: redirect);
      final user = r['user'] as Map<String, dynamic>;
      await CurrentUser.set(user); // Anggota 2: kunci data lokal per akun
      await _cacheUser(user); // simpan untuk dipakai saat offline
      SyncService.instance.requestSync();
      return user;
    } on ApiException catch (e) {
      // Offline atau server bermasalah: pakai profil tersimpan kalau ada
      if (e.statusCode == 0 || e.statusCode >= 500) {
        final cached = await cachedUser();
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  static Future<void> logout() async {
    await SyncService.instance.flush(); // kirim perubahan terakhir ke cloud
    await ApiClient.clearToken();
    ProfileStore.clear(); // foto/nama akun ini tidak lagi tampil
    await StudyBuddyFloating.reset(); // riwayat chat StudyBuddy akun ini dihapus
    await CurrentUser.clear(); // data lokal akun ini tidak lagi terlihat
    await CloudAuth.signOut();
    await NotificationService.instance.cancelAll();
  }

  // ---------- Cache profil (untuk mode offline) ----------
  static String? _cacheKey() {
    final id = CurrentUser.id;
    return id == null ? null : 'cached_user_$id';
  }

  static Future<void> _cacheUser(Map<String, dynamic> user) async {
    final k = _cacheKey();
    if (k == null) return;
    await _s.write(key: k, value: jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> cachedUser() async {
    final k = _cacheKey();
    if (k == null) return null;
    final raw = await _s.read(key: k);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  // ---------- Login offline ----------
  // Yang disimpan hanya hash PBKDF2 + salt acak, bukan password asli.
  static String _pbkdf2(String pass, List<int> salt, {int iter = 10000}) {
    final hmac = Hmac(sha256, utf8.encode(pass));
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final t = List<int>.from(u);
    for (var i = 1; i < iter; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    return base64.encode(t);
  }

  static Future<void> _saveOffline(
    Map<String, dynamic> user,
    String password,
  ) async {
    final rnd = Random.secure();
    final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
    final data = jsonEncode({
      'salt': base64.encode(salt),
      'hash': _pbkdf2(password, salt),
      'user': user,
    });
    // Disimpan di bawah email DAN username supaya keduanya bisa dipakai login
    final keys = <String>{
      (user['email'] as String).toLowerCase(),
      if (user['username'] != null) (user['username'] as String).toLowerCase(),
    };
    for (final k in keys) {
      await _s.write(key: 'offline_$k', value: data);
    }
  }

  static Future<Map<String, dynamic>?> _loginOffline(
    String identifier,
    String password,
  ) async {
    final raw = await _s.read(
      key: 'offline_${identifier.trim().toLowerCase()}',
    );
    if (raw == null) return null;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    final salt = base64.decode(m['salt'] as String);
    if (_pbkdf2(password, salt) != m['hash']) return null;
    final user = Map<String, dynamic>.from(m['user'] as Map);
    await CurrentUser.set(user);
    return user;
  }

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