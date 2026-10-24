import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'app_routes.dart';
import 'auth_service.dart';

// Batas tidak aktif sebelum otomatis logout.
// Untuk tes, ubah sementara jadi Duration(seconds: 20).
const kIdleTimeout = Duration(minutes: 15);
const _kLastActive = 'last_active_ms';

// Teks batas idle untuk ditampilkan di UI (mis. halaman Profil).
String get kIdleLabel => kIdleTimeout.inMinutes >= 1
    ? '${kIdleTimeout.inMinutes} menit'
    : '${kIdleTimeout.inSeconds} detik';

// Waktu logout otomatis berikutnya. Diperbarui setiap timer dipasang ulang (tiap sentuhan), dipakai untuk menampilkan hitung mundur di Profil.
DateTime idleDeadline = DateTime.now().add(kIdleTimeout);

// Dipasang di MaterialApp.builder. Logout otomatis jika tidak ada sentuhan selama [kIdleTimeout], baik saat app terbuka maupun sesudah di-background.
class IdleSessionGuard extends StatefulWidget {
  final Widget child;
  const IdleSessionGuard({super.key, required this.child});

  // Dipakai splash: true jika sudah lewat [kIdleTimeout] sejak aktivitas terakhir (termasuk saat app sempat ditutup).
  static Future<bool> isExpired() async {
    final p = await SharedPreferences.getInstance();
    final ms = p.getInt(_kLastActive);
    if (ms == null) return false;
    final last = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime.now().difference(last) >= kIdleTimeout;
  }

  @override
  State<IdleSessionGuard> createState() => _IdleSessionGuardState();
}

class _IdleSessionGuardState extends State<IdleSessionGuard>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _last = DateTime.now();
  DateTime _saved = DateTime.fromMillisecondsSinceEpoch(0);
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _arm(kIdleTimeout);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _arm(Duration after) {
    _timer?.cancel();
    _timer = Timer(after, _expire);
    idleDeadline = DateTime.now().add(after); // untuk hitung mundur di UI
  }

  void _touch() {
    final now = DateTime.now();
    _last = now;
    _arm(kIdleTimeout);
    // simpan ke penyimpanan paling sering tiap 10 detik
    if (now.difference(_saved) > const Duration(seconds: 10)) {
      _saved = now;
      SharedPreferences.getInstance().then(
        (p) => p.setInt(_kLastActive, now.millisecondsSinceEpoch),
      );
    }
  }

  // Timer bisa tertahan saat app di background, jadi cek lagi saat kembali.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final idle = DateTime.now().difference(_last);
    if (idle >= kIdleTimeout) {
      _expire();
    } else {
      _arm(kIdleTimeout - idle);
    }
  }

  Future<void> _expire() async {
    if (_busy) return;
    _busy = true;
    try {
      if (await ApiClient.token == null) return; // belum login
      await AuthService.logout();
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (r) => false,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text(
                'Sesi berakhir karena tidak ada aktivitas. Silakan login kembali.',
              ),
            ),
          );
        }
      });
    } catch (_) {
      // logout otomatis tidak boleh membuat app crash
    } finally {
      _busy = false;
      _arm(kIdleTimeout);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _touch(),
      onPointerUp: (_) => _touch(),
      child: widget.child,
    );
  }
}

// Teks hitung mundur mm:ss sampai logout otomatis.
class IdleCountdownText extends StatefulWidget {
  final TextStyle? style;
  const IdleCountdownText({super.key, this.style});

  @override
  State<IdleCountdownText> createState() => _IdleCountdownTextState();
}

class _IdleCountdownTextState extends State<IdleCountdownText> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var left = idleDeadline.difference(DateTime.now());
    if (left.isNegative) left = Duration.zero;
    final m = left.inMinutes.toString().padLeft(2, '0');
    final s = (left.inSeconds % 60).toString().padLeft(2, '0');
    return Text('$m:$s', style: widget.style);
  }
}
