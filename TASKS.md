# Daftar Pekerjaan

Riwayat pekerjaan di aplikasi **superApp Smart Meeting**, diurutkan per tanggal. Status: ✅ selesai · 🟡 sebagian / masih mock.

---

## 13 Oktober 2026

| # | Pekerjaan | Status | File |
|---|---|---|---|
| 1 | Membuat icon aplikasi Android & iOS dari `assets/images/onesia_icon.png` lewat `flutter_launcher_icons`, termasuk `remove_alpha_ios: true` (icon iOS tidak boleh transparan) | ✅ | `pubspec.yaml`, `android/.../mipmap-*`, `ios/.../AppIcon.appiconset` |

## 14 Oktober 2026

| # | Pekerjaan | Status | File |
|---|---|---|---|
| 2 | Menyusun daftar perintah per card perangkat (AC, lampu, audio, IFP, pintu, kamera, scene) | ✅ | — |
| 3 | Card IFP: tombol sumber input 2×2 dengan loading di card sebelum source berpindah | ✅ | `lib/pages/dashboard.dart` |
| 4 | Halaman Perangkat versi dummy sesuai prototype: tab perangkat, daftar unit, panel detail tiap jenis perangkat | ✅ | `lib/pages/devices_page.dart` |
| 5 | Klik card di dashboard membuka halaman Perangkat di tab yang sesuai | ✅ | `lib/pages/dashboard.dart` |
| 6 | Service kirim perintah (`DeviceCommandService`) dengan mode mock, disambungkan ke semua tombol | 🟡 mock | `lib/services/device_command_service.dart` |
| 7 | Tombol kembali (←) di halaman Perangkat ke halaman sebelumnya | ✅ | `lib/pages/devices_page.dart`, `lib/pages/dashboard.dart` |
| 8 | Sidebar bisa dibuka/tutup dengan tab chevron di tepi kanan, posisi disimpan (`shared_preferences`); tombol hamburger dihapus | ✅ | `lib/pages/dashboard.dart` |
| 9 | Data halaman Perangkat dimuat per tab saat tab diklik (bukan semua sekaligus) | ✅ | `lib/pages/devices_page.dart` |
| 10 | Menulis ulang halaman Perangkat dengan gaya kode yang sama seperti dashboard | ✅ | `lib/pages/devices_page.dart` |

## 15 Oktober 2026

| # | Pekerjaan | Status | File |
|---|---|---|---|
| 11 | Daftar unit perangkat dipindah menjadi baris tab di dalam panel detail | ✅ | `lib/pages/devices_page.dart` |
| 12 | Record diubah ke named record (`t.tab`, `o.label`, …) supaya kode lebih mudah dibaca | ✅ | `lib/pages/devices_page.dart` |
| 13 | Membersihkan semua peringatan di tab Problems (trailing comma, kutip, `const`, API usang) | ✅ | beberapa file |

## 16 Oktober 2026

### Integrasi API Smart Meeting

