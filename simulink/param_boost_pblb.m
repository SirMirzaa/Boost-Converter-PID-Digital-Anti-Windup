clear; clc;
%% 1. Spesifikasi
Vin_nom = 24;            % V
Vin_uji = [20 24 28];    % V
Vref    = 48;            % V
fsw     = 20e3;          % Hz
R_nom   = 32;            % ohm
R_uji   = [16 32 64];    % ohm
dV_maks = 0.02*Vref;     % 0,96 Vpp
t_gang  = 0.05;          % s, gangguan 32 -> 16 ohm

%% 2. Perhitungan perancangan (ideal, CCM)
D_nom   = 1 - Vin_nom/Vref;              % 0,50
Iout    = Vref/R_nom;                    % 1,5 A
Pout    = Vref*Iout;                     % 72 W
IL_nom  = Iout/(1 - D_nom);              % 3,0 A
dIL_tgt = 0.30*IL_nom;                   % target ripple arus 30 %
L_hit   = Vin_nom*D_nom/(dIL_tgt*fsw);   % 666,7 uH
L       = 680e-6;                        % nilai standar terdekat di atasnya

% Kapasitor: kasus terberat Iout*D (Vin 20 V, R 16 ohm), target 50 % batas ripple
D_wc    = 1 - min(Vin_uji)/Vref;
Iout_wc = Vref/min(R_uji);
dV_tgt  = 0.5*dV_maks;
C_hit   = Iout_wc*D_wc/(fsw*dV_tgt);     % 182 uF
C       = 220e-6;                        % nilai standar terdekat di atasnya

dIL     = Vin_nom*D_nom/(L*fsw);         % ripple arus dengan L terpilih
dV_nom  = Iout*D_nom/(C*fsw);            % ripple tegangan nominal (C ideal)
dV_wc   = Iout_wc*D_wc/(C*fsw);          % ripple tegangan kasus terberat

% Cek CCM di beban teringan (64 ohm) untuk semua Vin
ccm_ok = true;
for v = Vin_uji
    d  = 1 - v/Vref;
    il = (Vref/max(R_uji))/(1 - d);
    if il - v*d/(2*L*fsw) <= 0, ccm_ok = false; end
end

%% 3. Asumsi non-ideal model (cantumkan di laporan, Bab IV)
Ron_Q  = 0.023;   % ohm, Rds(on) IRF3710 (default blok MOSFET = 0,1 ohm)
Ron_D  = 0.01;    % ohm
Vf_D   = 0.6;     % V, Schottky MBR20100CT (default blok Diode = 0,8 V)
R_L    = 0.05;    % ohm, resistansi kawat induktor
ESR_C  = 0.03;    % ohm
Vc0    = Vin_nom; % V, tegangan awal C (= Vin lewat dioda saat start)

%% 4. Simulasi dan kontrol
Ts_pwr  = 5e-7;   % s, step powergui (min. 250 titik per periode PWM)
Ts_ctrl = 1/fsw;  % 50 us: PID diupdate sekali per periode PWM (sama dgn firmware)
T_sim   = 0.1;    % s
D_min   = 0;  D_max = 0.85;

% Titik awal tuning 
Kp0 = 1.4e-3;  Ki0 = 6.1;  Kd0 = 6.6e-6;  N0 = 1e4;  Kb0 = 4000;
Kp = Kp0; Ki = Ki0; Kd = Kd0; N = N0; Kb = Kb0;   % ubah saat tuning

%% 5. Ringkasan untuk tabel laporan
fprintf('D nominal          = %.3f\n', D_nom);
fprintf('Iout / Pout        = %.2f A / %.1f W\n', Iout, Pout);
fprintf('IL nominal         = %.2f A\n', IL_nom);
fprintf('L hitung / pakai   = %.1f uH / %.0f uH\n', L_hit*1e6, L*1e6);
fprintf('Ripple arus (pakai)= %.3f A pp (%.0f %% IL)\n', dIL, 100*dIL/IL_nom);
fprintf('C hitung / pakai   = %.1f uF / %.0f uF\n', C_hit*1e6, C*1e6);
fprintf('Ripple V nominal   = %.3f Vpp (batas %.2f)\n', dV_nom, dV_maks);
fprintf('Ripple V terberat  = %.3f Vpp (Vin %d V, R %d ohm)\n', dV_wc, min(Vin_uji), min(R_uji));
fprintf('CCM 16-64 ohm      = %d\n', ccm_ok);
