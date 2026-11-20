function k = hitung_kinerja(t, y, yref, t0, t1)
%HITUNG_KINERJA  Tr, Tp, %OS, Ts (2 %), Ess, ripple dari sinyal Vout.
%   k = hitung_kinerja(t, vout, 48, 0, 0.05)  -> analisis jendela [t0, t1)
%   Tidak butuh toolbox. Ripple diukur pada 20 % akhir jendela.
%   Tr: 10 % -> 90 % dari nilai akhir; Ts: masuk dan tetap di pita +/-2 % Vref.
m  = t >= t0 & t < t1;  t = t(m) - t0;  y = y(m);
n  = numel(y);  ss = y(round(0.8*n):end);
yf = mean(ss);  y0 = y(1);  dy = yf - y0;
k.Vss    = yf;
k.Ess    = yref - yf;
k.ripple = max(ss) - min(ss);
i10 = find((y - y0) >= 0.1*dy, 1);  i90 = find((y - y0) >= 0.9*dy, 1);
if isempty(i10) || isempty(i90), k.Tr = NaN; else, k.Tr = t(i90) - t(i10); end
[yp, ip] = max(y);  k.Tp = t(ip);
k.OS = max(0, (yp - yref)/yref*100);
out = find(abs(y - yref) > 0.02*yref);
if isempty(out), k.Ts = 0; elseif out(end) == n, k.Ts = NaN; else, k.Ts = t(out(end) + 1); end
fprintf('Tr %.3f ms | Tp %.3f ms | OS %.2f %% | Ts %.3f ms | Ess %.4f V | ripple %.3f Vpp\n', ...
    k.Tr*1e3, k.Tp*1e3, k.OS, k.Ts*1e3, k.Ess, k.ripple);
end