| # | Pekerjaan | Status | File |
|---|---|---|---|
| 14 | Pairing kode setup `XXXX-XXXX` → token (`POST /monitor/pair`), token disimpan di Keychain/Keystore, pesan error dari API | ✅ | `lib/pages/login_room.dart`, `lib/services/room_service.dart` |
| 15 | Splash mengecek token: ada → Dashboard, belum → halaman input kode | ✅ | `lib/pages/splash_logo_screen.dart` |
| 16 | `ApiService`: header `Accept`, timeout per request, status HTTP, pesan error koneksi | ✅ | `lib/services/api_services.dart` |
| 17 | Token dicabut (HTTP 401) di endpoint mana pun → hapus token & kembali ke halaman input kode | ✅ | `lib/main.dart`, `lib/helper/global_var.dart` |
| 18 | Dashboard memakai `GET /remote/room`: nama & info ruangan, card per perangkat, tombol dari `perintah`, status `kendali` | ✅ | `lib/pages/dashboard.dart` |
| 19 | Kirim perintah dari card dashboard (`POST /remote/devices/{id}/commands`): konfirmasi, isian parameter, loading, timeout 40 detik, penanganan kode galat | ✅ | `lib/pages/dashboard.dart`, `lib/services/room_service.dart` |
| 20 | Tombol **Keluar** di sidebar: konfirmasi, hapus token, kembali ke halaman input kode | ✅ | `lib/pages/dashboard.dart` |
| 21 | Card IFP kembali ke desain (saklar daya + grid sumber input), status dari `GET /remote/devices/state` dengan polling 20 detik | ✅ | `lib/pages/dashboard.dart` |
| 22 | Sumber input aktif & info volume/bisu/kontras/kecerahan diambil dari `/devices/state` sesuai `id_perangkat` | ✅ | `lib/pages/dashboard.dart` |
| 23 | Top bar: status ruangan (Meeting Aktif / Tersedia), jam meeting, dan jam yang disinkronkan ke server dari `GET /monitor/room-status` | ✅ | `lib/pages/dashboard.dart` |
| 24 | Perbaikan chip volume: angka volume tetap tampil saat bisu | ✅ | `lib/pages/dashboard.dart` |
| 25 | Tinggi semua card dashboard mengikuti card tertinggi (bukan nilai tetap) | ✅ | `lib/pages/dashboard.dart` |
| 26 | Halaman Perangkat memakai data API: tab per kategori, detail status dimuat saat tab diklik | ✅ | `lib/pages/devices_page.dart` |
| 27 | Desain ulang halaman Perangkat: card Daya bergaya pill, grup lain dalam grid tile (Suara, Sumber Input, Mode Gambar, Kontras, Kecerahan, Informasi) | ✅ | `lib/pages/devices_page.dart` |

### Rapikan project & repository

| # | Pekerjaan | Status | File |
|---|---|---|---|
| 28 | Mendata file yang dipakai dan alur navigasi aplikasi | ✅ | — |
| 29 | Menghapus scaffold lama yang tidak dipakai (105 file di `lib/core`, `lib/features`, `lib/shared`, `lib/app.dart`) dan sisa `main()`/`OnesiaApp` di dashboard | ✅ | — |
| 30 | Tombol back Android di halaman Perangkat kembali ke Dashboard (`PopScope`) | ✅ | `lib/pages/dashboard.dart` |
| 31 | Melepas koneksi lama ke GitHub, lalu menyambungkan ke `eeerzon/superApp-SmartMeeting` | ✅ | — |
| 32 | Menulis ulang `README.md`, commit, dan push ke GitHub | ✅ | `README.md`, `.gitignore` |
| 33 | Membuat daftar pekerjaan ini | ✅ | `TASKS.md` |

## 19 Oktober 2026

| # | Pekerjaan | Status | File |
|---|---|---|---|
| 34 | Kirim perintah dari halaman Perangkat sesuai API remote v0.6 (`POST /remote/devices/{id}/commands`): konfirmasi, isian parameter, loading & kunci kontrol, status terbaru setelah perintah, penanganan kode galat. Desain tidak berubah | ✅ | `lib/pages/devices_page.dart` |
| 35 | Slider volume di halaman Perangkat bisa digeser; nilai dikirim (`volume_set`) saat slider dilepas | ✅ | `lib/pages/devices_page.dart` |
| 36 | Dukungan perintah baru v0.6 `contrast_set` / `brightness_set` (dialog isian berisi nilai saat ini) | ✅ | `lib/pages/devices_page.dart` |
| 37 | Dialog konfirmasi & isian parameter dipindah ke helper bersama, dipakai dashboard dan halaman Perangkat | ✅ | `lib/helper/command_dialogs.dart`, `lib/pages/dashboard.dart` |
| 38 | Quick Scene mengikuti prototype (kartu aktif, "Menerapkan 2/4…", konfirmasi "Akhiri meeting?") dan dirakit di aplikasi dari perintah API asli | ✅ | `lib/pages/dashboard.dart` |

---

## Belum dikerjakan

- Endpoint scene di API remote (saat ini scene dirakit di aplikasi). Scene "Selesai" belum bisa mengunci pintu karena API pintu hanya punya `open_door`.
- Package yang tidak dipakai di `pubspec.yaml` (`flutter_riverpod`, `go_router`, `dio`, `mqtt_client`, `web_socket_channel`, `google_fonts`) belum dihapus.
- Versi `intl: any` di `pubspec.yaml` sebaiknya dikunci ke versi tertentu.
