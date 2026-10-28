# CampusLost

Aplikasi lost-and-found untuk lingkungan kampus, dibangun dengan Flutter dan Firebase. Dashboard admin tersedia di dalam APK yang sama sebagai layar terpisah dengan login admin.

## Build APK gabungan

Dashboard React harus dibangun lebih dulu agar asetnya tersedia saat Flutter mengemas APK:

```powershell
cd admin_web
npm install
npm run build
cd ..
flutter pub get
flutter build apk --release
```

Hasil APK: `build/app/outputs/flutter-apk/app-release.apk`.

## Membuka dashboard admin

- Dari layar login, pilih **Masuk sebagai Admin**.
- Jika sudah masuk ke akun mahasiswa, buka tab **Profil** lalu pilih **Masuk sebagai Admin**.
- Gunakan akun Firebase yang dokumen `users/{uid}`-nya memiliki field `role: "admin"`.
