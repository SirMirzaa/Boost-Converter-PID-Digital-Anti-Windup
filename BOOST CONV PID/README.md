# Boost Converter 24 V → 48 V PID Digital + Anti-Windup

PBL Elektronika Daya
Teknologi Rekayasa Instrumentasi dan Kontrol, SV UGM.

| Parameter | Nilai|
|---|---|
| Vin | 24 V (uji 20 / 24 / 28 V) |
| Vref | 48 V |
| fsw | 20 kHz |
| Beban | 32 Ω nominal, uji 16–64 Ω |
| Ripple Vout | ≤ 0,96 Vpp |
| Pout / Iout nominal | 72 W / 1,5 A |
| Gangguan | 32 Ω → 16 Ω pada t = 0,05 s |

## Struktur repo

```
docs/        rencana kerja, perhitungan, laporan, gambar
simulink/    model .slx + skrip parameter .m (deliverable Elektronika Daya)
hardware/    kicad/ (skematik & PCB board daya), proteus/ (opsional), BOM.csv
firmware/    kode RP2040 (PID digital + anti-windup, telemetri ke ESP32-C3)
data/        hasil pengukuran / log telemetri (.csv)
```

Rencana kerja: [docs/PLANNING.md](docs/PLANNING.md) · Daftar komponen: [hardware/BOM.csv](hardware/BOM.csv)
