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

