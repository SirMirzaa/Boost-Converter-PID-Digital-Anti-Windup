%% tuning_pid.m
% Menjalankan 8 kombinasi PID pada model boost_pid.slx secara otomatis,
% lalu menyusun tabel Tr, Tp, OS, Ts, Ess, ripple untuk laporan (Tugas 5).
%
% Syarat:
%   - File ini, param_boost_pblb.m, hitung_kinerja.m, dan boost_pid.slx
%     ada di folder yang sama, dan folder itu menjadi Current Folder.
%   - Model punya blok To Workspace bernama "vout" (Save format: Timeseries).
%   - Blok PID memakai variabel Kp, Ki, Kd, N, Kb.
%
% Keluaran:
%   - Tabel di Command Window
%   - hasil_tuning.csv  (buka di Excel / salin ke laporan)
%   - hasil_tuning.mat  (data Vout tiap kombinasi, untuk grafik perbandingan)
%   - tuning_perbandingan_vout.png

clear; clc; close all;
param_boost_pblb;            % muat semua parameter
Ts_pwr = 5e-7;               % step tuning (data final laporan pakai 2e-7)
model  = 'boost_pid';
t_awal = 0;  t_akhir = 0.05; % jendela analisis: start-up sampai sebelum gangguan

%% Daftar kombinasi: [Kp  Ki  Kd]   (ubah di sini bila perlu)
K = [ Kp0     0       0
      Kp0     Ki0     0
      3*Kp0   Ki0     0
      Kp0     3*Ki0   0
      Kp0     Ki0     Kd0
      Kp0     Ki0     2*Kd0
      3*Kp0   Ki0     Kd0
      Kp0     2*Ki0   Kd0 ];
ket = { 'P saja'
        'PI'
        'PI, Kp x3'
        'PI, Ki x3'
        'PID awal'
        'PID, Kd x2'
        'PID, Kp x3'
        'PID, Ki x2' };
idx_pid = 5:8;   % kombinasi PID (stabil) untuk grafik kedua

nK = size(K, 1);
Tr = nan(nK,1); Tp = Tr; OS = Tr; Ts = Tr; Ess = Tr; Vss = Tr; Rip = Tr;
data = struct('t', {}, 'v', {});

load_system(model);
for i = 1:nK
    Kp = K(i,1);  Ki = K(i,2);  Kd = K(i,3);
    fprintf('\n=== Percobaan %d (%s): Kp = %.3g, Ki = %.3g, Kd = %.3g ===\n', ...
        i, ket{i}, Kp, Ki, Kd);
    simOut = sim(model, 'ReturnWorkspaceOutputs', 'on');
    vo = simOut.get('vout');
    data(i).t = vo.Time;
    data(i).v = vo.Data;
    k = hitung_kinerja(vo.Time, vo.Data, Vref, t_awal, t_akhir);
    Tr(i) = k.Tr*1e3;  Tp(i) = k.Tp*1e3;  OS(i) = k.OS;  Ts(i) = k.Ts*1e3;
    Ess(i) = k.Ess;    Vss(i) = k.Vss;    Rip(i) = k.ripple;
end

%% Tabel hasil
Percobaan = (1:nK)';
Keterangan = ket;
Kp_ = K(:,1); Ki_ = K(:,2); Kd_ = K(:,3);
T = table(Percobaan, Kp_, Ki_, Kd_, Tr, Tp, OS, Ts, Ess, Vss, Rip, Keterangan, ...
    'VariableNames', {'Percobaan','Kp','Ki','Kd','Tr_ms','Tp_ms','OS_persen', ...
                      'Ts_ms','Ess_V','Vss_V','Ripple_Vpp','Keterangan'});
fprintf('\n');
disp(T);
writetable(T, 'hasil_tuning.csv');
save('hasil_tuning.mat', 'T', 'data', 'K', 'ket');

% Tandai ripple yang melebihi batas spesifikasi
lewat = find(Rip > dV_maks);
if ~isempty(lewat)
    fprintf('Ripple melebihi %.2f Vpp pada percobaan: %s\n', dV_maks, mat2str(lewat'));
end

%% Grafik perbandingan Vout (untuk laporan)
% Gambar 1: semua kombinasi; Gambar 2: hanya kombinasi PID (zoom sekitar Vref)
grafik = { 1:nK,    [0 70],  'tuning_perbandingan_vout.png',     'semua kombinasi'
           idx_pid, [40 52], 'tuning_perbandingan_vout_pid.png', 'kombinasi PID' };
for g = 1:size(grafik, 1)
    figure('Color', 'w', 'Position', [100 100 900 450]);
    hold on; grid on; box on;
    for i = grafik{g,1}
        m = data(i).t <= t_akhir;
        plot(data(i).t(m)*1e3, data(i).v(m), 'LineWidth', 1.2, ...
            'DisplayName', sprintf('#%d %s', i, ket{i}));
    end
    yline(Vref, 'k--', 'Vref = 48 V', 'HandleVisibility', 'off');
    yline(Vref*1.02, ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
    yline(Vref*0.98, ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
    ylim(grafik{g,2});
    xlabel('Waktu (ms)'); ylabel('V_{out} (V)');
    title(sprintf('Respons V_{out}, %s (Vin 24 V, R 32 \\Omega)', grafik{g,4}));
    legend('Location', 'southeast');
    if exist('exportgraphics', 'file')
        exportgraphics(gcf, grafik{g,3}, 'Resolution', 200);
    else
        saveas(gcf, grafik{g,3});
    end
end

% Kembalikan gain ke titik awal agar model siap dipakai lagi
Kp = Kp0; Ki = Ki0; Kd = Kd0;
fprintf(['\nSelesai. Hasil disimpan di hasil_tuning.csv, hasil_tuning.mat,\n' ...
         'tuning_perbandingan_vout.png, dan tuning_perbandingan_vout_pid.png\n']);