# Boost Converter dengan Kontrol PID Digital + Anti-Windup
Teknologi Rekayasa Instrumentasi dan Kontrol, SV UGM.

Proyek ini punya dua tahap dengan spesifikasi berbeda:

1. **Simulasi (UTS): paket PBL-B dari dosen**, 24 V → 48 V. Sudah selesai di Simulink (`simulink/`).
2. **Hardware (UAS): reverse engineering modul MT3608**, 12 V → 24 V. Board dibuat dengan MOSFET dan gate driver diskret, dikendalikan RP2040 dengan PID digital + anti-windup. Telemetri dikirim ke board IoT (ESP32-C3) lewat UART.

## Spesifikasi hardware (reverse MT3608)

| Parameter | Nilai |
|---|---|
| Vin | 12 V (adaptor 12 V 2 A) |
| Vout (Vref) | 24 V (bisa diatur, maks 28 V) |
| fsw | 300 kHz |
| Induktor | 22 µH, CD54 (dicopot dari modul MT3608) |
| Beban | 220 Ω dan 110 Ω (2 × 220 Ω paralel) |
| Iout nominal | ±0,22 A (110 Ω) |
| Gangguan | 220 Ω → 110 Ω |
| Ripple Vout | ≤ 0,48 Vpp (2 %) |

Arus dibatasi induktor CD54 (arus saturasi sekitar 1–1,5 A). Converter bekerja di batas CCM/DCM, sama seperti MT3608 di beban ringan.

## Spesifikasi simulasi (PBL-B, sudah selesai)

| Parameter | Nilai |
|---|---|
| Vin | 24 V (uji 20 / 24 / 28 V) |
| Vref | 48 V |
| fsw | 20 kHz |
| Beban | 32 Ω nominal, uji 16–64 Ω |
| Ripple Vout | ≤ 0,96 Vpp |
| Gangguan | 32 Ω → 16 Ω pada t = 0,05 s |

## Progres

- [x] Perhitungan dan model Simulink PBL-B (open-loop, closed-loop)
- [x] Tuning PID, 8 kombinasi gain (`simulink/tuning_pid.m`)
- [x] Skrip uji skenario (`simulink/uji_skenario.m`)
- [x] Revisi skematik KiCad ke spek MT3608 (ERC bersih)
- [x] Footprint CD54 + model 3D
- [ ] Simulink untuk spek hardware (12 V → 24 V, 300 kHz, 22 µH)
- [ ] Verifikasi Proteus (gate driver)
- [ ] Layout dan routing PCB, cetak PCB
- [ ] Firmware RP2040 (PWM 300 kHz, PID, telemetri UART)
- [ ] Uji hardware dan perbandingan dengan modul MT3608 asli

## Struktur repo

```
docs/        rencana kerja, perhitungan, laporan, gambar
simulink/    model .slx + skrip .m (PBL-B)
hardware/    kicad/ (skematik, PCB, footprint, model 3D), proteus/, BOM.csv
firmware/    kode RP2040 (PID digital + anti-windup, telemetri ke ESP32-C3)
data/        hasil pengukuran / log telemetri (.csv)
```

Rencana kerja: [docs/PLANNING.md](docs/PLANNING.md) · Daftar komponen: [hardware/BOM.csv](hardware/BOM.csv) · Panduan Simulink: [docs/SIMULINK_GUIDE.md](docs/SIMULINK_GUIDE.md)
