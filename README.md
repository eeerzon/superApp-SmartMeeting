# Smart Meeting Controller

Aplikasi Flutter untuk tablet guna mengontrol perangkat IoT di ruang meeting: AC, pencahayaan, audio, IFP, kamera, dan akses pintu.

- **Layar:** tablet, **dikunci landscape** (`main.dart`). Desain acuan 1280×800 dp. Lebar konten menyesuaikan, dan halaman di-scroll secara vertikal.
- **Arsitektur:** feature-first dan clean architecture (`data` / `domain` / `presentation`)
- **Stack:** Riverpod (state), go_router (navigasi + redirect login), Dio dan MQTT/WebSocket (disiapkan untuk integrasi)
- **Tema:** latar putih bersih dengan aksen gradasi merah Onesia
- **Data:** saat ini memakai repository mock dengan latency tiruan. Bagian yang perlu disambungkan ke backend ditandai `TODO`.

## Setup

```bash
# 1. Generate folder platform. File di lib/ tidak akan ditimpa.
flutter create --org id.onesia --platforms android,ios,web .
#    Hapus test/widget_test.dart hasil generate (masih merujuk MyApp).

# 2. Install dependency
flutter pub get

# 3. Preview di Chrome
flutter run -d chrome

# 4. Tablet
flutter run --dart-define=API_BASE_URL=https://<server>/v1 --dart-define=MQTT_HOST=mqtt://<broker>:1883 --dart-define=ROOM_ID=inovasi
```

**Akun demo:** `admin@ruangmeeting.local` / `admin123`. Akun ini ada di `features/auth/data/repositories/auth_repository_impl.dart`.

## Struktur folder

```
lib/
├── main.dart                     # lock landscape, immersive mode
├── app.dart                      # MaterialApp.router + tema
├── core/
│   ├── config/env.dart           # --dart-define (API, MQTT, room)
│   ├── constants/                # debounce, latency mock, endpoint, topik MQTT
│   ├── feedback/app_feedback.dart# showAppToast() & showConfirmDialog()
│   ├── layout/app_layout.dart    # ukuran tetap landscape (sidebar, grid 3 kolom, dll.)
│   ├── realtime/                 # status koneksi server (+ stub client MQTT/WS)
│   ├── router/                   # go_router, redirect login ↔ dashboard
│   ├── session/                  # ruangan & meeting aktif
│   ├── theme/                    # warna, gradasi, spacing, ThemeData
│   └── utils/time_format.dart
├── shared/layout/                # AppShell + widgets/ (side_nav, top_bar, connection_banner)
└── features/
    ├── auth/                     # login email + password
    ├── dashboard/                # quick scene + grid 6 tile perangkat
    │   └── presentation/widgets/tiles/   # tile_frame, tile_controls (lokal dashboard), 6 tile
    ├── devices/                  # entity perangkat, controller perintah, manajemen perangkat
    │   ├── domain/entities/      # Device (sealed) + AcDevice, IfpDevice, ... ; options enum
    │   └── presentation/
    │       ├── providers/room_devices_controller.dart  # execute / adjust / applyScene
    │       ├── device_commands.dart                    # kirim perintah + toast
    │       └── widgets/{common,setup}/                 # kontrol lokal + 6 panel setup
    ├── scenes/                   # preset Mulai Meeting / Presentasi / Video Call / Selesai
    ├── settings/                 # ruangan, koneksi, tampilan, keamanan, tentang
    └── user/                     # profil, ubah password, kelola user, aktivitas
```

## Aturan widget

- **Tidak ada folder widget global.** Setiap fitur punya kontrolnya sendiri dengan parameter yang eksplisit. Contohnya `TileChoiceButton` dan `TileSlider` khusus dashboard, `OptionPills` dan `PanelStepper` khusus panel perangkat, `SettingsTile` dan `SettingsSegmented` khusus pengaturan. Mengubah satu halaman tidak memengaruhi halaman lain.
- Yang dipakai bersama hanya **utilitas**, bukan komponen UI: tema, `AppLayout`, `showAppToast`, `showConfirmDialog`, dan helper perintah di `devices/presentation/device_commands.dart`.

## Alur perintah perangkat

| Jenis | Method | Perilaku UI |
|---|---|---|
| Diskrit (saklar, mode, input) | `RoomDevicesController.execute` | Kontrol dikunci dan spinner tampil sampai perangkat merespons, lalu muncul toast berhasil/gagal |
| Kontinu (slider, +/−) | `RoomDevicesController.adjust` | Nilai langsung berubah di UI, dikirim setelah debounce 700 ms, status "menyimpan…" |
| Scene | `RoomDevicesController.applyScene` | Perangkat diatur satu per satu dengan progres "Menerapkan 2/4…" |

Perintah ditolak dengan pesan error kalau server terputus atau perangkatnya offline. Untuk mencoba, buka **Pengaturan**, lalu nyalakan **Simulasi koneksi terputus**.

## Prototype HTML

`prototype/index.html` adalah acuan visual yang bisa dibuka langsung di Chrome. Isinya disamakan dengan versi Flutter: landscape 1280×800, login email + password dengan akun demo yang sama. Prototype ini **tidak terhubung** ke kode Dart, jadi setiap perubahan desain harus diterapkan manual di kedua tempat.
