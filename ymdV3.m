function ymdV3 (tiremodel)


addpath ('MFeval')
model = mfeval.readTIR(tiremodel);

p = get_excel_value();
p.n_map_points = 15;
p.balance_limit = 0.05;

% massa total do veiculo [kg]
m = p.ws + p.wuf + p.wur;
% peso total do veiculo [n]
w = m * p.g;

% peso da massa suspensa [n]
wsn = p.ws * p.g;

% peso da massa nao suspensa [n]
wufn = p.wuf * p.g;
wurn = p.wur * p.g;

% distancia cg ao eixo traseiro [m]
b = p.wb * p.wd;

% distancia cg ao eixo dianteiro [m]
a = p.wb * (1 - p.wd);

% velocidade longitudinal [m/s]
vx = p.v_kmh / 3.6;


% rigidez da mola [n/m]
k_spring_f = p.k_f * 1.3558;
k_spring_r = p.k_r * 1.3558;

% wheel rate  [n/m]
k_wf = (0.5* (k_spring_f / p.ir_f^2))/p.t_f^2;
k_wr = (0.5* (k_spring_r / p.ir_r^2))/p.t_r^2;

% rigidez ao roll da arb [nm/rad]
k_wr_arb_f = (p.arb_f*p.arb_l_f^2)/(p.arb_ir_f^2 * p.t_f^2);
k_wr_arb_r = (p.arb_r*p.arb_l_r^2)/(p.arb_ir_r^2 * p.t_r^2);

% rigidez total ao roll [nm/rad]
kphi_f = k_wf + k_wr_arb_f;
kphi_r = k_wr + k_wr_arb_r;

% altura da roll axis na posicao do cg [m]
h_ra = p.rc_f + (a / p.wb) * (p.rc_r - p.rc_f);

% distancia vertical entre cg e roll axis [m]
h2 = p.h_cg - h_ra;

% termo corrigido de rigidez ao rolamento [nm/rad]
kphi_f_p = kphi_f - (a * wsn * h2)/p.wb;
kphi_r_p = kphi_r - (b * wsn * h2)/p.wb;

% denominador comum da transferencia de carga [-]
den_roll = kphi_f + kphi_r - wsn * h2;

% carga estatica no eixo  [n]
fzf_static = w * b / p.wb;

fzr_static = w * a / p.wb;

% carga estatica por roda [n]
fz_f0 = fzf_static / 2;
fz_r0 = fzr_static / 2;

% inercia de guinada[kg m^2]
izz = (w / p.g) * (p.wb / 2)^2 / 2;

% steering input maximo [deg]
si_max_deg = 14;

% sideslip maximo [deg]
vs_max_deg = 14;

% vetor de steering input [deg]
si_vec_deg = -si_max_deg:p.si_step:si_max_deg;

% vetor de sideslip [deg]
vs_vec_deg = -vs_max_deg:p.vs_step :vs_max_deg;

% vetor de steering input [rad]
si_vec = deg2rad(si_vec_deg);

% vetor de sideslip [rad]
vs_vec = deg2rad(vs_vec_deg);

% numero de pontos de steering input [-]
nsi = numel(si_vec);

% numero de pontos de sideslip [-]
nvs = numel(vs_vec);

% % matriz de aceleracao lateral [m/s^2]
% a_lat = zeros(nsi, nvs);
% 
% % matriz de momento [nm]
% nz = zeros(nsi, nvs);
% 
% % matriz de aceleracao [deg/s^2]
% yawaccel = zeros(nsi, nvs);

% numero de iteracoes  [-]
niter = 8;

% limite do slip angle [rad]
alpha_lim = deg2rad(14);

[a_lat_g, nz_norm, yawaccel] = run_ymd( ...
    si_vec, vs_vec, niter, alpha_lim, ...
    a, b, vx, m, p.g, ...
    p.t_f, p.t_r, p.wb, ...
    wsn, wufn, wurn, ...
    h2, kphi_f_p, kphi_r_p, den_roll, ...
    p.rc_f, p.rc_r, ...
    fz_f0, fz_r0, ...
    p.gamma_fl, p.gamma_fr, p.gamma_rl, p.gamma_rr, ...
    p.tau_fl,p.tau_fr,p.tau_rl,p.tau_rr, ...
    model, izz, w);

% numero de linhas da matriz [-]
[m_plot, n_plot] = size(nz_norm);

figure('Name', sprintf('normalized yaw moment - v = %d km/h', p.v_kmh))
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
title(sprintf('normalized yaw moment - v = %d km/h', p.v_kmh))

legend({'vs = const', 'si = const'}, 'Location', 'eastoutside')

figure('Name', sprintf('yaw accel - v = %d km/h', p.v_kmh))
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
title(sprintf('yaw accel - v = %d km/h', p.v_kmh))

legend({'vs = const', 'si = const'}, 'Location', 'eastoutside')

