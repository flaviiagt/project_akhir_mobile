# Fitur Blockchain StudyTrip (FR-27 dan FR-28)

## Apa yang dilakukan
Aplikasi mencatat **hash SHA-256** dari data persiapan (progres checklist, skor quiz) sebagai
**transaksi nyata di testnet Ethereum Sepolia**. Isi data tetap di perangkat; yang tercatat publik
hanya hash-nya. Pengguna bisa **memverifikasi** langsung ke jaringan.

- Catat: Beranda > kartu "Bukti Blockchain" > "Catat progres checklist" / "Catat skor quiz terbaik".
- Transaksi: 0 ETH ke alamat wallet aplikasi sendiri, dengan data `STRIP1:` + 32 byte hash di kolom input.
- Verifikasi (tombol "Verifikasi") memeriksa 4 hal:
  1. data lokal belum berubah sejak dicatat (hash dihitung ulang),
  2. transaksi ada di jaringan (`eth_getTransactionByHash`),
  3. isi transaksi sama dengan hash data,
  4. transaksi sudah masuk blok dan berstatus sukses (`eth_getTransactionReceipt`).
- Bukti untuk dosen: salin tautan explorer lalu buka di browser. Kolom "Input Data" menampilkan `STRIP1:` dan hash-nya.

## Persiapan (sekali)
1. `flutter pub get`
2. Buat wallet khusus testnet: `dart run tool/gen_wallet.dart` (mencetak alamat dan private key).
3. Isi saldo testnet Sepolia ke alamat itu lewat faucet Sepolia (cari "Sepolia faucet"; sebagian
   faucet meminta akun atau verifikasi, pilih yang tersedia untukmu). Satu transaksi hanya butuh sangat sedikit ETH testnet.
4. Salin `dart_defines.example.json` menjadi `dart_defines.json`, isi `CHAIN_PRIVATE_KEY`.
   **Tambahkan `dart_defines.json` ke `.gitignore`. Jangan di-commit.**
5. Jalankan: `flutter run --dart-define-from-file=dart_defines.json`
   (build APK: `flutter build apk --dart-define-from-file=dart_defines.json`).

## Catatan keamanan dan batasan
- Private key ikut tertanam di aplikasi hasil build (sama seperti kunci API lain yang diberikan lewat `--dart-define`).
  Karena itu gunakan wallet **khusus testnet** yang hanya berisi ETH testnet tanpa nilai. Jangan pernah memakai wallet berisi uang asli.
- Endpoint RPC publik bisa lambat atau tidak tersedia. Ganti lewat `CHAIN_RPC_URL` di `dart_defines.json` kalau perlu.
- Di web (Chrome), sebagian endpoint RPC memblokir permintaan karena CORS. Uji di Android untuk hasil yang pasti.
- Verifikasi (1) hanya membuktikan data lokal tidak berubah **sejak dicatat**, bukan bahwa data itu benar sejak awal.
- Catatan blockchain disimpan lokal per akun dan tidak disinkronkan ke Supabase.

## Memakai dari fitur lain (mis. Anggaran)
```dart
await ChainService.instance.record(
  kind: 'budget',
  title: 'Pengeluaran Visa',
  payload: jsonEncode({'v': 1, 'kind': 'budget', 'amount': 8200000, 'at': DateTime.now().toUtc().toIso8601String()}),
);
```
Payload disimpan persis seperti string yang di-hash. Jangan menyusun ulang sebelum diverifikasi.
