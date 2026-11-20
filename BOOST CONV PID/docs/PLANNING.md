# Rencana Kerja: Boost 24 V → 48 V + PID Digital + Anti-Windup

## 1. Tiga penilaian, satu alat

| | PBL Elektronika Daya (UTS) | PBL Elektronika Daya (UAS) | Praktikum IoT |
|---|---|---|---|
| Wajib | Model **Simulink** (.slx), laporan, ≤ 10 slide, video ≤ 3 menit | **Hardware** boost converter | Hardware + telemetri ESP32 |
| Dasar | Spesifikasi PBL-B (tidak boleh diubah) | Hasil Simulink | Board daya yang sama |

Simulink dikerjakan dulu karena nilainya diperlukan lebih awal. Hasilnya (L, C, gain PID) dipakai langsung di hardware UAS, jadi hardware **harus konsisten dengan model Simulink**: fsw 20 kHz, L 680 µH, beban uji 16–64 Ω, PID diskret dengan Ts sama. Di laporan UAS, hasil pengukuran hardware dibandingkan dengan hasil Simulink. Konsistensi ini yang membuat perbandingannya bermakna.

Satu board daya dipakai untuk UAS Elektronika Daya dan Praktikum IoT sekaligus.

## 2. Urutan software

| Tahap | Software | Keluaran | Prasyarat |
|---|---|---|---|
| 1 | Hitung manual / skrip `.m` | D, L, C, ripple, arus | Spesifikasi PBL-B |
| 2 | **MATLAB Simulink** | Open-loop, closed-loop, ≥ 5 tuning PID, uji beban/Vin/gangguan | Tahap 1 |
| 3 | Proteus (opsional) | Cek gate driver + OVP | Komponen terpilih |
| 4 | **KiCad** | Skematik → PCB board daya | Tahap 2 + komponen sudah dibeli/diukur |
| 5 | Arduino IDE (arduino-pico) | Firmware RP2040 | Gain PID tahap 2 |
| 6 | Bench test | Data → `data/` | Board jadi |

Satu hal penting di tahap 2: **pakai blok PID diskret dengan Ts = 50 µs** (20 kHz, satu update per periode PWM) dan batasi output 0–0,85 dengan anti-windup *back-calculation* (opsi bawaan blok PID Simulink: *Output saturation* + *Anti-windup method: back-calculation*). Dengan begitu Kp, Ki, Kd dan Kb dari Simulink bisa langsung dipindah ke firmware.

## 3. Perhitungan awal (metode sama dengan laporan buck)

Target ripple arus 30 % dari arus induktor nominal, seperti laporan buck sebelumnya.

| Besaran | Persamaan | Hasil |
|---|---|---|
| D nominal | 1 − Vin/Vout = 1 − 24/48 | 0,50 |
| Iout nominal | 48/32 | 1,5 A |
| IL nominal | Iout/(1 − D) | 3,0 A |
| ΔIL target | 30 % × 3 A | 0,9 A |
| L | Vin·D/(ΔIL·fsw) = 24·0,5/(0,9·20 000) | 666,7 µH → **680 µH** |
| ΔVout target | 50 % × 0,96 (sisa untuk ESR) | 0,48 Vpp |
| C min (kasus terberat Vin 20 V, 16 Ω, D = 0,583, Iout = 3 A) | Iout·D/(fsw·ΔV) | 182 µF → **220 µF** |
| CCM di beban teringan (64 Ω, Vin 28 V) | IL − ΔIL/2 > 0 | 1,35 − 0,43 > 0 → CCM |

Kasus terberat untuk hardware (Vin 20 V, 16 Ω, η ≈ 95 %):

| Besaran | Nilai |
|---|---|
| Arus input / induktor rata-rata | ±7,6 A |
| Arus puncak induktor | ±8,0 A |
| Arus RMS kapasitor output | ±3,9 A |
| Daya output | 144 W |

