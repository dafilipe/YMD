clear all
close all
clc

C = readcell("inputs.xlsx");

v_kmh = get_excel_value(C, "v_kmh");
g     = get_excel_value(C, "g");
wb    = get_excel_value(C, "wb");
wd    = get_excel_value(C, "wd");
h_cg  = get_excel_value(C, "h_cg");
t_f   = get_excel_value(C, "t_f");
t_r   = get_excel_value(C, "t_r");

k_f   = get_excel_value(C, "k_f");
k_r   = get_excel_value(C, "k_r");
ir_f  = get_excel_value(C, "ir_f");
ir_r  = get_excel_value(C, "ir_r");

arb_f    = get_excel_value(C, "arb_f");
arb_r    = get_excel_value(C, "arb_r");
arb_l_f  = get_excel_value(C, "arb_l_f");
arb_l_r  = get_excel_value(C, "arb_l_r");
arb_ir_f = get_excel_value(C, "arb_ir_f");
arb_ir_r = get_excel_value(C, "arb_ir_r");

rc_f = get_excel_value(C, "rc_f");
rc_r = get_excel_value(C, "rc_r");

ws  = get_excel_value(C, "ws");
wuf = get_excel_value(C, "wuf");
wur = get_excel_value(C, "wur");

gamma_fl = get_excel_value(C, "gamma_fl");
gamma_fr = get_excel_value(C, "gamma_fr");
gamma_rl = get_excel_value(C, "gamma_rl");
gamma_rr = get_excel_value(C, "gamma_rr");

vs_step = get_excel_value(C, "vs");
si_step = get_excel_value(C, "si");

gamma_f_search_start = get_excel_value(C, "gamma_f");
gamma_r_search_start = get_excel_value(C, "gamma_r");
gamma_search_step    = get_excel_value(C, "gamma_step");

do_search = logical(get_excel_value(C, "do_search"));



% ficheiro do pneu [.tir]
tir_file = 'Hoosier 43100 18.0x6.0-10 R20, 7 inch rim.tir';
tire = load_hoosier_tire(tir_file);

% carga nominal do pneu [n]
fz0 = tire.FZ0;

% raio nominal do pneu [m]
r0 = tire.R0;

% parametros laterais [-]
p_fy = tire.P_fy;
p_mz = tire.P_mz;

% massa total do veiculo [kg]
m = ws + wuf + wur;
% peso total do veiculo [n]
w = m * g;

% peso da massa suspensa [n]
wsn = ws * g;

% peso da massa nao suspensa [n]
wufn = wuf * g;
wurn = wur * g;

% distancia cg ao eixo traseiro [m]
b = wb * wd;

% distancia cg ao eixo dianteiro [m]
a = wb * (1 - wd);

% velocidade longitudinal [m/s]
vx = v_kmh / 3.6;


% rigidez da mola [n/m]
k_spring_f = k_f * 1.3558;
k_spring_r = k_r * 1.3558;

% wheel rate  [n/m]
k_wf = (0.5* (k_spring_f / ir_f^2))/t_f^2;
k_wr = (0.5* (k_spring_r / ir_r^2))/t_r^2;

% rigidez ao roll da arb [nm/rad]
k_wr_arb_f = (arb_f*arb_l_f^2)/(arb_ir_f^2 * t_f^2);
k_wr_arb_r = (arb_r*arb_l_r^2)/(arb_ir_r^2 * t_r^2);

% rigidez total ao roll [nm/rad]
kphi_f = k_wf + k_wr_arb_f;
kphi_r = k_wr + k_wr_arb_r;

% altura da roll axis na posicao do cg [m]
h_ra = rc_f + (a / wb) * (rc_r - rc_f);

% distancia vertical entre cg e roll axis [m]
h2 = h_cg - h_ra;

% termo corrigido de rigidez ao rolamento [nm/rad]
kphi_f_p = kphi_f - (a * wsn * h2)/wb;
kphi_r_p = kphi_r - (b * wsn * h2)/wb;

% denominador comum da transferencia de carga [-]
den_roll = kphi_f + kphi_r - wsn * h2;

% carga estatica no eixo  [n]
fzf_static = w * b / wb;

fzr_static = w * a / wb;

% carga estatica por roda [n]
fz_f0 = fzf_static / 2;
fz_r0 = fzr_static / 2;