if p.do_search
    fprintf('\n--- ADAPTIVE GRID SEARCH ---\n');

    n_grid   = 7;
    n_rounds = 3;
    n_keep   = 3;

    ymd_args = { ...
        si_vec, vs_vec, niter, alpha_lim, ...
        a, b, vx, m, p.g, ...
        p.t_f, p.t_r, p.wb, ...
        wsn, wufn, wurn, ...
        h2, kphi_f_p, kphi_r_p, den_roll, ...
        p.rc_f, p.rc_r, ...
        fz_f0, fz_r0, ...
        model, izz, w};

    tau_f_base = (p.tau_fl + p.tau_fr) / 2;
    tau_r_base = (p.tau_rl + p.tau_rr) / 2;

    % --- CAMBER ---
    fprintf('\nCAMBER SEARCH\n');
    [best_camber, best_camber_ay, best_camber_bal, camber_hist] = adaptive_grid_search( ...
        [p.gamma_f_min, p.gamma_r_min], ...
        [p.gamma_f_max, p.gamma_r_max], ...
        n_grid, n_rounds, n_keep, ...
        [tau_f_base, tau_r_base], [3, 4], ...
        ymd_args, p.balance_limit);

    best_gamma_f = best_camber(1);
    best_gamma_r = best_camber(2);

    fprintf('Front camber = %.3f deg\n', best_gamma_f);
    fprintf('Rear  camber = %.3f deg\n', best_gamma_r);
    fprintf('Max ay       = %.4f g\n',   best_camber_ay);
    fprintf('Balance      = %.6f\n',     best_camber_bal);

    % --- TOE ---
    fprintf('\nTOE SEARCH\n');
    [best_toe, best_toe_ay, best_toe_bal, toe_hist] = adaptive_grid_search( ...
        [p.tau_f_min, p.tau_r_min], ...
        [p.tau_f_max, p.tau_r_max], ...
        n_grid, n_rounds, n_keep, ...
        [best_gamma_f, best_gamma_r], [1, 2], ...
        ymd_args, p.balance_limit);

    best_tau_f = best_toe(1);
    best_tau_r = best_toe(2);

    fprintf('\n--- BEST FINAL SETUP ---\n');
    fprintf('Front camber = %.3f deg\n', best_gamma_f);
    fprintf('Rear  camber = %.3f deg\n', best_gamma_r);
    fprintf('Front toe    = %.3f deg\n', best_tau_f);
    fprintf('Rear  toe    = %.3f deg\n', best_tau_r);
    fprintf('Max ay       = %.4f g\n',   best_toe_ay);
    fprintf('Balance      = %.6f\n',     best_toe_bal);

    if best_toe_bal <= p.balance_limit
        fprintf('Status       = ACCEPTED\n');
    else
        fprintf('Status       = BEST FOUND, BUT OUTSIDE BALANCE LIMIT\n');
    end

    % plot do historico de busca
    plot_search_history(camber_hist, best_gamma_f, best_gamma_r, ...
        'camber', 'front camber [deg]', 'rear camber [deg]');

    plot_search_history(toe_hist, best_tau_f, best_tau_r, ...
        'toe', 'front toe [deg]', 'rear toe [deg]');

    % YMD do melhor setup
    [a_lat_g_best, nz_norm_best, yawaccel_best] = run_ymd( ...
        si_vec, vs_vec, niter, alpha_lim, ...
        a, b, vx, m, p.g, ...
        p.t_f, p.t_r, p.wb, ...
        wsn, wufn, wurn, ...
        h2, kphi_f_p, kphi_r_p, den_roll, ...
        p.rc_f, p.rc_r, ...
        fz_f0, fz_r0, ...
        best_gamma_f, best_gamma_f, best_gamma_r, best_gamma_r, ...
        best_tau_f,   best_tau_f,   best_tau_r,   best_tau_r, ...
        model, izz, w);

    plot_ymd_maps(a_lat_g_best, nz_norm_best, yawaccel_best, p.v_kmh, ...
        sprintf('best setup | camber F %.2f R %.2f | toe F %.2f R %.2f', ...
        best_gamma_f, best_gamma_r, best_tau_f, best_tau_r));

end
end
function plot_search_history(history, x_best, y_best, tag, xl, yl)
% history: [v1, v2, ay, balance]

n_rounds = size(history, 1) / 49;   % assumindo 7x7

colors = cool(n_rounds);

figure('Name', sprintf('%s search history', tag))
hold on; grid on

for r = 1:n_rounds
    idx = (r-1)*49+1 : r*49;
    scatter(history(idx,1), history(idx,2), 40, ...
        'MarkerFaceColor', colors(r,:), ...
        'MarkerEdgeColor', 'none', ...
        'DisplayName', sprintf('round %d', r));
end

plot(x_best, y_best, 'kx', 'MarkerSize', 14, 'LineWidth', 2, ...
    'DisplayName', 'best');

xlabel(xl); ylabel(yl)
title(sprintf('%s search history', tag))
legend('Location', 'eastoutside')
end