**Catatan kapasitor:** di Simulink pakai C = 220 µF (hasil hitung). Di hardware, satu elco 220 µF tidak kuat menahan ripple current 3,9 A RMS, jadi dipasang **3 × 220 µF**. Cantumkan ini di laporan sebagai *modifikasi untuk implementasi*: parameter awal, modifikasi, alasan, dampak (ripple jadi lebih kecil), sesuai aturan E dari dosen.

## 4. Komponen (tersedia di pasar Indonesia)

Lihat `hardware/BOM.csv`. Ringkasan bagian daya:

| Fungsi | Pilihan utama | Cadangan | Hindari |
|---|---|---|---|
| MOSFET | IRF3710 | IRFB4110, IRFP260N | IRFZ44N (55 V) |
| Dioda | MBR20100CT | MBR20150CT, MBR30100CT | Dioda biasa 1N54xx (lambat) |
| Driver | TC4420 | IR2101 (sudah punya) / IR2110 | — |
| Induktor | Lilit sendiri 680 µH di 2 × T200-26 | Induktor jadi ≥ 680 µH / 10 A | Induktor kecil "drum core" (saturasi) |
| Sensor arus | INA226 + shunt 5 mΩ | ACS712-20A | INA219 (maks 26 V) |
| Elco output | 3 × 220 µF 100 V low-ESR | 2 × 330 µF 100 V low-ESR | Elco 63 V |

Ketersediaan dicek di Tokopedia/Shopee sebelum checkout. Part daya (MOSFET, MBR, TC4420) banyak yang palsu; beli dari toko dengan ulasan bagus dan cek Rds/Vf saat barang datang.

**Induktor:** induktor ini paling sulit dicari jadi. Estimasi awal ±70 lilitan kawat email 1,2 mm pada dua toroid T200-26 (kuning-putih) ditumpuk. Karena permeabilitas serbuk besi turun pada arus besar, **ukur L dengan LCR meter**, dan bila bisa uji di arus kerja. Nilai L terukur dipakai ulang di Simulink untuk verifikasi.

## 5. Jadwal (sesuaikan dengan deadline UTS/UAS)

| Fase | Pekerjaan | Commit |
|---|---|---|
| A (sebelum UTS) | Perhitungan, model open-loop & closed-loop, ≥ 5 tuning PID, semua skenario uji | `simulink/`, `docs/` |
| A | Laporan + slide + video PBL Simulink | `docs/` |
| A (paralel) | **Pesan komponen sekarang** (induktor, elco, part TO-220 butuh waktu kirim) | `hardware/BOM.csv` |
| B | Lilit & ukur induktor; masukkan L terukur ke Simulink untuk verifikasi | `docs/` |
| B | KiCad skematik + PCB, cetak PCB (lokal atau JLCPCB ±1–2 minggu) | `hardware/kicad/` |
| C | Firmware; uji bertahap: suplai → gate → open-loop → closed-loop | `firmware/` |
| C | Uji skenario yang sama dengan Simulink (Vin 20/24/28 V, beban 16/32/64 Ω, gangguan 32 → 16 Ω) | `data/` |
| D (UAS) | Laporan hardware: perbandingan simulasi vs pengukuran | `docs/` |

Cetak PCB dan pengiriman komponen adalah jalur kritis. Mulai fase B **paling lambat 3–4 minggu sebelum UAS**.

## 6. Aturan GitHub kelompok

- Satu branch per pekerjaan (`simulink-tuning`, `kicad-board-daya`, `firmware`), merge lewat pull request.
- File `.slx` dan `.kicad_pcb` tidak bisa di-merge otomatis: **satu orang mengedit satu file pada satu waktu**.
- Simpan `.slx` dengan versi MATLAB yang sama dengan komputer lab/dosen.
- Pertimbangkan repo **private** selama tugas belum dinilai, dan jangan cantumkan NIM di repo publik.
