import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/chain_config.dart';
import '../core/current_user.dart';
import '../data/app_db.dart';
import '../data/models.dart';

class ChainException implements Exception {
  final String message;
  ChainException(this.message);
  @override
  String toString() => message;
}

/// Satu catatan: data (payload) tetap lokal, yang masuk blockchain hanya hash-nya.
class ChainRecord {
  final int id;
  final String kind; // checklist | quiz | ...
  final String title;
  final String payload; // JSON persis seperti saat di-hash
  final String hash; // SHA-256 (hex) dari payload
  final String? txHash;
  final String status; // draft | pending | confirmed | failed
  final int? blockNumber;
  final String? error;
  final DateTime createdAt;

  const ChainRecord({
    required this.id,
    required this.kind,
    required this.title,
    required this.payload,
    required this.hash,
    this.txHash,
    required this.status,
    this.blockNumber,
    this.error,
    required this.createdAt,
  });

  factory ChainRecord.fromMap(Map<String, Object?> m) => ChainRecord(
    id: m['id'] as int,
    kind: m['kind'] as String,
    title: m['title'] as String,
    payload: m['payload'] as String,
    hash: m['hash'] as String,
    txHash: m['tx_hash'] as String?,
    status: m['status'] as String,
    blockNumber: m['block_number'] as int?,
    error: m['error'] as String?,
    createdAt:
        DateTime.tryParse((m['created_at'] as String?) ?? '') ?? DateTime.now(),
  );

  String get explorerUrl => '$kChainExplorerTx$txHash';
}

class ChainVerification {
  final bool ok;
  final String title;
  final List<String> lines;
  const ChainVerification(this.ok, this.title, this.lines);
}

class _Receipt {
  final bool success;
  final int block;
  const _Receipt(this.success, this.block);
}

/// Menyegel hash data ke blockchain (Ethereum Sepolia) dan memverifikasinya.
///
/// Cara kerja: hash SHA-256 dari data dikirim ke Edge Function `seal-record`,
/// yang menandatangani transaksi 0 ETH ke wallet server dengan hash di kolom
/// "input data". Transaksi itu publik dan permanen; siapa pun bisa
/// memeriksanya di block explorer. Pengguna tidak butuh wallet atau saldo.
class ChainService {
  ChainService._();
  static final ChainService instance = ChainService._();

  // ---------- util ----------

  static String sha256Hex(String s) =>
      sha256.convert(utf8.encode(s)).toString();

  static String _toHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Penanda akun yang tidak membocorkan id asli (hash, dipotong).
  String _userTag() =>
      sha256Hex('studytrip:${CurrentUser.id ?? ''}').substring(0, 16);

  String _friendly(Object e) {
    if (e is ChainException) return e.message;
    final s = e.toString();
    if (e is TimeoutException ||
        s.contains('SocketException') ||
        s.contains('ClientException') ||
        s.contains('XMLHttpRequest')) {
      return 'Tidak bisa terhubung. Periksa koneksi internetmu lalu coba lagi.';
    }
    return 'Terjadi kendala. Coba lagi nanti.';
  }

  // ---------- JSON-RPC ----------

