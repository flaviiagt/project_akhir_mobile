import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Kurs terakhir yang berhasil diambil. Semua kurs berbasis USD (USD = 1),
/// konversi antar mata uang dihitung lewat kurs silang.
class RateSnapshot {
  final Map<String, double> rates;
  final String sourceDate; // tanggal publikasi kurs dari ECB (yyyy-MM-dd)
  final DateTime fetchedAt; // kapan aplikasi mengambil data ini
  final bool fromCache; // true = data lama karena offline/gagal

  const RateSnapshot({
    required this.rates,
    required this.sourceDate,
    required this.fetchedAt,
    this.fromCache = false,
  });

  double convert(double amount, String from, String to) {
    final rFrom = rates[from];
    final rTo = rates[to];
    if (rFrom == null || rTo == null) {
      throw ArgumentError('Mata uang tidak didukung: $from/$to');
    }
    return amount / rFrom * rTo;
  }

  /// Nilai 1 [from] dalam [to].
  double unitRate(String from, String to) => convert(1, from, to);

  Map<String, dynamic> toJson() => {
        'rates': rates,
        'sourceDate': sourceDate,
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  factory RateSnapshot.fromJson(Map<String, dynamic> j,
          {bool fromCache = false}) =>
      RateSnapshot(
        rates: (j['rates'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
        sourceDate: j['sourceDate'] as String,
        fetchedAt: DateTime.parse(j['fetchedAt'] as String),
        fromCache: fromCache,
      );
}

class CurrencyRepository {
  static const supported = ['IDR', 'USD', 'JPY', 'GBP', 'EUR'];
  static const sourceName = 'Frankfurter (European Central Bank)';
  static const _cacheKey = 'currency_rates_cache_v1';

  final http.Client _client;
  CurrencyRepository({http.Client? client}) : _client = client ?? http.Client();

  /// Ambil kurs terbaru. Jika gagal (offline/error), pakai cache terakhir.
  /// Jika cache juga tidak ada, melempar exception.
  Future<RateSnapshot> getRates() async {
    try {
      final uri = Uri.https('api.frankfurter.dev', '/v1/latest', {
        'base': 'USD',
        'symbols': supported.where((c) => c != 'USD').join(','),
      });
      final res = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception('Server mengembalikan status ${res.statusCode}');
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final rates = (json['rates'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble()));
      rates['USD'] = 1.0;

      final snap = RateSnapshot(
        rates: rates,
        sourceDate: json['date'] as String,
        fetchedAt: DateTime.now(),
      );
      await _save(snap);
      return snap;
    } catch (_) {
      final cached = await _load();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<void> _save(RateSnapshot s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(s.toJson()));
  }

  Future<RateSnapshot?> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      return RateSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
        fromCache: true,
      );
    } catch (_) {
      return null;
    }
  }
}