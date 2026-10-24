/// Validasi input (checklist: tolak kosong, nol, negatif, tidak valid).
class Validators {
  static const int maxAmount = 1000000000000; // 1 triliun

  /// Mengembalikan pesan error, atau null jika valid.
  static String? amount(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Nominal wajib diisi';
    if (v.startsWith('-')) return 'Nominal tidak boleh negatif';
    if (!RegExp(r'^\d+$').hasMatch(v)) {
      return 'Nominal tidak valid (hanya angka)';
    }
    final n = int.tryParse(v);
    if (n == null) return 'Nominal tidak valid';
    if (n <= 0) return 'Nominal harus lebih dari 0';
    if (n > maxAmount) return 'Nominal terlalu besar';
    return null;
  }

  /// Ubah teks nominal menjadi int (panggil setelah [amount] lolos).
  static int parseAmount(String value) => int.parse(value.trim());

  static String? name(String? value, {String label = 'Nama'}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return '$label wajib diisi';
    if (v.length > 60) return '$label maksimal 60 karakter';
    return null;
  }

  static String? note(String? value) {
    if ((value ?? '').length > 200) return 'Catatan maksimal 200 karakter';
    return null;
  }
}
