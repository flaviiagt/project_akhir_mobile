import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/current_user.dart';
import '../data/app_db.dart';

/// Notifikasi lokal: sambutan sesudah login + pengingat deadline checklist
/// (H-1 dan hari-H pukul 09.00, zona Asia/Jakarta).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Menyiapkan plugin. TIDAK meminta izin (lihat [requestPermission]).
  Future<void> init() async {
    if (kIsWeb || _ready) return; // notifikasi tidak didukung di browser
    try {
      const init = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(init);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
    // Zona waktu dipisah supaya kegagalannya tidak mematikan notifikasi biasa
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {}
  }

  /// Memunculkan dialog izin sistem (Android 13+ / iOS). True jika diizinkan.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await init();
    if (!_ready) return false;
    try {
      if (_android != null) {
        return await _android!.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (_) {}
    return false;
  }

  /// Apakah izin notifikasi sudah diberikan.
  Future<bool> isGranted() async {
    if (kIsWeb) return false;
    await init();
    try {
      if (_android != null) {
        return await _android!.areNotificationsEnabled() ?? false;
      }
    } catch (_) {}
    return _ready; // iOS: izin sudah ditangani di requestPermission
  }

  static const _generalDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'studytrip_general',
      'Notifikasi StudyTrip',
      channelDescription: 'Pemberitahuan umum aplikasi StudyTrip',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Menampilkan notifikasi sekarang (muncul di bar atas dan tersimpan di
  /// panel notifikasi sampai dihapus pengguna).
  Future<void> show(String title, String body) async {
    if (kIsWeb) return;
    await init();
    if (!_ready || !await isGranted()) return;
    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        _generalDetails,
      );
    } catch (_) {}
  }

  /// Dipanggil sesudah login: minta izin, lalu tampilkan sambutan.
  Future<void> welcome({String? name}) async {
    await requestPermission();
    final who = (name == null || name.trim().isEmpty) ? '' : ', ${name.trim()}';
    await show(
      'Selamat datang di StudyTrip$who',
      'Rencanakan studimu dan jangan lewatkan tenggat dokumen.',
    );
  }

  /// Batalkan semua notifikasi (dipanggil saat logout).
  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  /// Hanya membatalkan pengingat yang dijadwalkan, bukan notifikasi yang
  /// sudah tampil (supaya sambutan tidak ikut terhapus).
  Future<void> _cancelScheduled() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      await _plugin.cancel(p.id);
    }
  }

  /// Jadwalkan ulang pengingat dari checklist akun yang sedang login.
  Future<void> rescheduleAll() async {
    if (!_ready) return;
    try {
      await _cancelScheduled();
      if (CurrentUser.id == null) return; // belum login: tidak ada pengingat
      final items = await AppDb.instance.checklist();
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'deadline',
          'Pengingat Deadline',
          channelDescription: 'Pengingat deadline persiapan studi',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      for (final it in items) {
        if (it.done || it.deadline == null || it.id == null) continue;
        final d = it.deadline!;
        for (final offset in [1, 0]) {
          final when = DateTime(
            d.year,
            d.month,
            d.day,
            9,
          ).subtract(Duration(days: offset));
          if (!when.isAfter(DateTime.now())) continue;
          await _plugin.zonedSchedule(
            it.id! * 2 + offset,
            offset == 0 ? 'Deadline hari ini' : 'Deadline besok',
            it.title,
            tz.TZDateTime.from(when, tz.local),
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    } catch (_) {}
  }
}
