# Network Sniffing & Traffic Analysis Laboratory 🚀

Repositori ini berisi catatan pembelajaran dan dokumentasi praktik mandiri mengenai **Network Sniffing** dan **Traffic Analysis** menggunakan *Command Line Interface (CLI)* dan *Graphical User Interface (GUI)* pada sistem operasi Linux.

> ⚠️ **Penyangkalan (Disclaimer):** Seluruh aktivitas dalam dokumentasi ini dilakukan di dalam jaringan laboratorium pribadi untuk tujuan edukasi dan pemahaman keamanan siber (Defensive & Offensive Security). Melakukan penyadapan pada jaringan tanpa izin adalah tindakan ilegal.

---

## 📅 Tahap 1: Pengenalan Jaringan & Sniffing Dasar (CLI)

Pada tahap awal, pengujian dilakukan menggunakan `tcpdump` untuk memahami bagaimana paket data bergerak melalui kartu jaringan lokal.

### 1. Identifikasi Kartu Jaringan (Interface)
Mencari nama kartu jaringan yang aktif di komputer (misal: Wi-Fi atau Ethernet):
```bash
# Opsi 1: Melihat status link interface
ip link show

# Opsi 2: Melihat daftar interface yang siap digunakan oleh tcpdump
sudo tcpdump -D
```
*Hasil analisis:* Kartu jaringan Wi-Fi lokal teridentifikasi sebagai **`wlp1s0`**.

### 2. Menangkap Paket Data Sederhana
Menangkap 10 paket pertama yang melewati interface Wi-Fi tanpa mengubah IP menjadi domain (`-n`):
```bash
sudo tcpdump -i wlp1s0 -n -c 10
```

### 3. Memfilter Lalu Lintas Internet (Web Traffic)
Mengisolasi pencarian hanya pada aktivitas web (HTTP/HTTPS) agar terminal tidak terlalu penuh:
```bash
sudo tcpdump -i wlp1s0 -n port 443 or port 80
```

---

## 🎨 Tahap 2: Analisis Visual & Ekstraksi Objek HTTP (Wireshark GUI)

Beralih dari CLI ke GUI menggunakan **Wireshark** untuk membedah anatomi paket dan melakukan rekonstruksi file.

### 1. Instalasi Wireshark
```bash
sudo apt update && sudo apt install wireshark -y
```

### 2. Rekonstruksi & Ekstraksi File dari Trafik Tidak Terenkripsi (HTTP)
Saat mengunduh file melalui protokol HTTP murni (contoh uji coba: `dlptest.com` atau `thinkbroadband`), data dikirim dalam bentuk teks terbuka (*plaintext*).
* **Langkah Ekstraksi di Wireshark:**
  1. Jalankan *Capture* pada interface `wlp1s0`.
  2. Gunakan display filter: `http`
  3. Setelah unduhan selesai, klik **File** -> **Export Objects** -> **HTTP...**
  4. Pilih file yang sesuai (misal: `content-type: application/json` atau `.zip`), lalu klik **Save**.

---

## 📡 Tahap 3: Menembus Batasan Jaringan (Wireless Monitor Mode)

**Masalah:** Pada mode normal (*Managed Mode*), Router Wi-Fi modern menerapkan *Wireless Isolation / Unicast Filtering*. Wireshark tidak dapat menangkap paket privat (seperti DNS atau TLS Handshake) milik perangkat lain (`192.168.1.7`) karena paket tersebut langsung disaring oleh router.

**Solusi:** Mengubah mode kartu Wi-Fi menjadi **Monitor Mode** agar bertindak sebagai antena yang menangkap seluruh sinyal radio mentah (Layer 2 802.11) di udara.

### 1. Instalasi Perangkat Alat Tambahan
```bash
sudo apt install iw -y
```

### 2. Mengaktifkan Monitor Mode Secara Manual
```bash
# 1. Hentikan Network Manager agar tidak menginterupsi
sudo systemctl stop NetworkManager

# 2. Matikan interface sementara
sudo ip link set wlp1s0 down

# 3. Ubah tipe kartu jaringan menjadi monitor
sudo iw wlp1s0 set type monitor

# 4. Nyalakan kembali interface
sudo ip link set wlp1s0 up

# 5. Verifikasi perubahan mode
iwconfig wlp1s0
```
*(Catatan: Jika menggunakan Kali Linux, proses ini bisa disingkat otomatis menggunakan perintah `sudo airmon-ng start wlp1s0` yang akan menghasilkan interface baru bernama `wlp1s0mon`).*

### 3. Menganalisis Trafik Target Berdasarkan MAC Address
Dalam Monitor Mode, pelacakan dilakukan menggunakan **MAC Address** perangkat target karena struktur IP tersembunyi sebelum paket ter-asosiasi:
* **Display Filter Wireshark:**
  ```text
  wlan.addr == aa:bb:cc:dd:ee:ff
  ```
  *(Ganti dengan MAC Address asli dari perangkat target)*

---

## 🛠️ Tahap 4: Mengembalikan Kartu Wi-Fi ke Mode Normal

Setelah sesi laboratorium selesai, kartu jaringan harus dikembalikan ke mode asal (*Managed Mode*) agar komputer dapat terhubung kembali ke internet dengan normal:

```bash
sudo ip link set wlp1s0 down
sudo iw wlp1s0 set type managed
sudo ip link set wlp1s0 up
sudo systemctl start NetworkManager
```

---

## 🧠 Poin Pembelajaran Utama (Key Takeaways)
* **HTTP vs HTTPS:** Protokol HTTP mengirimkan data mentah secara transparan sehingga rentan terhadap *packet carving* (perekatan objek). Sebaliknya, HTTPS mengamankan data dengan enkripsi TLS, menyisakan hanya informasi dasar seperti SNI (*Server Name Indication*) yang tidak terenkripsi pada proses awal *handshake*.
* **Managed Mode vs Monitor Mode:** *Managed mode* hanya menerima paket yang dialamatkan khusus ke komputer kita atau bersifat *broadcast*. *Monitor mode* mengabaikan aturan tersebut dan menangkap seluruh paket yang melayang di frekuensi radio yang sama.