% inercia de guinada[kg m^2]
izz = (w / g) * (wb / 2)^2 / 2;



% steering input maximo [deg]
si_max_deg = 14;

% sideslip maximo [deg]
vs_max_deg = 14;

% vetor de steering input [deg]
si_vec_deg = -si_max_deg:si_step:si_max_deg;

% vetor de sideslip [deg]
vs_vec_deg = -vs_max_deg:vs_step :vs_max_deg;

% vetor de steering input [rad]
si_vec = deg2rad(si_vec_deg);

% vetor de sideslip [rad]
vs_vec = deg2rad(vs_vec_deg);

% numero de pontos de steering input [-]
nsi = numel(si_vec);

% numero de pontos de sideslip [-]
nvs = numel(vs_vec);

% matriz de aceleracao lateral [m/s^2]
a_lat = zeros(nsi, nvs);

% matriz de momento [nm]
nz = zeros(nsi, nvs);

% matriz de aceleracao [deg/s^2]
yawaccel = zeros(nsi, nvs);

% numero de iteracoes  [-]
niter = 8;

% limite do slip angle [rad]
alpha_lim = deg2rad(14);

[a_lat_g, nz_norm, yawaccel] = run_ydm( ...
    si_vec, vs_vec, niter, alpha_lim, ...
    a, b, vx, m, g, ...
    t_f, t_r, wb, ...
    wsn, wufn, wurn, ...
    h2, kphi_f_p, kphi_r_p, den_roll, ...
    rc_f, rc_r, ...
    fz0, fz_f0, fz_r0, ...
    gamma_fl, gamma_fr, gamma_rl, gamma_rr, ...
    p_fy, p_mz, r0, izz, w);

% numero de linhas da matriz [-]
[m_plot, n_plot] = size(nz_norm);

figure('Name', sprintf('normalized yaw moment - v = %d km/h', v_kmh))
hold on
grid on

% cores
color_vs = [0 0.4470 0.7410];
color_si = [0.8500 0.3250 0.0980];

% curvas VS constante (colunas)
for col = 1:n_plot
    plot(a_lat_g(:, col), nz_norm(:, col), ...
        'Color', color_vs, 'LineWidth', 1.5);
end

% curvas SI constante (linhas)
for row = 1:m_plot
    plot(a_lat_g(row, :), nz_norm(row, :), ...
        'Color', color_si, 'LineWidth', 1.5);
end

xlabel('lateral accel [g]')
ylabel('normalized yaw moment [nz/(w*wb)]')
title(sprintf('normalized yaw moment - v = %d km/h', v_kmh))

legend({'vs = const', 'si = const'}, 'Location', 'eastoutside')

figure('Name', sprintf('yaw accel - v = %d km/h', v_kmh))
hold on
grid on

% curvas VS constante
for col = 1:n_plot
    plot(a_lat_g(:, col), yawaccel(:, col), ...
        'Color', color_vs, 'LineWidth', 1.5);
end

% curvas SI constante
for row = 1:m_plot
    plot(a_lat_g(row, :), yawaccel(row, :), ...
        'Color', color_si, 'LineWidth', 1.5);
end

xlabel('lateral accel [g]')
ylabel('yaw accel [deg/s^2]')
title(sprintf('yaw accel - v = %d km/h', v_kmh))

legend({'vs = const', 'si = const'}, 'Location', 'eastoutside')

