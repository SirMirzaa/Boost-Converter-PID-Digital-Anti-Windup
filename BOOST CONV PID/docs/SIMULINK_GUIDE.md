# Panduan Model Simulink — Boost PBL-B

Jalankan `simulink/param_boost_pblb.m` dulu. Semua blok di bawah memakai **nama variabel**, bukan angka, supaya satu perubahan di skrip langsung berlaku.

## 1. Model open-loop (`boost_openloop.slx`)

| Blok (Simscape Electrical › Specialized Power Systems) | Parameter |
|---|---|
| powergui | Simulation type: Discrete, Sample time `Ts_pwr` |
| DC Voltage Source | `Vin_nom` |
| Series RLC Branch (L) | Branch type L, Inductance `L`; tambah Resistor `R_L` seri |
| Mosfet | FET resistance `Ron_Q`; snubber Rs = 1e5, Cs = inf |
| Diode | Resistance `Ron_D`, Forward voltage `Vf_D` |
| Series RLC Branch (C) | Capacitance `C`, Initial voltage `Vc0`; tambah Resistor `ESR_C` seri |
| Beban | Series RLC Branch R = `R_nom` |
| PWM Generator (DC-DC) | Switching frequency `fsw`, input = Constant `D_nom` |
| Ukur | Voltage Measurement (Vin, Vout, Vds), Current Measurement (IL, Iout, I_MOSFET) → To Workspace |

Topologi: Vin(+) → L → node SW. MOSFET drain di SW, source ke GND. Anoda dioda di SW, katoda ke VOUT. C dan beban dari VOUT ke GND.

Solver: `Ts_pwr = 2e-7` (250 titik per periode). Dengan 1 µs seperti model buck, resolusi duty hanya 2 %, dan ripple Vout ikut bergerigi.

## 2. Model closed-loop (`boost_pid.slx`)

Tambahkan ke model open-loop:

1. Vout (Voltage Measurement) → **Zero-Order Hold** `Ts_ctrl`
2. **Sum**: `Vref` − Vout = error (rekam ke workspace: parameter wajib no. 6)
3. **PID Controller** (Simulink › Continuous/Discrete):
   - Controller: PID, Form: Parallel, Time domain: **Discrete-time**, Sample time `Ts_ctrl`
   - P = `Kp`, I = `Ki`, D = `Kd`, Filter coefficient N = `N`
   - Integrator & filter method: Forward Euler
   - Tab *Output Saturation*: centang Limit output, Upper `D_max`, Lower `D_min`
   - Anti-windup method: **back-calculation**, Back-calculation coefficient Kb = `Kb`
4. Output PID → PWM Generator (DC-DC), menggantikan Constant `D_nom`.

Untuk membandingkan anti-windup, jalankan sekali dengan `Anti-windup method: none` pada start-up dari 0 s. Duty mentok 0,85 saat start, jadi perbedaannya terlihat sebagai overshoot.

## 3. Gangguan beban 32 → 16 Ω pada t = 0,05 s

Pasang dua resistor 32 Ω paralel; satu disambung lewat **Breaker** (Initial state open, Switching times `t_gang`). T_sim minimal 0,1 s.

## 4. Tuning (minimal 5 kombinasi)

Titik awal di skrip (`Kp0, Ki0, Kd0`) berasal dari analisis loop dan simulasi switching untuk spesifikasi ini. Contoh rencana tuning, hasilnya diisi dari simulasimu sendiri:

| No | Kp | Ki | Kd | Tujuan |
|---|---|---|---|---|
| 1 | Kp0 | 0 | 0 | P saja → tunjukkan Ess |
| 2 | Kp0 | Ki0 | 0 | PI → Ess hilang |
| 3 | 3·Kp0 | Ki0 | 0 | Pengaruh Kp: lebih cepat, risiko osilasi |
| 4 | Kp0 | 3·Ki0 | 0 | Pengaruh Ki: overshoot/osilasi naik |
| 5 | Kp0 | Ki0 | Kd0 | Pengaruh Kd: redaman |
| 6 | (pilihan akhir) | | | Berdasarkan Tr, OS, Ts, Ess, ripple |

Boost memiliki **zero RHP** (±1,8 kHz pada beban 32 Ω, lebih rendah pada 16 Ω). Kp dan Ki yang terlalu besar membuat sistem berosilasi atau tidak stabil di beban 16 Ω. Selalu cek kombinasi akhir di **semua** beban dan Vin.

Hasil simulasi switching di luar Simulink dengan titik awal ini (soft-start, untuk perbandingan): Vout tunak 47,9 V, ripple 0,18 Vpp. Gangguan 32 → 16 Ω menghasilkan Vout 44,3–49,9 V dan pulih ke pita ±2 % dalam ±4,2 ms. Angka Simulink-mu akan sedikit berbeda karena start-up dan model komponen tidak sama.

## 5. Pengukuran kinerja

```matlab
% contoh: sinyal tersimpan sebagai timeseries vout
k = hitung_kinerja(vout.Time, vout.Data, Vref, 0, 0.05);      % start-up
g = hitung_kinerja(vout.Time, vout.Data, Vref, t_gang, 0.1);  % setelah gangguan
```

Definisi yang dipakai (tulis di laporan): Tr 10–90 %, Ts pita ±2 % Vref, OS relatif terhadap Vref, ripple = puncak-ke-puncak pada 20 % akhir jendela.

## 6. Skenario wajib (tabel M di PDF)

| Skenario | Vin | Beban | Catat |
|---|---|---|---|
| Nominal | 24 V | 32 Ω | Vout, OS, Ts, Ess, ripple |
| Vin rendah / tinggi | 20 / 28 V | 32 Ω | + duty |
| Beban rendah / tinggi | 24 V | 16 / 64 Ω | + Iout, Pout |
| Gangguan | 24 V | 32 → 16 Ω @ 0,05 s | undershoot, waktu pulih |
| Open-loop vs closed-loop | semua di atas | | perbandingan |