  Future<Object?> _rpc(String method, List<Object?> params) async {
    final res = await http
        .post(
          Uri.parse(kChainRpcUrl),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'jsonrpc': '2.0',
            'id': 1,
            'method': method,
            'params': params,
          }),
        )
        .timeout(const Duration(seconds: 20));
    final j = jsonDecode(res.body);
    if (j is Map && j['error'] != null) {
      final err = j['error'];
      throw ChainException('RPC: ${err is Map ? err['message'] : err}');
    }
    return j is Map ? j['result'] : null;
  }

  Future<_Receipt?> _receipt(String tx) async {
    final r = await _rpc('eth_getTransactionReceipt', [tx]);
    if (r is! Map) return null; // belum masuk blok
    final block = int.parse(
      (r['blockNumber'] as String).substring(2),
      radix: 16,
    );
    return _Receipt(r['status'] == '0x1', block);
  }

  // ---------- kirim ----------

  Future<String> _send(String hashHex) async {
    final SupabaseClient client;
    try {
      client = Supabase.instance.client;
    } catch (_) {
      throw ChainException('Layanan cloud belum aktif di aplikasi ini.');
    }
    if (client.auth.currentSession == null) {
      throw ChainException(
        'Fitur ini butuh akun yang tersambung ke cloud. Coba keluar lalu masuk lagi saat internet aktif.',
      );
    }
    try {
      final res = await client.functions
          .invoke('seal-record', body: {'hash': hashHex})
          .timeout(const Duration(seconds: 40));
      final d = res.data;
      if (d is Map && d['txHash'] is String) return d['txHash'] as String;
      throw ChainException('Penyegelan belum berhasil. Coba lagi nanti.');
    } on ChainException {
      rethrow;
    } on FunctionException catch (e) {
      final code = e.details is Map ? (e.details as Map)['error'] : null;
      throw ChainException(switch (code) {
        'rate_limit' =>
          'Batas penyegelan hari ini sudah tercapai. Coba lagi besok.',
        'auth' => 'Sesi cloud berakhir. Coba keluar lalu masuk lagi.',
        _ => 'Layanan penyegelan sedang tidak tersedia. Coba lagi nanti.',
      });
    }
  }

  // ---------- catat ----------

  Future<List<ChainRecord>> records() async => (await AppDb.instance.query(
    'chain_records',
    orderBy: 'id DESC',
  )).map(ChainRecord.fromMap).toList();

  /// Catat snapshot progres checklist akun yang sedang login.
  Future<void> recordChecklist() async {
    final items = await AppDb.instance.checklist();
    if (items.isEmpty)
      throw ChainException('Checklist masih kosong, tidak ada yang dicatat.');
    final sorted = [...items]..sort((a, b) => a.title.compareTo(b.title));
    final done = sorted.where((e) => e.done).length;
    final payload = jsonEncode({
      'v': 1,
      'kind': 'checklist',
      'user': _userTag(),
      'at': DateTime.now().toUtc().toIso8601String(),
      'done': done,
      'total': sorted.length,
      'items': [
        for (final e in sorted)
          {
            't': e.title,
            'c': e.category,
            'd': fmtDate(e.deadline),
            'x': e.done,
          },
      ],
    });
    await record(
      kind: 'checklist',
      title: 'Progres checklist $done/${sorted.length}',
      payload: payload,
    );
  }

  /// Segel bukti kepemilikan dokumen tanpa mengirim isi atau nama file.
  Future<void> recordDocument({required String fileHash}) async {
    final payload = jsonEncode({
      'v': 1,
      'kind': 'document',
      'user': _userTag(),
      'at': DateTime.now().toUtc().toIso8601String(),
      'documentHash': fileHash,
    });
    await record(
      kind: 'document',
      title: 'Bukti dokumen checklist',
      payload: payload,
    );
  }

  /// Catat skor quiz terbaik.
  Future<void> recordQuiz() async {
    final rows = await AppDb.instance.query(
      'quiz_scores',
      orderBy: 'score DESC, played_at DESC',
    );
    if (rows.isEmpty)
      throw ChainException('Belum ada skor quiz. Mainkan Travel Quiz dulu.');
    final r = rows.first;
    final payload = jsonEncode({
      'v': 1,
      'kind': 'quiz',
      'user': _userTag(),
      'at': DateTime.now().toUtc().toIso8601String(),
      'score': r['score'],
      'total': r['total'],
      'played_at': r['played_at'],
    });
    await record(
      kind: 'quiz',
      title: 'Skor quiz ${r['score']}/${r['total']}',
      payload: payload,
    );
  }

  /// API umum: fitur lain (mis. Anggaran) cukup memanggil ini dengan payload JSON.
  Future<void> record({
    required String kind,
    required String title,
    required String payload,
  }) async {
    final hash = sha256Hex(payload);
    final id = await AppDb.instance.insert('chain_records', {
      'kind': kind,
      'title': title,
      'payload': payload,
      'hash': hash,
      'status': 'draft',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    await _submit(id, hash);
  }

  /// Kirim ulang catatan yang belum pernah terkirim (draft/gagal tanpa transaksi).
  Future<void> retry(ChainRecord r) async {
    if (r.txHash != null) return;
    await _submit(r.id, r.hash);
  }

  /// Mengirim, lalu langsung kembali. Konfirmasi di jaringan ditunggu di
  /// latar belakang (layar yang terbuka ikut diperbarui lewat AppDb.version).
  Future<void> _submit(int id, String hash) async {
    try {
      final tx = await _send(hash);
      await AppDb.instance.update('chain_records', id, {
        'tx_hash': tx,
        'status': 'pending',
        'error': null,
      });
      unawaited(_waitConfirmed(id, tx));
    } catch (e) {
      await AppDb.instance.update('chain_records', id, {
        'status': 'failed',
        'error': _friendly(e),
      });
    }
  }

  Future<void> _waitConfirmed(int id, String tx) async {
    try {
      for (var i = 0; i < 30; i++) {
        await Future<void>.delayed(const Duration(seconds: 4));
        final r = await _receipt(tx);
        if (r != null) {
          await AppDb.instance.update('chain_records', id, {
            'status': r.success ? 'confirmed' : 'failed',
            'block_number': r.block,
            if (!r.success) 'error': 'Penyegelan ditolak jaringan.',
          });
          return;
        }
      }
    } catch (_) {
      // abaikan: status "memproses" bisa diperbarui lagi lewat tombol di layar
    }
  }

  /// Perbarui status catatan yang masih menunggu konfirmasi.
  Future<void> refresh(ChainRecord r) async {
    if (r.status != 'pending' || r.txHash == null) return;
    try {
      final rc = await _receipt(r.txHash!);
      if (rc == null) return;
      await AppDb.instance.update('chain_records', r.id, {
        'status': rc.success ? 'confirmed' : 'failed',
        'block_number': rc.block,
        if (!rc.success) 'error': 'Penyegelan ditolak jaringan.',
      });
    } catch (_) {
      // abaikan: akan dicoba lagi nanti
    }
  }

  // ---------- verifikasi ----------

  /// Memeriksa langsung ke jaringan: (1) data lokal belum berubah sejak dicatat,
  /// (2) transaksi ada di blockchain, (3) isinya sama dengan hash data, (4) sudah masuk blok.
  Future<ChainVerification> verify(ChainRecord r) async {
    final lines = <String>[];
    final recomputed = sha256Hex(r.payload);
    if (recomputed != r.hash) {
      return ChainVerification(false, 'Data sudah berubah sejak disegel', [
        'Hash data sekarang tidak sama dengan hash yang dicatat.',
        'Dicatat : ${r.hash}',
        'Sekarang: $recomputed',
      ]);
    }
    lines.add('Hash data cocok:\n${r.hash}');
    if (r.txHash == null) {
      return ChainVerification(false, 'Belum tersegel', [
        ...lines,
        'Catatan ini belum terkirim ke jaringan.',
      ]);
    }
    try {
      final tx = await _rpc('eth_getTransactionByHash', [r.txHash]);
      if (tx is! Map) {
        return ChainVerification(false, 'Segel tidak ditemukan', [
          ...lines,
          'Jaringan tidak mengenali transaksi ${r.txHash}.',
        ]);
      }
      if (tx['blockNumber'] == null) {
        return ChainVerification(false, 'Segel masih diproses', [
          ...lines,
          'Transaksi sudah dikirim tetapi belum masuk blok. Coba lagi sebentar lagi.',
        ]);
      }
      final input = ((tx['input'] ?? tx['data']) as String? ?? '')
          .toLowerCase();
      final expected = '0x${_toHex(utf8.encode(kChainDataPrefix))}${r.hash}';
      if (input != expected) {
        return ChainVerification(false, 'Isi segel tidak cocok', [
          ...lines,
          'Data di blockchain tidak sama dengan hash catatan ini.',
          'Di blockchain: $input',
          'Seharusnya   : $expected',
        ]);
      }
      lines.add('Isi transaksi di blockchain cocok dengan hash.');
      final rc = await _receipt(r.txHash!);
      if (rc == null || !rc.success) {
        return ChainVerification(false, 'Segel belum berhasil', [
          ...lines,
          'Status transaksi di jaringan: gagal atau belum final.',
        ]);
      }
      lines.add('Terkonfirmasi di blok ${rc.block}.');
      try {
        final b = await _rpc('eth_getBlockByNumber', [
          '0x${rc.block.toRadixString(16)}',
          false,
        ]);
        if (b is Map && b['timestamp'] is String) {
          final ts = int.parse(
            (b['timestamp'] as String).substring(2),
            radix: 16,
          );
          final t = DateTime.fromMillisecondsSinceEpoch(
            ts * 1000,
            isUtc: true,
          ).toLocal();
          lines.add('Waktu blok: ${t.toString().split('.').first}');
        }
      } catch (_) {}
      lines.add('Jaringan: $kChainName');
      lines.add('Tx: ${r.txHash}');
      return ChainVerification(true, 'Asli dan tidak berubah', lines);
    } catch (e) {
      return ChainVerification(false, 'Belum bisa memeriksa', [
        ...lines,
        _friendly(e),
      ]);
    }
  }
}
