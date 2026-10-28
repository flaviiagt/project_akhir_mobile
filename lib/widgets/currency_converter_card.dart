import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../data/currency_repository.dart';

const _teal = Color(0xFF1E8289);
const _navy = Color(0xFF0F2537);
const _amber = Color(0xFFF4A261);

const _names = {
  'IDR': 'Rupiah Indonesia',
  'USD': 'US Dollar',
  'JPY': 'Yen Jepang',
  'GBP': 'British Pound',
  'EUR': 'Euro',
};
const _symbols = {'IDR': 'Rp', 'USD': r'$', 'JPY': '¥', 'GBP': '£', 'EUR': '€'};

/// Kartu konversi mata uang. Bisa ditaruh di halaman Alat & Utilitas
/// atau dipakai di halaman sendiri.
class CurrencyConverterCard extends StatefulWidget {
  final CurrencyRepository? repository;
  const CurrencyConverterCard({super.key, this.repository});

  @override
  State<CurrencyConverterCard> createState() => _CurrencyConverterCardState();
}

class _CurrencyConverterCardState extends State<CurrencyConverterCard> {
  late final CurrencyRepository _repo =
      widget.repository ?? CurrencyRepository();
  final _amountCtrl = TextEditingController(text: '25');

  RateSnapshot? _snap;
  bool _loading = true;
  String? _loadError;

  String _from = 'GBP';
  String _to = 'IDR';

