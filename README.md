# Manajemen Keuangan Pribadi KoTA 101 - Client (Flutter) 📱

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![BLoC](https://img.shields.io/badge/BLoC-45A6F5?style=for-the-badge)
![Hive](https://img.shields.io/badge/Hive-FFD234?style=for-the-badge)

Aplikasi mobile cross-platform yang elegan dan fungsional untuk manajemen keuangan pribadi. Dibangun dengan Flutter, aplikasi ini menyediakan antarmuka yang intuitif bagi pengguna untuk melacak transaksi, merencanakan anggaran, dan mengevaluasi kesehatan finansial mereka, dengan dukungan penuh untuk mode offline.

---

## Daftar Isi

- [Tentang Proyek](#tentang-proyek)
- [Screenshot Aplikasi](#screenshot-aplikasi)
- [Fitur Utama](#fitur-utama)
- [Arsitektur & Teknologi](#arsitektur--teknologi)
- [Instalasi & Menjalankan](#instalasi--menjalankan)
  - [Prasyarat](#prasyarat)
  - [Langkah-langkah Instalasi](#langkah-langkah-instalasi)
- [Struktur Proyek](#struktur-proyek)
- [Kontribusi](#kontribusi)
- [Lisensi](#lisensi)

## Tentang Proyek

**Manajemen Keuangan Pribadi KoTA 101 - Client** adalah aplikasi yang dirancang untuk membantu pengguna mengelola keuangan mereka dengan lebih baik. Aplikasi ini terhubung dengan backend `ta_server` untuk menyinkronkan data, namun dirancang dengan pendekatan **Offline-First**. Ini berarti pengguna tetap dapat mencatat transaksi dan menggunakan fitur-fitur inti bahkan tanpa koneksi internet.

## Screenshot Aplikasi

| Halaman Dashboard                                | Halaman Evaluasi                               | Halaman Budgeting                                |
| ------------------------------------------------ | ---------------------------------------------- | ------------------------------------------------ |
| ![Dashboard](https://via.placeholder.com/250x500) | ![Evaluasi](https://via.placeholder.com/250x500) | ![Budgeting](https://via.placeholder.com/250x500) |

## Fitur Utama

-   ✨ **Desain Modern & Intuitif**: Antarmuka yang bersih dan mudah digunakan.
-   🔒 **Otentikasi Pengguna**: Halaman login dan registrasi yang aman.
-   💹 **Dashboard Transaksi**: Menampilkan ringkasan pemasukan, pengeluaran, dan daftar transaksi yang terkelompokkan berdasarkan tanggal.
-   ✍️ **Manajemen Transaksi**: Membuat, melihat, mengedit, dan menghapus transaksi dengan mudah.
-   🧠 **Klasifikasi Cerdas**: Menggunakan deskripsi transaksi untuk menyarankan kategori secara otomatis (terhubung ke backend).
-   📊 **Evaluasi Kesehatan Finansial**: Halaman khusus untuk menampilkan 7 rasio keuangan penting dengan visualisasi yang menarik.
-   💰 **Perencanaan Anggaran**: Alur kerja terpandu untuk membuat rencana anggaran berdasarkan pendapatan dan mengalokasikannya ke berbagai pos pengeluaran.
-   🌐 **Fungsionalitas Offline-First**:
    -   Pengguna dapat membuat/mengedit/menghapus transaksi saat offline.
    -   Perubahan akan dimasukkan ke dalam antrian (queue) dan disinkronkan secara otomatis saat koneksi internet kembali.
    -   Data penting seperti transaksi dan kategori di-cache secara lokal menggunakan **Hive** untuk akses cepat.
-   👤 **Manajemen Profil**: Pengguna dapat melihat dan mengubah data profil mereka.

## Arsitektur & Teknologi

Aplikasi ini dibangun dengan praktik terbaik Flutter untuk memastikan kode yang bersih, teruji, dan mudah dikelola.

-   **Arsitektur:**
    -   **Feature-Based Directory Structure**: Kode diorganisir berdasarkan fitur (misalnya, `login`, `transaction`, `evaluation`).
    -   **BLoC (Business Logic Component)**: Digunakan sebagai pola manajemen state utama untuk memisahkan UI dari logika bisnis.
    -   **Repository Pattern**: Abstraksi untuk sumber data, menangani logika pengambilan data dari API (online) atau cache lokal (offline).
    -   **Dependency Injection**: Menggunakan **GetIt** sebagai service locator untuk mengelola dan menyediakan instance dari service dan repository di seluruh aplikasi.

-   **Teknologi Utama:**
    -   **Framework**: Flutter
    -   **Bahasa**: Dart
    -   **State Management**: `flutter_bloc`
    -   **Networking**: `dio` (dengan interceptor untuk logging dan otentikasi)
    -   **Local Storage**: `hive` (untuk caching data dan antrian sinkronisasi)
    -   **Dependency Injection**: `get_it`
    -   **Routing**: Navigator 2.0 (via `onGenerateRoute`)

## Instalasi & Menjalankan

Ikuti langkah-langkah ini untuk menjalankan aplikasi di emulator atau perangkat fisik.

### Prasyarat

-   [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.x atau lebih baru)
-   Code Editor seperti [VS Code](https://code.visualstudio.com/) atau [Android Studio](https://developer.android.com/studio).
-   Emulator Android atau iOS, atau perangkat fisik yang terhubung.
-   Pastikan **server backend (`ta_server`)** sudah berjalan.

### Langkah-langkah Instalasi

1.  **Clone Repositori**
    ```bash
    git clone https://github.com/thisisjackii/ta_client.git
    cd ta_client
    ```

2.  **Setup Environment Variables**
    Buat file `.env.dev` di root direktori proyek. File ini akan berisi URL ke backend Anda.

    ```env
    # Ganti dengan IP dan port backend Anda.
    # Jika menjalankan di emulator Android, gunakan 10.0.2.2 untuk merujuk ke localhost mesin Anda.
    # Jika menjalankan di perangkat fisik di jaringan yang sama, gunakan IP lokal mesin Anda (misal: 192.168.1.10).
    BASE_URL="http://10.0.2.2:4000/api/v1"
    ```

3.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

4.  **Jalankan Aplikasi**
    Pastikan emulator atau perangkat Anda sudah berjalan dan terdeteksi oleh Flutter.

    ```bash
    flutter run
    ```

🚀 Aplikasi Anda sekarang akan ter-build dan berjalan!

## Struktur Proyek

Struktur direktori `lib` diatur berdasarkan fitur untuk menjaga keteraturan.

```
ta_client/
└── lib/
    ├── app/                    # Konfigurasi utama aplikasi (view & routes)
    ├── core/                   # Widget, service, dan konstanta yang digunakan bersama
    │   ├── constants/
    │   ├── services/
    │   └── widgets/
    ├── features/               # Direktori utama untuk setiap fitur
    │   ├── login/
    │   ├── transaction/
    │   ├── evaluation/
    │   ├── budgeting/
    │   └── ... (fitur pelengkap lainnya)
    ├── l10n/                   # File untuk lokalisasi
    └── main.dart               # Entry point utama aplikasi
```

## Kontribusi

Kontribusi, isu, dan permintaan fitur sangat diterima! Jangan ragu untuk membuka isu baru jika Anda menemukan bug atau memiliki saran.

## Lisensi

Didistribusikan di bawah Lisensi MIT. Lihat `LICENSE` untuk informasi lebih lanjut.