if do_search

    gamma_f_vec = gamma_f_search_start:gamma_search_step:0;
    gamma_r_vec = gamma_r_search_start:gamma_search_step:0;

    perf_map = zeros(length(gamma_f_vec), length(gamma_r_vec));
    balance_map = zeros(length(gamma_f_vec), length(gamma_r_vec));

    for ii = 1:length(gamma_f_vec)
        for jj = 1:length(gamma_r_vec)

            gamma_fl_s = gamma_f_vec(ii);
            gamma_fr_s = gamma_f_vec(ii);
            gamma_rl_s = gamma_r_vec(jj);
            gamma_rr_s = gamma_r_vec(jj);

            [a_lat_g_s, nz_norm_s, ~] = run_ydm( ...
                si_vec, vs_vec, niter, alpha_lim, ...
                a, b, vx, m, g, ...
                t_f, t_r, wb, ...
                wsn, wufn, wurn, ...
                h2, kphi_f_p, kphi_r_p, den_roll, ...
                rc_f, rc_r, ...
                fz0, fz_f0, fz_r0, ...
                gamma_fl_s, gamma_fr_s, gamma_rl_s, gamma_rr_s, ...
                p_fy, p_mz, r0, izz, w);

            perf_map(ii, jj) = max(a_lat_g_s(:));

            mask = abs(a_lat_g_s) > 1;
            if any(mask(:))
                balance_map(ii, jj) = mean(abs(nz_norm_s(mask)));
            else
                balance_map(ii, jj) = NaN;
            end
        end
    end

    [max_score, idx] = max(perf_map(:));
    [i_best, j_best] = ind2sub(size(perf_map), idx);

    best_gamma_f = gamma_f_vec(i_best);
    best_gamma_r = gamma_r_vec(j_best);

    fprintf('\n--- SEARCH RESULT ---\n');
    fprintf('Best front camber = %.2f deg\n', best_gamma_f);
    fprintf('Best rear camber  = %.2f deg\n', best_gamma_r);
    fprintf('Best max ay       = %.4f g\n', max_score);

    figure('Name', 'camber performance map')
    contourf(gamma_f_vec, gamma_r_vec, perf_map', 20)
    colorbar
    hold on
    plot(best_gamma_f, best_gamma_r, 'rx', 'MarkerSize', 12, 'LineWidth', 2)
    xlabel('front camber [deg]')
    ylabel('rear camber [deg]')
    title('maximum lateral acceleration [g]')
    grid on

    figure('Name', 'camber performance surface')
    surf(gamma_f_vec, gamma_r_vec, perf_map')
    hold on
    plot3(best_gamma_f, best_gamma_r, max_score, 'rx', 'MarkerSize', 12, 'LineWidth', 2)
    xlabel('front camber [deg]')
    ylabel('rear camber [deg]')
    zlabel('max lateral acceleration [g]')
    title('camber sweep performance map')
    shading interp
    grid on

    figure('Name', 'camber balance map')
    contourf(gamma_f_vec, gamma_r_vec, balance_map', 20)
    colorbar
    xlabel('front camber [deg]')
    ylabel('rear camber [deg]')
    title('balance metric (lower is better)')
    grid on

    [a_lat_g_best, nz_norm_best, yawaccel_best] = run_ydm( ...
        si_vec, vs_vec, niter, alpha_lim, ...
        a, b, vx, m, g, ...
        t_f, t_r, wb, ...
        wsn, wufn, wurn, ...
        h2, kphi_f_p, kphi_r_p, den_roll, ...
        rc_f, rc_r, ...
        fz0, fz_f0, fz_r0, ...
        best_gamma_f, best_gamma_f, best_gamma_r, best_gamma_r, ...
        p_fy, p_mz, r0, izz, w);

    figure('Name', 'yaw accel - best camber')
    hold on
    grid on
    for col = 1:nvs
        plot(a_lat_g_best(:, col), yawaccel_best(:, col), 'b')
    end
    for row = 1:nsi
        plot(a_lat_g_best(row, :), yawaccel_best(row, :), 'r')
    end
    xlabel('lateral accel [g]')
    ylabel('yaw accel [deg/s^2]')
    title('yaw accel with optimal camber')

    figure('Name', 'YMD - best camber')
    hold on
    grid on
    for col = 1:nvs
        plot(a_lat_g_best(:, col), nz_norm_best(:, col), 'b')
    end
    for row = 1:nsi
        plot(a_lat_g_best(row, :), nz_norm_best(row, :), 'r')
    end
    xlabel('lateral accel [g]')
    ylabel('normalized yaw moment')
    title('YMD with optimal camber')
    legend({'vs const','si const'})

end



function val = get_excel_value(C, name)
    [row, col] = find(strcmpi(string(C), name), 1);

    if isempty(row)
        error("Parâmetro '%s' não encontrado no Excel.", name);
    end

    val = C{row, col+1};
end



function [a_lat_g, nz_norm, yawaccel] = run_ydm( ...
    si_vec, vs_vec, niter, alpha_lim, ...
    a, b, vx, m, g, ...
    t_f, t_r, wb, ...
    wsn, wufn, wurn, ...
    h2, kphi_f_p, kphi_r_p, den_roll, ...
    rc_f, rc_r, ...
    fz0, fz_f0, fz_r0, ...
    gamma_fl, gamma_fr, gamma_rl, gamma_rr, ...
    p_fy, p_mz, r0, izz, w)

    nsi = numel(si_vec);
    nvs = numel(vs_vec);

    a_lat = zeros(nsi, nvs);
    nz = zeros(nsi, nvs);
    yawaccel = zeros(nsi, nvs);

    for i = 1:nsi
        si = si_vec(i);

        for j = 1:nvs
            vs = vs_vec(j);

            r = 0;
            a_lat(i, j) = 0;

            for k = 1:niter

                alpha_f = si - vs - (a * r) / vx;
                alpha_r = -vs + (b * r) / vx;

                alpha_f = max(min(alpha_f, alpha_lim), -alpha_lim);
                alpha_r = max(min(alpha_r, alpha_lim), -alpha_lim);

                alpha_fl = alpha_f;
                alpha_fr = alpha_f;
                alpha_rl = alpha_r;
                alpha_rr = alpha_r;

                if k == 1
                    fy_fl = calc_FY(p_fy, fz0, alpha_fl, fz_f0, gamma_fl);
                    fy_fr = calc_FY(p_fy, fz0, alpha_fr, fz_f0, gamma_fr);
                    fy_rl = calc_FY(p_fy, fz0, alpha_rl, fz_r0, gamma_rl);
                    fy_rr = calc_FY(p_fy, fz0, alpha_rr, fz_r0, gamma_rr);

                    fyf = fy_fl + fy_fr;
                    fyr = fy_rl + fy_rr;

                    a_lat(i, j) = (fyf + fyr) / m;
                end

                ay = a_lat(i, j);
                ay_g = ay / g;

                dwf = ay_g * ((wsn / t_f) * (h2 * kphi_f_p / den_roll + (b / wb) * rc_f) + (wufn / t_f) * rc_f);
                dwr = ay_g * ((wsn / t_r) * (h2 * kphi_r_p / den_roll + (a / wb) * rc_r) + (wurn / t_r) * rc_r);

                if ay >= 0
                    fz_fl = max(fz_f0 - dwf / 2, 0);
                    fz_fr = max(fz_f0 + dwf / 2, 0);
                    fz_rl = max(fz_r0 - dwr / 2, 0);
                    fz_rr = max(fz_r0 + dwr / 2, 0);
                else
                    fz_fl = max(fz_f0 + dwf / 2, 0);
                    fz_fr = max(fz_f0 - dwf / 2, 0);
                    fz_rl = max(fz_r0 + dwr / 2, 0);
                    fz_rr = max(fz_r0 - dwr / 2, 0);
                end

                fy_fl = calc_FY(p_fy, fz0, alpha_fl, fz_fl, gamma_fl);
                fy_fr = calc_FY(p_fy, fz0, alpha_fr, fz_fr, gamma_fr);
                fy_rl = calc_FY(p_fy, fz0, alpha_rl, fz_rl, gamma_rl);
                fy_rr = calc_FY(p_fy, fz0, alpha_rr, fz_rr, gamma_rr);

                fyf = fy_fl + fy_fr;
                fyr = fy_rl + fy_rr;

                a_lat(i, j) = (fyf + fyr) / m;

                
                mz_fl = calc_MZ(p_mz, p_fy, fz0, alpha_fl, fz_fl, gamma_fl, r0);
                mz_fr = calc_MZ(p_mz, p_fy, fz0, alpha_fr, fz_fr, gamma_fr, r0);
                mz_rl = calc_MZ(p_mz, p_fy, fz0, alpha_rl, fz_rl, gamma_rl, r0);
                mz_rr = calc_MZ(p_mz, p_fy, fz0, alpha_rr, fz_rr, gamma_rr, r0);

                mzf = mz_fl + mz_fr;
                mzr = mz_rl + mz_rr;

                nz(i, j) = fyf * a * cos(si) - fyr * b - mzf - mzr;

                yawaccel(i, j) = nz(i, j) / izz * 180 / pi;

                r = a_lat(i, j) / vx;
            end
        end
    end

    nz_norm = nz / (w * wb);
    a_lat_g = a_lat / g;
end