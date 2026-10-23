import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../core/current_user.dart';
import '../data/app_db.dart';

/// Pengingat deadline checklist: H-1 dan hari-H pukul 09.00 (zona Asia/Jakarta).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      const init = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(init);
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (_) {
      _ready = false; // aplikasi tetap jalan tanpa notifikasi
    }
  }

  /// Batalkan semua pengingat (dipanggil saat logout).
  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  /// Jadwalkan ulang pengingat dari checklist akun yang sedang login.
  Future<void> rescheduleAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
    if (CurrentUser.id == null) return; // belum login: tidak ada pengingat
    final items = await AppDb.instance.checklist();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'deadline', 'Pengingat Deadline',
        channelDescription: 'Pengingat deadline persiapan studi',
        importance: Importance.high, priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    for (final it in items) {
      if (it.done || it.deadline == null || it.id == null) continue;
      final d = it.deadline!;
      for (final offset in [1, 0]) {
        final when = DateTime(d.year, d.month, d.day, 9).subtract(Duration(days: offset));
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
  }
}
