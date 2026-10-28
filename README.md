# studytrip

Aplikasi persiapan studi ke luar negeri (Flutter + Supabase).

## Backend (Supabase) yang perlu disiapkan sekali

Fitur **StudyBuddy AI** dan **Bukti Progres** berjalan lewat Supabase Edge
Function, jadi pengguna akhir tidak perlu memasukkan API key atau wallet apa pun.
Semua rahasia disimpan sebagai *secret* di server, bukan di aplikasi/repository.

```bash
# 1. buat tabel pencatat pemakaian + catatan segel
supabase db push            # atau jalankan supabase/migrations/*.sql di SQL Editor

# 2. simpan rahasia di server
supabase secrets set GEMINI_API_KEY=isi-api-key-gemini
supabase secrets set CHAIN_PRIVATE_KEY=0xPRIVATE_KEY_WALLET_TESTNET
# opsional: GEMINI_MODEL (default gemini-3.8-flash) dan CHAIN_RPC_URL
# (default https://ethereum-sepolia-rpc.publicnode.com)

# 3. deploy fungsi
supabase functions deploy studybuddy
supabase functions deploy seal-record
```

Catatan:
- API key Gemini bisa dibuat gratis di https://aistudio.google.com/.
- `CHAIN_PRIVATE_KEY` harus wallet **khusus testnet** (Sepolia) yang diisi ETH
  testnet dari faucet; satu penyegelan hanya butuh sangat sedikit. Buat wallet
  baru dengan: `node -e "const {Wallet}=require('ethers');const w=Wallet.createRandom();console.log(w.address,w.privateKey)"`
  (setelah `npm i ethers`). Bila saldo wallet habis, penyegelan menampilkan
  "layanan sedang tidak tersedia" ke pengguna dan pesan jelas di log fungsi.
- Kedua fungsi hanya menerima pengguna yang sudah login dan dibatasi per pengguna
  (AI: 60 permintaan/jam, penyegelan: 10/hari; ubah di `supabase/functions/*/index.ts`).

## Pengingat deadline

Pengingat muncul di luar aplikasi (juga saat aplikasi ditutup): 3 hari sebelum,
1 hari sebelum, dan pada hari deadline pukul 09.00, ditambah pukul 17.00 bila
tugas belum selesai. Jika tugas dengan deadline hari ini baru ditambahkan atau
dibuka setelah pukul 09.00, pengingat susulan dibunyikan beberapa detik kemudian
(sekali per tugas per hari).
