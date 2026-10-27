# studytrip

A new Flutter project.

## Gemini API key (StudyBuddy AI)

Jangan commit API key ke GitHub. Setiap developer sebaiknya memakai API key
masing-masing dan mengaturnya secara lokal melalui ikon pengaturan (⚙️)
StudyBuddy di aplikasi. Key tersebut disimpan di perangkat, bukan di repository.

Untuk menjalankan aplikasi dengan key dari file lokal, buat `env.json` di root
project (file ini diabaikan Git):

```json
{
  "GEMINI_API_KEY": "isi-api-key-lokal"
}
```

Jalankan Flutter dengan file tersebut sebagai compile-time define:

```powershell
flutter run --dart-define-from-file=env.json
```

Ini diperlukan untuk Android/iOS/web; membaca `env.json` langsung hanya
didukung saat aplikasi berjalan sebagai desktop. Untuk build, gunakan opsi
yang sama, misalnya `flutter build apk --dart-define-from-file=env.json`.
Setiap anggota tim perlu membuat file lokalnya sendiri. Jangan mengirim key
melalui commit, chat grup, atau screenshot.
