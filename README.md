# superApp Smart Meeting

Aplikasi Flutter untuk tablet (landscape) yang mengendalikan perangkat di satu ruang meeting — IFP, pintu, dan perangkat lain yang terdaftar di **Smart Meeting**. Aplikasi hanya berbicara dengan API Smart Meeting; Smart Meeting yang meneruskan perintah ke mini PC ruangan.

```
Aplikasi (Flutter) ⇄ Smart Meeting API ⇄ Mini PC → Perangkat
```

## Fitur

- **Pairing ruangan** dengan kode setup `XXXX-XXXX` (sama dengan kode layar display). Kode ditukar dengan token, token disimpan di Keychain / Keystore.
- **Dashboard**: info ruangan, status & jadwal meeting di top bar, card per perangkat dari API (card IFP dengan saklar daya dan sumber input), semua card sama tinggi.
- **Halaman Perangkat**: tab per kategori, detail tiap perangkat (daya, suara, sumber input, mode gambar, kontras, kecerahan, informasi).
- **Status perangkat** langsung dari mini PC, dengan polling berkala di dashboard.
- **Keluar** dari ruangan (hapus token) dan **otomatis keluar** bila token dicabut admin (HTTP 401).

## Menjalankan

```bash
flutter pub get
flutter run
```

Base URL API diatur di `lib/helper/global_var.dart`:

```dart
const String baseUrl = 'https://smartmeeting.onesia.id';
```

Butuh kode setup ruangan dari admin Smart Meeting (menu Ruangan → "Hubungkan Display").

### Icon aplikasi

Diatur lewat `flutter_launcher_icons` di `pubspec.yaml` (`assets/images/onesia_icon.png`):

```bash
dart run flutter_launcher_icons
```

## Endpoint API yang dipakai

Base: `{APP_URL}/api/v1`. Semua endpoint selain pairing memakai `Authorization: Bearer <token>`.

| Kegunaan | Method | Endpoint | Dipakai di |
|---|---|---|---|
| Tukar kode setup → token | `POST` | `/monitor/pair` | `login_room.dart` |
| Data ruangan + daftar perangkat & perintah | `GET` | `/remote/room` | Dashboard, Perangkat |
| Status perangkat (langsung dari mini PC) | `GET` | `/remote/devices/state` | Dashboard (polling 20 dtk), Perangkat (saat tab diklik) |
| Status & jadwal ruangan | `GET` | `/monitor/room-status` | Top bar (polling 60 dtk) |
| Kirim perintah ke perangkat | `POST` | `/remote/devices/{id_perangkat}/commands` | Card dashboard (timeout 40 dtk) |

Format respons: `{ "success": true, "data": {...} }` atau `{ "success": false, "message": "...", "code": "..." }`. `message` ditampilkan langsung ke pengguna.

Tombol kontrol dibuat dari daftar `perintah` tiap perangkat yang dikirim API — aplikasi tidak menulis daftar perintah sendiri, jadi perintah baru muncul tanpa rilis ulang.

## Struktur folder

```
lib/
├── main.dart                     # lock landscape, navigatorKey, handler 401
├── helper/
│   ├── global_var.dart           # baseUrl, navigatorKey
│   └── loading_page.dart         # dialog loading
├── pages/
│   ├── splash_logo_screen.dart   # cek token → Dashboard / LoginRoom
│   ├── login_room.dart           # input kode setup & pairing
│   ├── dashboard.dart            # shell (sidebar, top bar) + konten dashboard
│   └── devices_page.dart         # halaman Perangkat
├── services/
│   ├── api_services.dart         # wrapper HTTP (header, timeout, 401)
│   ├── room_service.dart         # semua endpoint API di atas
│   ├── storage_services.dart     # token di secure storage
│   └── device_command_service.dart  # mock, hanya untuk Quick Scene
└── l10n/                         # file lokalisasi (generate)
```

## Alur navigasi

```
SplashLogoPage ── ada token ──► DashboardPage
      └──────── belum ────────► LoginRoom ── pairing berhasil ──► DashboardPage

DashboardPage (satu shell, isi diganti lewat state)
  ├─ Dashboard
  ├─ Perangkat  ◄── sidebar / klik card / "Kelola perangkat"
  │                 tombol ← atau back Android → kembali ke Dashboard
  └─ Keluar → hapus token → LoginRoom

API 401 di mana pun → hapus token → LoginRoom
```

## Status pengembangan

Sudah tersambung ke API: pairing, data ruangan, status perangkat, jadwal ruangan, kirim perintah dari card dashboard.

Belum / masih mock (ditandai `TODO` di kode):

- Kirim perintah dari **halaman Perangkat** (tombol baru menampilkan pesan "belum tersedia").
- **Quick Scene** di dashboard (belum ada di API remote, memakai `device_command_service.dart` mode mock).

## Prototype desain

`prototype/index.html` adalah acuan visual yang bisa dibuka langsung di browser (tablet landscape 1280×800). Prototype ini tidak terhubung ke kode Flutter; perubahan desain perlu diterapkan manual di kedua tempat.
