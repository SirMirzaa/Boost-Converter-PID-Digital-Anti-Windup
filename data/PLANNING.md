# Rencana Kerja: Boost Converter + PID Digital + Anti-Windup

## 1. Tiga penilaian, dua spesifikasi

| | PBL Elektronika Daya (UTS) | PBL Elektronika Daya (UAS) | Praktikum IoT |
|---|---|---|---|
| Wajib | Model **Simulink** (.slx), laporan, ≤ 10 slide, video ≤ 3 menit | **Hardware** boost converter | Hardware + telemetri ESP32 |
| Spesifikasi | PBL-B: 24 V → 48 V, 20 kHz | Reverse modul **MT3608**: 12 V → 24 V | Board daya yang sama dengan UAS |
| Status | Selesai | Skematik selesai, PCB berjalan | Menunggu board |

Untuk UAS, dosen meminta **reverse engineering modul MT3608**: spesifikasi mirip modul, tapi switch-nya diganti MOSFET diskret dengan gate driver yang sesuai. Arus output bebas ditentukan kelompok.

Hasil Simulink PBL-B (spek 24 → 48 V) tetap dipakai untuk laporan UTS. Untuk hardware, Simulink diulang dengan spek baru (bagian 3) supaya gain PID dan hasil pengukuran bisa dibandingkan dengan simulasi.

## 2. Urutan software

| Tahap | Software | Keluaran | Status |
|---|---|---|---|
| 1 | Hitung manual / skrip `.m` | D, L, C, ripple, arus | PBL-B selesai; spek MT3608 di bagian 3 |
| 2 | **MATLAB Simulink** | Open-loop, closed-loop, tuning PID, uji skenario | PBL-B selesai; spek MT3608 belum |
| 3 | Proteus (opsional) | Cek gate driver IR2113 | Belum |
| 4 | **KiCad** | Skematik → PCB board daya | Skematik selesai (ERC 0), PCB berjalan |
| 5 | Arduino IDE (arduino-pico) | Firmware RP2040 | Belum |
| 6 | Bench test | Data → `data/` | Belum |

## 3. Perhitungan spek hardware (MT3608-style)

| Besaran | Persamaan | Hasil |
|---|---|---|
| D ideal | 1 − Vin/Vout = 1 − 12/24 | 0,50 (0,57 untuk 28 V) |
| Iout nominal | 24 / 110 | 0,22 A |
| Pout nominal | 24² / 110 | 5,2 W |
| Arus input rata-rata (η ≈ 88 %) | Pout / (η · Vin) | ±0,5 A |
| ΔIL (kalau CCM) | Vin·D / (L·fsw) = 12·0,5 / (22 µH · 300 kHz) | 0,91 A |
| Batas CCM/DCM | Iout = (ΔIL/2)·(1 − D) | ±0,23 A → beban nominal tepat di batas, 220 Ω masuk DCM |
| Arus puncak induktor | — | ±0,95 A (masih di bawah batas CD54) |
| Pembagi feedback | 100 k / 10 k | 24 V → 2,18 V ke ADC; batas baca ±36 V |
| Resolusi PWM RP2040 | 125 MHz / 300 kHz | ±416 langkah → ±0,1 V per langkah duty di Vout |

**Kenapa 300 kHz:** induktor CD54 22 µH kecil. Di 100 kHz, arus puncak untuk Iout 0,22 A sudah melewati batas saturasinya. Di 300 kHz, arus puncak turun ke ±0,95 A. MT3608 asli sendiri bekerja di frekuensi jauh lebih tinggi (±1,2 MHz, cek datasheet).

**Kenapa arusnya kecil:** label "2 A" di modul MT3608 adalah arus switch, bukan arus output. Dengan induktor bawaan modul, Iout realistis di 12 → 24 V hanya ratusan mA.

**Pengukuran arus:** arus input ±0,5 A masih di dalam rentang shunt R100 bawaan modul INA226 (±0,82 A). Jadi shunt di PCB dihapus dan arus input lewat modul INA226.

**Proteksi:** blok OVP hardware dihapus. Penggantinya di firmware:
- Batas duty maksimum 0,65.
- PWM dimatikan dan dikunci kalau Vout > 30 V atau < 1 V saat berjalan (antisipasi pembagi feedback putus).
- Watchdog RP2040.
- Resistor gate-ke-GND (R2 10 k) dan pull-down input driver (R9 47 k) menjaga MOSFET mati saat boot.

## 4. Komponen

Lihat `hardware/BOM.csv`. Ringkasan bagian daya:

| Fungsi | Dipakai | Alasan |
|---|---|---|
| MOSFET | STP65NF06 (60 V, TO-220) | Rds(on) kecil, mudah didrive 12 V |
| Dioda | MBR2045CT (45 V, TO-220) | Schottky, Vf rendah; kedua anoda diparalel |
| Driver | IR2113S, sisi LO saja | Tersedia; TC4420 tidak ada di toko |
| Induktor | 22 µH CD54 dari MT3608 | Bagian dari reverse engineering |
| Sensor arus | Modul INA226 (shunt R100 bawaan) | Arus input ≤ 0,82 A |
| Elco | 470 µF 25 V (input), 220 µF 50 V (output) | Ditambah keramik 10 µF di output |

**Catatan IR2113S:** versi SOIC-16W. VDD ke 3V3 (supaya logika cocok dengan RP2040), VCC ke Vin 12 V, HIN dan SD ke GND, HO/VS/VB tidak dipakai. Suplai minimum IR2113 10 V, jadi adaptor 12 V tidak boleh turun di bawah ±10,5 V.

**Catatan heatsink:** tab STP65NF06 = SW, tab MBR2045CT = VOUT. Kalau satu heatsink, wajib mika dan ring isolator.

## 5. Jadwal

| Fase | Pekerjaan | Commit |
|---|---|---|
| A | Simulink PBL-B, laporan, slide, video UTS | `simulink/`, `docs/` (selesai) |
| B | Revisi skematik ke spek MT3608 | `hardware/kicad/` (selesai) |
| B | Simulink spek MT3608 (12 → 24 V, 300 kHz, 22 µH), tuning ulang PID | `simulink/` |
| B | Layout dan routing PCB, cetak 1:1 di kertas untuk cek footprint, pesan PCB | `hardware/kicad/` |
| C | Firmware; uji bertahap: suplai → gate → open-loop → closed-loop | `firmware/` |
| C | Uji skenario: 220 Ω, 110 Ω, gangguan 220 → 110 Ω; bandingkan dengan modul MT3608 asli | `data/` |
| D (UAS) | Laporan hardware: simulasi vs pengukuran, board kita vs MT3608 | `docs/` |

Cetak PCB adalah jalur kritis. Pesan PCB **paling lambat 3–4 minggu sebelum UAS**.

## 6. Aturan GitHub kelompok

- Satu branch per pekerjaan (`simulink-tuning`, `kicad-board-daya`, `firmware`), merge lewat pull request.
- File `.slx` dan `.kicad_pcb` tidak bisa di-merge otomatis: **satu orang mengedit satu file pada satu waktu**.
- Simpan `.slx` dengan versi MATLAB yang sama dengan komputer lab/dosen.
- Jangan upload folder `*-backups`, `fp-info-cache`, `*.lck`, dan `.kicad_prl`.
- Pertimbangkan repo **private** selama tugas belum dinilai, dan jangan cantumkan NIM di repo publik.
