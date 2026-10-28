# CampusLost Admin

Panel admin berbasis React + Vite yang memakai Firebase project yang sama dengan aplikasi Flutter CampusLost.

## Menjalankan

```sh
npm install
npm run dev
```

Build produksi:

```sh
npm run build
npm run preview
```

## Dipakai di APK CampusLost

Dashboard admin dibundel ke aplikasi Flutter CampusLost yang sama. Bangun ulang aset web ini sebelum build APK dari folder proyek utama:

```powershell
cd admin_web
npm install
npm run build
cd ..
flutter pub get
flutter build apk --release
```

Hasil APK berada di `build/app/outputs/flutter-apk/app-release.apk`.

## Akses admin

1. Buat akun melalui Firebase Authentication.
2. Pastikan dokumen `users/{uid}` akun tersebut memiliki field `role: "admin"`.
3. Masuk lewat dashboard. Akun dengan role lain akan ditolak.

Dashboard membaca koleksi `items`, `claims`, dan `users` secara realtime. Admin dapat meninjau klaim, memperbarui status klaim, dan menutup/membuka kembali laporan.

Pemeriksaan role pada aplikasi web hanya mengatur tampilan dan alur UI. Aturan Firestore tetap harus membatasi akses baca/tulis di server; jangan mengandalkan pemeriksaan React sebagai satu-satunya kontrol keamanan.
