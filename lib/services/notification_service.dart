import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, VoidCallback;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/current_user.dart';
import '../data/app_db.dart';

/// Status pengingat di HP, ditentukan oleh izin sistem DAN pilihan pengguna.
enum NotifStatus {
  unsupported, // browser: notifikasi HP tidak tersedia
  denied, // izin sistem belum diberikan / ditolak
  off, // izin ada, tetapi pengguna mematikan pengingat
  on, // izin ada dan pengingat aktif
}

/// Notifikasi lokal: pengingat deadline checklist (3 hari, 1 hari, dan hari-H
/// pukul 09.00, zona Asia/Jakarta) + sambutan sesudah login.
/// Pengingat dijadwalkan ulang otomatis setiap data berubah (checklist diubah,
/// atau data baru masuk dari cloud).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _scheduling = false, _scheduleAgain = false;
  bool _listening = false, _launchHandled = false;
  Timer? _debounce;

  /// Pengingat dikirim sekian hari sebelum deadline (0 = hari-H), pukul 09.00.
  static const reminderDays = [3, 1, 0];
  static const _hour = 9;
  static const _testId = 2147000000;

  /// Dipanggil saat notifikasi di HP diketuk (diatur di main.dart).
  VoidCallback? onTap;

  static const _kEnabled = 'notif_enabled';
  static const _kAsked = 'notif_asked';

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
      await _plugin.initialize(
        init,
        onDidReceiveNotificationResponse: (_) => onTap?.call(),
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
    // Zona waktu dipisah supaya kegagalannya tidak mematikan notifikasi biasa
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {}
    // Jadwal ikut diperbarui setiap data berubah (termasuk dari sinkron cloud)
    if (!_listening) {
      _listening = true;
      AppDb.version.addListener(_onDataChanged);
    }
  }

  void _onDataChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), rescheduleAll);
  }

  // ---------- Izin & pilihan pengguna ----------

  Future<bool> get enabled async =>
      (await SharedPreferences.getInstance()).getBool(_kEnabled) ?? true;

  Future<void> _setEnabled(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kEnabled, v);

  Future<bool> get asked async =>
      (await SharedPreferences.getInstance()).getBool(_kAsked) ?? false;

  /// Memunculkan dialog izin sistem (Android 13+ / iOS). True jika diizinkan.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await init();
    if (!_ready) return false;
    (await SharedPreferences.getInstance()).setBool(_kAsked, true);
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

  /// Apakah izin notifikasi sistem sudah diberikan.
  Future<bool> isGranted() async {
    if (kIsWeb) return false;
    await init();
    try {
      if (_android != null) {
        return await _android!.areNotificationsEnabled() ?? false;
      }
    } catch (_) {}
    return _ready; // iOS: izin ditangani di requestPermission
  }

  Future<NotifStatus> status() async {
    if (kIsWeb) return NotifStatus.unsupported;
    if (!await isGranted()) return NotifStatus.denied;
    return (await enabled) ? NotifStatus.on : NotifStatus.off;
  }

  /// Dipakai tombol di halaman notifikasi. Menyalakan = meminta izin bila perlu.
  Future<NotifStatus> setReminders(bool want) async {
    if (kIsWeb) return NotifStatus.unsupported;
    if (want) {
      var ok = await isGranted();
      if (!ok) ok = await requestPermission();
      if (!ok) return NotifStatus.denied;
      await _setEnabled(true);
    } else {
      await _setEnabled(false);
    }
    await rescheduleAll();
    return status();
  }

  // ---------- Tampil sekarang ----------

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

  /// Menampilkan notifikasi sekarang (bar atas HP + panel notifikasi).
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
        payload: 'general',
      );
    } catch (_) {}
  }

  /// Dipanggil sesudah login: minta izin sistem bila belum aktif, lalu sambutan.
  Future<void> welcome({String? name}) async {
    if (!kIsWeb && !await isGranted()) await requestPermission();
    final who = (name == null || name.trim().isEmpty) ? '' : ', ${name.trim()}';
    await show(
      'Selamat datang di StudyTrip$who',
      'Rencanakan studimu dan jangan lewatkan tenggat dokumen.',
    );
    await rescheduleAll();
  }

  /// Untuk demo: pengingat percobaan yang muncul 1 menit lagi, juga saat
  /// aplikasi ditutup. False jika izin belum ada / tidak didukung.
  Future<bool> scheduleTest() async {
    if (kIsWeb) return false;
    await init();
    if (!_ready || !await isGranted()) return false;
    try {
      await _plugin.zonedSchedule(
        _testId,
        'Tes pengingat StudyTrip',
        'Notifikasi terjadwal ini muncul walau aplikasi ditutup.',
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1)),
        _deadlineDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'deadline',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Jumlah pengingat yang terjadwal di HP (tidak termasuk tes).
  Future<int> pendingCount() async {
    if (kIsWeb) return 0;
    await init();
    if (!_ready) return 0;
    try {
      final p = await _plugin.pendingNotificationRequests();
      return p.where((e) => e.id != _testId).length;
    } catch (_) {
      return 0;
    }
  }

  /// True sekali saja jika aplikasi dibuka dengan mengetuk notifikasi.
  Future<bool> launchedFromNotification() async {
    if (kIsWeb || _launchHandled) return false;
    _launchHandled = true;
    await init();
    try {
      final d = await _plugin.getNotificationAppLaunchDetails();
      return d?.didNotificationLaunchApp ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Batalkan semua notifikasi (dipanggil saat logout).
  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  /// Hanya membatalkan pengingat terjadwal (bukan yang sudah tampil).
  Future<void> _cancelScheduled() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id == _testId) continue;
      await _plugin.cancel(p.id);
    }
  }

  // ---------- Pengingat deadline ----------

  static const _deadlineDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'deadline',
      'Pengingat Deadline',
      channelDescription: 'Pengingat deadline persiapan studi',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static String _titleFor(int offset) => offset == 0
      ? 'Deadline hari ini'
      : offset == 1
      ? 'Deadline besok'
      : 'Deadline $offset hari lagi';

  /// Jadwalkan ulang pengingat dari checklist akun yang sedang login.
  /// Hanya berjalan jika izin sistem ada DAN pengingat diaktifkan pengguna.
  Future<void> rescheduleAll() async {
    if (kIsWeb) return;
    if (_scheduling) {
      _scheduleAgain = true;
      return;
    }
    _scheduling = true;
    try {
      do {
        _scheduleAgain = false;
        await _doReschedule();
      } while (_scheduleAgain);
    } catch (_) {
      // penjadwalan tidak boleh mengganggu aplikasi
    } finally {
      _scheduling = false;
    }
  }

  Future<void> _doReschedule() async {
    await init();
    if (!_ready) return;
    await _cancelScheduled();
    if (CurrentUser.id == null) return; // belum login: tidak ada pengingat
    if (!await enabled || !await isGranted()) return;

    final items = await AppDb.instance.checklist();
    for (final it in items) {
      if (it.done || it.deadline == null || it.id == null) continue;
      final d = it.deadline!;
      for (final offset in reminderDays) {
        final when = DateTime(
          d.year,
          d.month,
          d.day,
          _hour,
        ).subtract(Duration(days: offset));
        if (!when.isAfter(DateTime.now())) continue;
        await _plugin.zonedSchedule(
          it.id! * 10 + offset,
          _titleFor(offset),
          '${it.title} (${it.category})',
          tz.TZDateTime.from(when, tz.local),
          _deadlineDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'deadline',
        );
      }
    }
  }
}
