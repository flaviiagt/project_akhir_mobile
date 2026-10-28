# Bukti Progres (blockchain di balik layar) — FR-27 dan FR-28

## Yang dilihat pengguna
Di **Checklist > ikon centang-terverifikasi** (atau banner "Semua tugas selesai"),
pengguna menekan **Segel progres sekarang**. Mereka mendapat bukti ber-cap waktu
yang tidak bisa diubah, dan bisa menekan **Cek keaslian** kapan saja. Istilah teknis
(kode data, ID transaksi, nomor blok, tautan explorer) hanya muncul di **Detail teknis**.

## Cara kerja
1. Aplikasi membuat ringkasan progres checklist (JSON) dan menghitung hash SHA-256-nya.
   Ringkasan disimpan lokal; hanya hash yang keluar dari perangkat.
2. Aplikasi memanggil Edge Function `seal-record` (butuh login). Fungsi menandatangani
   transaksi 0 ETH di **Ethereum Sepolia (testnet)** ke wallet server, dengan data
   `STRIP1:` + 32 byte hash. Wallet ada di server (secret `CHAIN_PRIVATE_KEY`),
   bukan di aplikasi, jadi pengguna tidak butuh wallet atau saldo.
3. Konfirmasi ditunggu di latar belakang; status berubah dari DIPROSES ke TERSEGEL.
4. **Cek keaslian** memeriksa langsung ke jaringan (RPC publik, hanya baca):
   hash dihitung ulang, transaksi ada, isinya sama dengan hash, dan sudah masuk blok.
   Bukti publik: salin tautan dari Detail teknis lalu buka di browser (kolom "Input Data").

## Persiapan
Lihat bagian Backend di `README.md` (secret + deploy `seal-record`).

## Batasan
- Bukti hanya menunjukkan data **tidak berubah sejak disegel**, bukan bahwa data itu benar sejak awal.
- Ini testnet: cocok untuk demo/tugas, bukan bukti hukum.
- Endpoint RPC publik bisa lambat; ganti lewat `--dart-define=CHAIN_RPC_URL=...`
  (aplikasi) dan secret `CHAIN_RPC_URL` (server) bila perlu. Di web, sebagian RPC
  memblokir verifikasi karena CORS; uji di Android.
- Riwayat segel disimpan lokal per akun. Server hanya menyimpan hash + ID transaksi
  (tabel `seal_records`).

## Memakai dari fitur lain
```dart
await ChainService.instance.record(
  kind: 'budget',
  title: 'Pengeluaran Visa',
  payload: jsonEncode({'v': 1, 'kind': 'budget', 'amount': 8200000}),
);
```
Payload disimpan persis seperti string yang di-hash; jangan disusun ulang sebelum diverifikasi.
