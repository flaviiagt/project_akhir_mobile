import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/chain_config.dart';
import '../data/app_db.dart';
import '../services/chain_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Bukti Blockchain: catat hash data persiapan ke testnet, lihat riwayat, dan verifikasi.
class BlockchainScreen extends StatefulWidget {
  const BlockchainScreen({super.key});
  @override
  State<BlockchainScreen> createState() => _BlockchainScreenState();
}

class _BlockchainScreenState extends State<BlockchainScreen> {
  final _svc = ChainService.instance;
  final _fmt = DateFormat('d MMM y, HH:mm', 'id_ID');
  List<ChainRecord> _records = [];
  String? _wallet;
  bool _busy = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppDb.version.addListener(_load);
    _load();
    _loadWallet();
  }

  @override
  void dispose() {
    AppDb.version.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final recs = await _svc.records();
    if (!mounted) return;
    setState(() {
      _records = recs;
      _loading = false;
    });
    for (final r in recs.where((e) => e.status == 'pending')) {
      _svc.refresh(r);
    }
  }

  Future<void> _loadWallet() async {
    try {
      final a = await _svc.walletAddress();
      if (mounted) setState(() => _wallet = a);
    } catch (_) {
      // private key tidak valid: ditangani saat mengirim
    }
  }

  Future<void> _run(Future<void> Function() action, String doneMsg) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showSnack(context, doneMsg);
    } on ChainException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (e) {
      if (mounted) showSnack(context, 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify(ChainRecord r) async {
    showSnack(context, 'Memeriksa ke jaringan…');
    final v = await _svc.verify(r);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
        title: Row(children: [
          Icon(v.ok ? Icons.verified : Icons.error_outline, color: v.ok ? kPrimary : kDanger),
          const SizedBox(width: 8),
          Expanded(child: Text(v.title)),
        ]),
        content: SingleChildScrollView(child: SelectableText(v.lines.join('\n\n'))),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup'))],
      ),
    );
  }

  Future<void> _copy(String text, String msg) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showSnack(context, msg);
  }

  String _short(String s) => s.length <= 18 ? s : '${s.substring(0, 10)}…${s.substring(s.length - 6)}';

  @override
  Widget build(BuildContext context) {
    final ready = _svc.configured;
    return Scaffold(
      appBar: AppBar(title: const Text('Bukti Blockchain')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          SoftCard(
            color: kTealTint,
            shadow: false,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.verified_user_outlined, color: kPrimary),
                const SizedBox(width: 8),
                Text('Cara kerja', style: headlineStyle(16, weight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),
              const Text(
                'Aplikasi mengambil sidik jari (hash SHA-256) dari data persiapanmu, lalu menyimpannya '
                'sebagai transaksi di jaringan $kChainName. Isi datamu tetap di perangkat; yang '
                'tercatat publik hanya hash-nya. Tombol Verifikasi memeriksa langsung ke jaringan.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          if (!ready)
            SoftCard(
              color: kAmberTint,
              shadow: false,
              child: const Text(
                'Wallet blockchain belum diatur, jadi pencatatan dinonaktifkan. '
                'Jalankan aplikasi dengan --dart-define-from-file=dart_defines.json '
                '(langkah lengkap ada di BLOCKCHAIN.md).',
                style: TextStyle(fontSize: 13, height: 1.4, color: kAmberDark),
              ),
            )
          else if (_wallet != null)
            SoftCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                const Icon(Icons.account_balance_wallet_outlined, color: kSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Wallet aplikasi (testnet)',
                        style: TextStyle(fontSize: 12, color: kSecondary)),
                    Text(_short(_wallet!), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                ),
                IconButton(
                  tooltip: 'Salin alamat',
                  onPressed: () => _copy(_wallet!, 'Alamat wallet disalin'),
                  icon: const Icon(Icons.copy, size: 20),
                ),
                IconButton(
                  tooltip: 'Salin tautan explorer',
                  onPressed: () => _copy('$kChainExplorerAddress$_wallet', 'Tautan explorer disalin'),
                  icon: const Icon(Icons.link, size: 20),
                ),
              ]),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: (_busy || !ready)
                ? null
                : () => _run(_svc.recordChecklist, 'Progres checklist dikirim ke blockchain'),
            icon: const Icon(Icons.checklist),
            label: const Text('Catat progres checklist'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: (_busy || !ready)
                ? null
                : () => _run(_svc.recordQuiz, 'Skor quiz dikirim ke blockchain'),
            icon: const Icon(Icons.quiz_outlined),
            label: const Text('Catat skor quiz terbaik'),
          ),
          if (_busy) ...[
            const SizedBox(height: 14),
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              child: LinearProgressIndicator(minHeight: 6),
            ),
            const SizedBox(height: 6),
            const Text('Mengirim ke jaringan dan menunggu konfirmasi (bisa sampai ±1 menit)…',
                style: TextStyle(fontSize: 12, color: kSecondary)),
          ],
          const SectionHeader('Riwayat', 'Catatan di blockchain'),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_records.isEmpty)
            const EmptyState(
                icon: Icons.link_off, message: 'Belum ada catatan.\nCatat progresmu untuk membuat bukti pertama.')
          else
            for (final r in _records)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: _recordCard(r)),
        ],
      ),
    );
  }

  Widget _recordCard(ChainRecord r) {
    final (label, bg, fg) = switch (r.status) {
      'confirmed' => ('TERKONFIRMASI', kTealTint, kPrimary),
      'pending' => ('MENUNGGU', kAmberTint, kAmberDark),
      'failed' => ('GAGAL', kDangerTint, kDanger),
      _ => ('DRAFT', kBlueTint, kSecondary),
    };
    return SoftCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(width: 8),
          Pill(label, bg: bg, fg: fg),
        ]),
        const SizedBox(height: 4),
        Text(_fmt.format(r.createdAt.toLocal()), style: const TextStyle(fontSize: 12, color: kSecondary)),
        const SizedBox(height: 8),
        Text('Hash: ${_short(r.hash)}', style: const TextStyle(fontSize: 12)),
        if (r.txHash != null) Text('Tx: ${_short(r.txHash!)}', style: const TextStyle(fontSize: 12)),
        if (r.blockNumber != null) Text('Blok: ${r.blockNumber}', style: const TextStyle(fontSize: 12)),
        if (r.status == 'failed' && r.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(r.error!, style: const TextStyle(fontSize: 12, color: kDanger)),
          ),
        const SizedBox(height: 4),
        Wrap(spacing: 4, children: [
          if (r.txHash != null)
            TextButton.icon(
              onPressed: () => _verify(r),
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: const Text('Verifikasi'),
            ),
          if (r.txHash != null)
            TextButton.icon(
              onPressed: () => _copy(r.explorerUrl, 'Tautan explorer disalin'),
              icon: const Icon(Icons.link, size: 18),
              label: const Text('Salin tautan'),
            ),
          if (r.status == 'pending')
            TextButton.icon(
              onPressed: () => _svc.refresh(r),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Cek status'),
            ),
          if (r.txHash == null && (r.status == 'failed' || r.status == 'draft'))
            TextButton.icon(
              onPressed: _busy ? null : () => _run(() => _svc.retry(r), 'Dikirim ulang'),
              icon: const Icon(Icons.replay, size: 18),
              label: const Text('Coba lagi'),
            ),
        ]),
      ]),
    );
  }
}
