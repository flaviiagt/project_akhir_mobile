import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/app_db.dart';
import '../services/chain_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Bukti Progres: menyegel ringkasan progres checklist dengan cap waktu yang
/// tidak bisa diubah, lalu bisa dicek keasliannya. Istilah teknis
/// (hash, transaksi, blok) disembunyikan di "Detail teknis".
class ProgressProofScreen extends StatefulWidget {
  const ProgressProofScreen({super.key});
  @override
  State<ProgressProofScreen> createState() => _ProgressProofScreenState();
}

class _ProgressProofScreenState extends State<ProgressProofScreen> {
  final _svc = ChainService.instance;
  final _fmt = DateFormat('d MMM y, HH:mm', 'id_ID');
  List<ChainRecord> _records = [];
  final Set<int> _expanded = {};
  bool _busy = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppDb.version.addListener(_load);
    _load();
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
      _records = recs.where((e) => e.kind == 'checklist').toList();
      _loading = false;
    });
    for (final r in recs.where((e) => e.status == 'pending')) {
      _svc.refresh(r);
    }
  }

  Future<void> _seal() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _svc.recordChecklist();
      if (mounted) showSnack(context, 'Progres disegel. Konfirmasi butuh sekitar 1 menit.');
    } on ChainException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (_) {
      if (mounted) showSnack(context, 'Penyegelan belum berhasil. Coba lagi nanti.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retry(ChainRecord r) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _svc.retry(r);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify(ChainRecord r) async {
    showSnack(context, 'Memeriksa keaslian…');
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
        content: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(v.ok
                ? 'Progres ini sama persis dengan saat kamu menyegelnya, dan cap waktunya tercatat permanen.'
                : 'Pemeriksaan belum berhasil. Lihat detail teknis di bawah untuk penyebabnya.'),
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Detail teknis', style: TextStyle(fontSize: 13)),
                children: [SelectableText(v.lines.join('\n\n'), style: const TextStyle(fontSize: 12))],
              ),
            ),
          ]),
        ),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Bukti Progres')),
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
                Text('Simpan bukti progresmu', style: headlineStyle(16, weight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),
              const Text(
                'Segel progres checklist-mu dengan cap waktu yang tidak bisa diubah, '
                'misalnya untuk menunjukkan ke pembimbing atau sponsor bahwa persiapanmu '
                'sudah sampai tahap tertentu pada tanggal tertentu. Yang dikirim hanya '
                'kode unik dari datamu, bukan isi checklist-nya.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _seal,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Segel progres sekarang'),
          ),
          if (_busy) ...[
            const SizedBox(height: 14),
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              child: LinearProgressIndicator(minHeight: 6),
            ),
          ],
          const SectionHeader('Riwayat', 'Bukti yang sudah kamu buat'),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_records.isEmpty)
            const EmptyState(
                icon: Icons.lock_open_outlined,
                message: 'Belum ada bukti.\nSegel progresmu untuk membuat bukti pertama.')
          else
            for (final r in _records)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: _recordCard(r)),
        ],
      ),
    );
  }

  Widget _recordCard(ChainRecord r) {
    final (label, bg, fg) = switch (r.status) {
      'confirmed' => ('TERSEGEL', kTealTint, kPrimary),
      'pending' => ('DIPROSES', kAmberTint, kAmberDark),
      'failed' => ('GAGAL', kDangerTint, kDanger),
      _ => ('BELUM TERKIRIM', kBlueTint, kSecondary),
    };
    final open = _expanded.contains(r.id);
    return SoftCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(width: 8),
          Pill(label, bg: bg, fg: fg),
        ]),
        const SizedBox(height: 4),
        Text(_fmt.format(r.createdAt.toLocal()), style: const TextStyle(fontSize: 12, color: kSecondary)),
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
              label: const Text('Cek keaslian'),
            ),
          if (r.status == 'pending')
            TextButton.icon(
              onPressed: () => _svc.refresh(r),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Perbarui status'),
            ),
          if (r.txHash == null && (r.status == 'failed' || r.status == 'draft'))
            TextButton.icon(
              onPressed: _busy ? null : () => _retry(r),
              icon: const Icon(Icons.replay, size: 18),
              label: const Text('Coba lagi'),
            ),
          TextButton.icon(
            onPressed: () => setState(() => open ? _expanded.remove(r.id) : _expanded.add(r.id)),
            icon: Icon(open ? Icons.expand_less : Icons.expand_more, size: 18),
            label: const Text('Detail teknis'),
          ),
        ]),
        if (open)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Kode data (SHA-256): ${_short(r.hash)}', style: const TextStyle(fontSize: 12)),
              if (r.txHash != null) Text('ID transaksi: ${_short(r.txHash!)}', style: const TextStyle(fontSize: 12)),
              if (r.blockNumber != null) Text('Nomor blok: ${r.blockNumber}', style: const TextStyle(fontSize: 12)),
              const Text('Jaringan: Ethereum Sepolia (testnet)', style: TextStyle(fontSize: 12)),
              if (r.txHash != null)
                TextButton.icon(
                  onPressed: () => _copy(r.explorerUrl, 'Tautan bukti disalin'),
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('Salin tautan bukti publik'),
                ),
            ]),
          ),
      ]),
    );
  }
}
