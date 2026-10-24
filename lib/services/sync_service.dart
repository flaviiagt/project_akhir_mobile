import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/current_user.dart';
import '../data/app_db.dart';

/// Sinkronisasi SQLite <-> Supabase. Offline-first:
/// - Semua perubahan ditulis ke SQLite dulu dan ditandai dirty.
/// - sync(): kirim baris dirty (push), lalu ambil data terbaru (pull).
/// - Konflik: perubahan dengan mtime paling baru menang. Hapus = soft delete.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  /// Kolom data per tabel (di luar user_id, rid, mtime, dirty, deleted).
  static const _cols = <String, List<String>>{
    'checklist': ['title', 'category', 'deadline', 'done'],
    'itinerary': ['day', 'time', 'title', 'location', 'note'],
    'notes': ['title', 'content', 'kind', 'updated_at'],
    'quiz_scores': ['score', 'total', 'played_at'],
  };

  bool _running = false, _again = false;
  Timer? _debounce;

  SupabaseClient? get _c {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get canSync =>
      CurrentUser.id != null && _c?.auth.currentSession != null;

  /// Dipanggil setiap ada perubahan data (ditunda sebentar agar tidak berondong).
  void requestSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), sync);
  }

  /// Kirim perubahan terakhir sebelum logout (maksimal 6 detik).
  Future<void> flush() async {
    _debounce?.cancel();
    try {
      await sync().timeout(const Duration(seconds: 6));
    } catch (_) {}
  }

  Future<void> sync() async {
    if (!canSync) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    var changed = false;
    try {
      do {
        _again = false;
        final uid = CurrentUser.id!;
        final sbUid = _c!.auth.currentUser!.id;
        for (final t in _cols.keys) {
          if (await _syncTable(t, uid, sbUid)) changed = true;
        }
        if (await _syncSettings(uid, sbUid)) changed = true;
      } while (_again);
    } catch (_) {
      // offline / error: data lokal tetap aman, dicoba lagi pada sinkron berikutnya
    } finally {
      _running = false;
    }
    if (changed) AppDb.instance.notifyChanged();
  }

  static String _iso(DateTime t) =>
      DateTime.fromMillisecondsSinceEpoch(t.millisecondsSinceEpoch, isUtc: true)
          .toIso8601String();

  Future<bool> _syncTable(String t, String uid, String sbUid) async {
    final c = _c!;
    final d = await AppDb.instance.db;
    final cols = _cols[t]!;
    var changed = false;

    // 1) PUSH baris yang berubah di perangkat ini
    final dirty = await d.query(t, where: 'user_id = ? AND dirty = 1', whereArgs: [uid]);
    if (dirty.isNotEmpty) {
      final payload = dirty
          .map((r) => <String, Object?>{
                'user_id': sbUid,
                'id': r['rid'],
                for (final k in cols) k: r[k],
                'mtime': r['mtime'],
                'deleted': r['deleted'],
              })
          .toList();
      await c.from(t).upsert(payload, onConflict: 'user_id,id');
      final b = d.batch();
      for (final r in dirty) {
        b.update(t, {'dirty': 0},
            where: 'id = ? AND mtime = ?', whereArgs: [r['id'], r['mtime']]);
      }
      await b.commit(noResult: true);
    }

    // 2) PULL: ambil data akun ini dari cloud (RLS membatasi ke pemilik)
    final remote = await c.from(t).select();
    for (final m in remote) {
      final rid = m['id'] as String;
      final rMtime = DateTime.parse(m['mtime'] as String).toUtc();
      final rDeleted = (m['deleted'] as num?)?.toInt() == 1;
      final local = await d.query(t, where: 'user_id = ? AND rid = ?', whereArgs: [uid, rid]);
      if (local.isEmpty) {
        if (rDeleted) continue;
        await d.insert(t, {
          'user_id': uid,
          'rid': rid,
          for (final k in cols) k: m[k],
          'mtime': _iso(rMtime),
          'dirty': 0,
          'deleted': 0,
        });
        changed = true;
        continue;
      }
      final lMtime = DateTime.parse(local.first['mtime'] as String).toUtc();
      if (rMtime.isAfter(lMtime)) {
        await d.update(
            t,
            {
              for (final k in cols) k: m[k],
              'mtime': _iso(rMtime),
              'dirty': 0,
              'deleted': rDeleted ? 1 : 0,
            },
            where: 'user_id = ? AND rid = ?',
            whereArgs: [uid, rid]);
        changed = true;
      }
    }
    // Baris yang sudah terhapus & tersinkron tidak perlu disimpan lagi
    await d.delete(t, where: 'user_id = ? AND deleted = 1 AND dirty = 0', whereArgs: [uid]);
    return changed;
  }

  Future<bool> _syncSettings(String uid, String sbUid) async {
    final c = _c!;
    final d = await AppDb.instance.db;
    final keys = AppDb.syncedSettings;
    final marks = List.filled(keys.length, '?').join(',');
    var changed = false;

    final dirty = await d.query('settings',
        where: 'user_id = ? AND dirty = 1 AND key IN ($marks)', whereArgs: [uid, ...keys]);
    if (dirty.isNotEmpty) {
      await c.from('user_settings').upsert([
        for (final r in dirty)
          {'user_id': sbUid, 'key': r['key'], 'value': r['value'], 'mtime': r['mtime']}
      ], onConflict: 'user_id,key');
      final b = d.batch();
      for (final r in dirty) {
        b.update('settings', {'dirty': 0},
            where: 'user_id = ? AND key = ? AND mtime = ?', whereArgs: [uid, r['key'], r['mtime']]);
      }
      await b.commit(noResult: true);
    }

    final remote = await c.from('user_settings').select();
    for (final m in remote) {
      final key = m['key'] as String;
      if (!keys.contains(key)) continue;
      final rMtime = DateTime.parse(m['mtime'] as String).toUtc();
      final local = await d.query('settings', where: 'user_id = ? AND key = ?', whereArgs: [uid, key]);
      if (local.isEmpty) {
        await d.insert('settings',
            {'user_id': uid, 'key': key, 'value': m['value'], 'mtime': _iso(rMtime), 'dirty': 0});
        changed = true;
      } else if (rMtime.isAfter(DateTime.parse(local.first['mtime'] as String).toUtc())) {
        await d.update('settings', {'value': m['value'], 'mtime': _iso(rMtime), 'dirty': 0},
            where: 'user_id = ? AND key = ?', whereArgs: [uid, key]);
        changed = true;
      }
    }
    return changed;
  }
}