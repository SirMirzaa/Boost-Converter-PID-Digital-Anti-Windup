%% uji_skenario.m
% Menjalankan skenario wajib PBL-B dengan gain PID akhir (Tugas 6, 7, 8),
% menyusun tabel format M dari PDF, membandingkan dengan open-loop,
% dan menyimpan grafik untuk laporan.
%
% Syarat di model boost_pid.slx:
%   - DC Voltage Source = Vin_nom, kapasitor Initial voltage = Vc0
%   - Resistor beban = R_nom
%   - Beban gangguan: resistor R_nom seri Breaker
%     (Initial status 0, Switching times [t_gang]) paralel dengan beban
%   - To Workspace "vout" (Timeseries). Opsional: To Workspace "duty"
%     di output PID (Timeseries) untuk kolom duty cycle.
% Opsional: boost_openloop.slx dengan To Workspace "vout" untuk perbandingan.

clear; clc; close all;
param_boost_pblb;
Ts_pwr = 2e-7;               % data final laporan (ganti 5e-7 untuk uji cepat)
model  = 'boost_pid';
model_ol = 'boost_openloop';

%% Gain akhir (hasil tuning: percobaan #6)
Kp = Kp0;  Ki = Ki0;  Kd = 2*Kd0;

%% Daftar skenario: nama, Vin, R, gangguan (1 = beban 32 -> 16 ohm pada t_gang)
S = { 'Nominal',       24, 32, 0
      'Vin rendah',    20, 32, 0
      'Vin tinggi',    28, 32, 0
      'Beban rendah',  24, 16, 0
      'Beban tinggi',  24, 64, 0
      'Gangguan',      24, 32, 1 };
nS = size(S, 1);
t_gang_asli = t_gang;

Vout = nan(nS,1); OS = Vout; Ts = Vout; Ess = Vout; Rip = Vout; Duty = Vout;
Iout = Vout; Pout = Vout; Tr = Vout; Under = Vout; Pulih = Vout; Vol = Vout;
data = struct('t', {}, 'v', {}, 'tol', {}, 'vol', {});

load_system(model);
for i = 1:nS
    Vin_nom = S{i,2};  R_nom = S{i,3};  Vc0 = Vin_nom;
    if S{i,4}, t_gang = t_gang_asli; else, t_gang = 10*T_sim; end  % breaker tidak pernah menutup
    fprintf('\n=== %s: Vin %d V, R %d ohm ===\n', S{i,1}, Vin_nom, R_nom);

    so = sim(model, 'ReturnWorkspaceOutputs', 'on');
    vo = so.get('vout');
    t = vo.Time;  v = vo.Data;
    data(i).t = t;  data(i).v = v;

    % kinerja start-up: jendela 0 .. t_gang_asli
    k = hitung_kinerja(t, v, Vref, 0, t_gang_asli);
    Tr(i) = k.Tr*1e3;  OS(i) = k.OS;  Ts(i) = k.Ts*1e3;
    Ess(i) = k.Ess;  Rip(i) = k.ripple;  Vout(i) = k.Vss;
    Iout(i) = Vout(i)/R_nom;  Pout(i) = Vout(i)*Iout(i);

    du = [];
    try, du = so.get('duty'); catch, end
    if ~isempty(du)
        m = du.Time >= 0.8*t_gang_asli & du.Time < t_gang_asli;
        Duty(i) = mean(du.Data(m));
    end

    % kinerja setelah gangguan
    if S{i,4}
        m = t >= t_gang_asli;
        tg = t(m) - t_gang_asli;  vg = v(m);
        Under(i) = Vref - min(vg);                       % V
        luar = find(abs(vg - Vref) > 0.02*Vref);
        if isempty(luar), Pulih(i) = 0;
        elseif luar(end) == numel(vg), Pulih(i) = NaN;
        else, Pulih(i) = tg(luar(end) + 1)*1e3;          % ms
        end
        ss = vg(tg >= 0.8*tg(end));
        Vout(i) = mean(ss);  Rip(i) = max(ss) - min(ss);  Ess(i) = Vref - Vout(i);
        Iout(i) = Vout(i)/(R_nom/2);  Pout(i) = Vout(i)*Iout(i);
        fprintf('Gangguan: undershoot %.3f V, pulih ke +/-2%% dalam %.3f ms\n', Under(i), Pulih(i));
    end
end
t_gang = t_gang_asli;

%% Open-loop untuk perbandingan (duty tetap D_nom)
ada_ol = exist([model_ol '.slx'], 'file') == 4;
if ada_ol
    load_system(model_ol);
    for i = 1:nS
        if S{i,4}, continue; end
        Vin_nom = S{i,2};  R_nom = S{i,3};  Vc0 = Vin_nom;
        try
            so = sim(model_ol, 'ReturnWorkspaceOutputs', 'on');
            vo = so.get('vout');
            data(i).tol = vo.Time;  data(i).vol = vo.Data;
            m = vo.Time >= 0.8*T_sim;
            Vol(i) = mean(vo.Data(m));
        catch e
            fprintf('Open-loop dilewati (%s)\n', e.message);  ada_ol = false;  break;
        end
    end
end
Vin_nom = 24;  R_nom = 32;  Vc0 = Vin_nom;   % kembalikan nilai nominal

%% Tabel format M (PDF)
Skenario = S(:,1);
VinT = cell2mat(S(:,2));  Beban = S(:,3);
Beban(cell2mat(S(:,4)) == 1) = {'32 -> 16'};
Beban = cellfun(@num2str, Beban, 'UniformOutput', false);
T = table(Skenario, VinT, Beban, repmat(Vref,nS,1), repmat(Kp,nS,1), repmat(Ki,nS,1), ...
    repmat(Kd,nS,1), Vout, OS, Ts, Ess, Rip, Duty, Iout, Pout, Tr, Under, Pulih, Vol, ...
    'VariableNames', {'Skenario','Vin_V','Beban_ohm','Vref_V','Kp','Ki','Kd','Vout_V', ...
    'OS_persen','Ts_ms','Ess_V','Ripple_Vpp','Duty','Iout_A','Pout_W','Tr_ms', ...
    'Undershoot_V','Pulih_ms','Vout_openloop_V'});
disp(T);
writetable(T, 'hasil_skenario.csv');
save('hasil_skenario.mat', 'T', 'data', 'S');

lewat = find(Rip > dV_maks);
if ~isempty(lewat)
    fprintf('Ripple melebihi %.2f Vpp pada: %s\n', dV_maks, strjoin(S(lewat,1)', ', '));
end

%% Grafik untuk laporan
simpan = @(nama) exportgraphics(gcf, nama, 'Resolution', 200);
if ~exist('exportgraphics', 'file'), simpan = @(nama) saveas(gcf, nama); end
band = @() [yline(Vref,'k--','HandleVisibility','off'), ...
            yline(1.02*Vref,':','Color',[.5 .5 .5],'HandleVisibility','off'), ...
            yline(0.98*Vref,':','Color',[.5 .5 .5],'HandleVisibility','off')];

grup = { [1 4 5], 'Perubahan beban (Vin 24 V)',       'skenario_beban.png'
         [2 1 3], 'Perubahan tegangan masukan (R 32 \Omega)', 'skenario_vin.png' };
for g = 1:size(grup,1)
    figure('Color','w','Position',[100 100 900 420]); hold on; grid on; box on;
    for i = grup{g,1}
        plot(data(i).t*1e3, data(i).v, 'LineWidth', 1.1, ...
            'DisplayName', sprintf('%s (Vin %d V, R %d \\Omega)', S{i,1}, S{i,2}, S{i,3}));
    end
    band(); xlim([0 t_gang_asli*1e3]); ylim([20 55]);
    xlabel('Waktu (ms)'); ylabel('V_{out} (V)'); title(grup{g,2});
    legend('Location','southeast'); simpan(grup{g,3});
end

% Gangguan: penuh + zoom
i = find(cell2mat(S(:,4)) == 1, 1);
figure('Color','w','Position',[100 100 900 600]);
subplot(2,1,1); plot(data(i).t*1e3, data(i).v, 'LineWidth', 1.1); hold on; grid on; band();
xline(t_gang_asli*1e3, 'r--', 'Beban 32 \rightarrow 16 \Omega');
ylabel('V_{out} (V)'); title('Uji gangguan beban'); ylim([20 55]);
subplot(2,1,2); plot(data(i).t*1e3, data(i).v, 'LineWidth', 1.1); hold on; grid on; band();
xlim([t_gang_asli t_gang_asli+0.015]*1e3); ylim([40 52]);
xlabel('Waktu (ms)'); ylabel('V_{out} (V)'); title('Zoom sekitar gangguan');
simpan('skenario_gangguan.png');

% Open-loop vs closed-loop (nominal)
if ada_ol && ~isempty(data(1).tol)
    figure('Color','w','Position',[100 100 900 420]); hold on; grid on; box on;
    plot(data(1).tol*1e3, data(1).vol, 'LineWidth', 1.1, 'DisplayName', 'Open-loop (D = 0,5)');
    plot(data(1).t*1e3,   data(1).v,   'LineWidth', 1.1, 'DisplayName', 'Closed-loop PID');
    band(); ylim([20 70]);
    xlabel('Waktu (ms)'); ylabel('V_{out} (V)');
    title('Open-loop vs closed-loop PID (Vin 24 V, R 32 \Omega)');
    legend('Location','southeast'); simpan('openloop_vs_closedloop.png');
end

fprintf('\nSelesai. Tabel: hasil_skenario.csv | Grafik: skenario_*.png, openloop_vs_closedloop.png\n');