  // --- Gyroscope: putar HP untuk menukar arah konversi (FR-21) ---
  static const double _spinThreshold =
      2.0; // rad/s, perlu gerakan cepat yang disengaja
  static const Duration _cooldown = Duration(seconds: 1);
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  DateTime? _lastSpin;
  bool _gyroAvailable = true;
  bool _motionSwapEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
    _startGyro();
  }

  void _startGyro() {
    try {
      _gyroSub = gyroscopeEventStream().listen(
        (e) {
          if (!mounted) return;
          // Abaikan jika kartu tidak sedang terlihat (mis. di tab lain).
          if (!TickerMode.valuesOf(context).enabled) return;
          if (!_motionSwapEnabled) return;
          // e.y = kecepatan putar HP mengelilingi sumbu panjangnya (rad/s).
          if (e.y.abs() < _spinThreshold) return;

          final now = DateTime.now();
          if (_lastSpin != null && now.difference(_lastSpin!) < _cooldown) {
            return;
          }
          _lastSpin = now;
          HapticFeedback.selectionClick();
          _swap();
        },
        onError: (_) {
          if (mounted) {
            setState(() {
              _gyroAvailable = false;
              _motionSwapEnabled = false;
            });
          }
        },
        cancelOnError: false,
      );
    } catch (_) {
      _gyroAvailable = false;
    }
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final s = await _repo.getRates();
      if (!mounted) return;
      setState(() {
        _snap = s;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Gagal mengambil kurs dan belum ada data tersimpan. Periksa koneksi internetmu.';
      });
    }
  }

  // ---------- validasi & parsing ----------
  /// Mengembalikan (nilai, pesanError). Menerima "1,5" maupun "1.5".
  (double?, String?) _parseAmount() {
    final raw = _amountCtrl.text.trim();
    if (raw.isEmpty) return (null, 'Nominal tidak boleh kosong');
    final v = double.tryParse(raw.replaceAll(',', '.'));
    if (v == null) return (null, 'Nominal tidak valid');
    if (v <= 0) return (null, 'Nominal harus lebih dari 0');
    if (v > 1e12) return (null, 'Nominal terlalu besar');
    return (v, null);
  }

  void _swap() => setState(() {
    final t = _from;
    _from = _to;
    _to = t;
  });

  // ---------- format ----------
  static String _fmt(double v, String cur) {
    final dec = (cur == 'IDR' || cur == 'JPY') ? 0 : 2;
    final parts = v.toStringAsFixed(dec).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return dec == 0 ? intPart : '$intPart,${parts[1]}';
  }

  static String _fmtTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    final l = t.toLocal();
    return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: GoogleFonts.beVietnamPro(),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _snap == null) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator(color: _teal)),
      );
    }
    if (_snap == null) return _buildError();

    final snap = _snap!;
    final (amount, error) = _parseAmount();
    final result = amount == null ? null : snap.convert(amount, _from, _to);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // header + kurs 1:x
        Row(
          children: [
            const Expanded(
              child: Text(
                'KONVERSI MATA UANG',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Colors.black54,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _amber.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '1 $_from = ${_symbols[_to]} ${_fmtRate(snap.unitRate(_from, _to), _to)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        _currencyChips(
          selected: _from,
          onSelect: (c) => setState(() => _from = c),
        ),
        const SizedBox(height: 12),

        // input
        _row(
          currency: _from,
          trailing: SizedBox(
            width: 104,
            child: TextField(
              controller: _amountCtrl,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _teal,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '0',
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 8),
            child: Text(
              error,
              style: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 12),
            ),
          ),

        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Material(
              color: _teal,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _swap,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.swap_vert, color: Colors.white),
                ),
              ),
            ),
          ),
        ),

        _currencyChips(selected: _to, onSelect: (c) => setState(() => _to = c)),
        const SizedBox(height: 12),

        // hasil
        _row(
          currency: _to,
          trailing: Text(
            result == null ? '—' : _fmt(result, _to),
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Tukar arah konversi dengan gerakan
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tukar dengan gerakan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    _gyroAvailable
                        ? 'Goyangkan HP dengan cepat'
                        : 'Sensor gerak tidak tersedia',
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
            ),
            Text(
              _motionSwapEnabled ? 'Aktif' : 'Nonaktif',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _motionSwapEnabled ? _teal : Colors.black45,
              ),
            ),
            Switch.adaptive(
              value: _motionSwapEnabled,
              onChanged: _gyroAvailable
                  ? (enabled) => setState(() => _motionSwapEnabled = enabled)
                  : null,
              activeTrackColor: _teal,
            ),
          ],
        ),
        const SizedBox(height: 6),

        // sumber & waktu update (FR-14)
        _statusBar(snap),
      ],
    );
  }

  String _fmtRate(double v, String cur) {
    final dec = (cur == 'IDR' || cur == 'JPY') ? 0 : 4;
    final parts = v.toStringAsFixed(dec).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return dec == 0 ? intPart : '$intPart,${parts[1]}';
  }

  Widget _statusBar(RateSnapshot snap) {
    final offline = snap.fromCache;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          offline ? Icons.cloud_off : Icons.info_outline,
          size: 16,
          color: offline ? const Color(0xFFBA1A1A) : Colors.black45,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            offline
                ? 'Offline — memakai kurs tersimpan (data ${snap.sourceDate}, diambil ${_fmtTime(snap.fetchedAt)}).'
                : 'Sumber: ${CurrencyRepository.sourceName}. Kurs tanggal ${snap.sourceDate}, diperbarui ${_fmtTime(snap.fetchedAt)}.',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: _teal),
              )
            : InkWell(
                onTap: _load,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.refresh, size: 20, color: _teal),
                ),
              ),
      ],
    );
  }

  Widget _buildError() => Column(
    children: [
      const Icon(Icons.wifi_off, size: 40, color: _teal),
      const SizedBox(height: 12),
      Text(_loadError ?? 'Terjadi kesalahan', textAlign: TextAlign.center),
      const SizedBox(height: 12),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: _teal),
        onPressed: _load,
        child: const Text('Coba lagi'),
      ),
    ],
  );

  Widget _currencyChips({
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in CurrencyRepository.supported)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(c),
                selected: c == selected,
                showCheckmark: false,
                selectedColor: _teal,
                backgroundColor: const Color(0xFFEFEEEB),
                labelStyle: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.w700,
                  color: c == selected ? Colors.white : _navy,
                ),
                shape: const StadiumBorder(),
                side: BorderSide.none,
                onSelected: (_) => onSelect(c),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row({required String currency, required Widget trailing}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3F0),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _symbols[currency]!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _teal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _names[currency]!.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  currency,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
