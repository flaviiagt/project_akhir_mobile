import 'core/current_user.dart';

/// user_id sementara sebelum login dari Anggota 1 jadi.
/// Setelah login selesai, ganti dengan ID user yang sedang login
/// (cukup oper ke BudgetPage(userId: ...)).
const int kTempUserId = 1;

/// Kategori pengeluaran (mengikuti desain: Akomodasi, Visa, Tiket, Tes Bahasa).
const List<String> kExpenseCategories = [
  'Akomodasi',
  'Visa & Paspor',
  'Tiket Pesawat',
  'Tes Bahasa',
  'Makan & Hidup',
  'Transportasi',
  'Lainnya',
];

/// Gemini API Key untuk fitur StudyBuddy AI.
/// Dapatkan secara gratis di https://aistudio.google.com/
/// Kamu bisa mengganti kunci ini atau mengaturnya lewat dialog pengaturan (ikon ⚙️) di aplikasi.
const String kGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
const String kGeminiModel = 'gemini-3.8-flash';

/// ID pemilik anggaran = akun yang sedang login. Id dari server berupa angka;
/// jika bukan angka (mis. email), dibuat angka tetap dari teksnya supaya
/// tiap akun tetap punya anggaran sendiri.
int currentBudgetUserId() {
  final id = CurrentUser.id;
  if (id == null || id.isEmpty) return kTempUserId;
  return int.tryParse(id) ?? id.codeUnits.fold<int>(7, (h, c) => (h * 31 + c) & 0x7fffffff);
}
