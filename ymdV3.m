function ymdV3(tiremodel)

addpath('MFeval')
model = mfeval.readTIR(tiremodel);

p = get_excel_value();

figs_before = findall(0, 'Type', 'figure');

run_stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
base_output_dir = fullfile(pwd, 'images', ['run_' run_stamp]);
output_dir = base_output_dir;

i = 1;
while exist(output_dir, 'dir')
    output_dir = sprintf('%s_%02d', base_output_dir, i);
    i = i + 1;
end

mkdir(output_dir);
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

% wheel rate [n/m]
k_wf = (0.5 * (k_spring_f / p.ir_f^2)) / p.t_f^2;
k_wr = (0.5 * (k_spring_r / p.ir_r^2)) / p.t_r^2;

% rigidez ao roll da arb [nm/rad]
k_wr_arb_f = (p.arb_f * p.arb_l_f^2) / (p.arb_ir_f^2 * p.t_f^2);
k_wr_arb_r = (p.arb_r * p.arb_l_r^2) / (p.arb_ir_r^2 * p.t_r^2);

% rigidez total ao roll [nm/rad]
kphi_f = k_wf + k_wr_arb_f;
kphi_r = k_wr + k_wr_arb_r;

% altura da roll axis na posicao do cg [m]
h_ra = p.rc_f + (a / p.wb) * (p.rc_r - p.rc_f);

% distancia vertical entre cg e roll axis [m]
h2 = p.h_cg - h_ra;

% termo corrigido de rigidez ao rolamento [nm/rad]
kphi_f_p = kphi_f - (a * wsn * h2) / p.wb;
kphi_r_p = kphi_r - (b * wsn * h2) / p.wb;

% denominador comum da transferencia de carga [-]
den_roll = kphi_f + kphi_r - wsn * h2;

% carga estatica no eixo [n]
fzf_static = w * b / p.wb;
fzr_static = w * a / p.wb;

% carga estatica por roda [n]
fz_f0 = fzf_static / 2;
fz_r0 = fzr_static / 2;

% inercia de guinada [kg m^2]
izz = (w / p.g) * (p.wb / 2)^2 / 2;

% steering input maximo [deg]
si_max_deg = 14;

% sideslip maximo [deg]
vs_max_deg = 14;

% vetor de steering input [deg -> rad]
si_vec = deg2rad(-si_max_deg : p.si_step : si_max_deg);

% vetor de sideslip [deg -> rad]
vs_vec = deg2rad(-vs_max_deg : p.vs_step : vs_max_deg);

% numero de iteracoes (YMD final)
niter = 8;

% limite do slip angle [rad]
alpha_lim = deg2rad(14);

% -----------------------------------------------------------------------
%  YMD do setup base
% -----------------------------------------------------------------------
[a_lat_g, nz_norm, yawaccel] = run_ymd( ...
    si_vec, vs_vec, niter, alpha_lim, ...
    a, b, vx, m, p.g, ...
    p.t_f, p.t_r, p.wb, ...
    wsn, wufn, wurn, ...
    h2, kphi_f_p, kphi_r_p, den_roll, ...
    p.rc_f, p.rc_r, ...
    fz_f0, fz_r0, ...
    p.gamma_fl, p.gamma_fr, p.gamma_rl, p.gamma_rr, ...
    p.tau_fl, p.tau_fr, p.tau_rl, p.tau_rr, ...
    model, izz, w);

plot_ymd_maps(a_lat_g, nz_norm, yawaccel, p.v_kmh, 'base setup');

% -----------------------------------------------------------------------
%  BUSCA ADAPTATIVA 4D
% -----------------------------------------------------------------------
if p.do_search

    fprintf('\n=== ADAPTIVE GRID SEARCH 4D ===\n');
    fprintf('Variaveis: gamma_f, gamma_r, tau_f, tau_r\n\n');

    ymd_args = { ...
        si_vec, vs_vec, niter, alpha_lim, ...
        a, b, vx, m, p.g, ...
        p.t_f, p.t_r, p.wb, ...
        wsn, wufn, wurn, ...
        h2, kphi_f_p, kphi_r_p, den_roll, ...
        p.rc_f, p.rc_r, ...
        fz_f0, fz_r0, ...
        model, izz, w};

    x_min4 = [p.gamma_f_min, p.gamma_r_min, p.tau_f_min, p.tau_r_min];
    x_max4 = [p.gamma_f_max, p.gamma_r_max, p.tau_f_max, p.tau_r_max];

    n_grid   = 3;
    n_rounds = 4;
    n_keep   = 3;

    [best_x, best_ay, best_bal, search_hist] = adaptive_grid_search( ...
        x_min4, x_max4, ...
        n_grid, n_rounds, n_keep, ...
        ymd_args, p.balance_limit);

    best_gamma_f = best_x(1);
    best_gamma_r = best_x(2);
    best_tau_f   = best_x(3);
    best_tau_r   = best_x(4);

    fprintf('\n--- MELHOR SETUP ENCONTRADO ---\n');
    fprintf('Front camber = %.3f deg\n', best_gamma_f);
    fprintf('Rear  camber = %.3f deg\n', best_gamma_r);
    fprintf('Front toe    = %.3f deg\n', best_tau_f);
    fprintf('Rear  toe    = %.3f deg\n', best_tau_r);
    fprintf('Max ay       = %.4f g\n',   best_ay);
    fprintf('Balance      = %.6f\n',     best_bal);

    if best_bal <= p.balance_limit
        fprintf('Status       = ACCEPTED\n');
    else
        fprintf('Status       = BEST FOUND (fora do limite de balance)\n');
    end

    plot_search_history_4d(search_hist, best_x, n_grid);
    plot_search_surfaces_4d(search_hist, best_x);


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
        sprintf('best | camber F %.2f R %.2f | toe F %.2f R %.2f', ...
        best_gamma_f, best_gamma_r, best_tau_f, best_tau_r));

end
save_generated_figures(output_dir, figs_before);
fprintf('\nFiguras guardadas em: %s\n', output_dir);
end

% =========================================================================
%  helpers locais
% =========================================================================

function plot_ymd_maps(a_lat_g, nz_norm, yawaccel, v_kmh, subtitle_str)

[m_plot, n_plot] = size(nz_norm);
color_vs = [0 0.4470 0.7410];
color_si = [0.8500 0.3250 0.0980];

figure('Name', sprintf('YMD — %s — %d km/h', subtitle_str, v_kmh))
hold on; grid on
for col = 1:n_plot
    plot(a_lat_g(:,col), nz_norm(:,col), 'Color', color_vs, 'LineWidth', 1.5);
end
for row = 1:m_plot
    plot(a_lat_g(row,:), nz_norm(row,:), 'Color', color_si, 'LineWidth', 1.5);
end
xlabel('lateral accel [g]')
ylabel('normalized yaw moment [nz/(w*wb)]')
title(sprintf('YMD — %s — %d km/h', subtitle_str, v_kmh))
legend({'vs = const','si = const'}, 'Location', 'eastoutside')

figure('Name', sprintf('Yaw accel — %s — %d km/h', subtitle_str, v_kmh))
hold on; grid on
for col = 1:n_plot
    plot(a_lat_g(:,col), yawaccel(:,col), 'Color', color_vs, 'LineWidth', 1.5);
end
for row = 1:m_plot
    plot(a_lat_g(row,:), yawaccel(row,:), 'Color', color_si, 'LineWidth', 1.5);
end
xlabel('lateral accel [g]')
ylabel('yaw accel [deg/s^2]')
title(sprintf('Yaw accel — %s — %d km/h', subtitle_str, v_kmh))
legend({'vs = const','si = const'}, 'Location', 'eastoutside')
end


function plot_search_history_4d(history, best_x, n_grid)
% history: [N x 6] — gamma_f, gamma_r, tau_f, tau_r, ay, balance
% Mostra 2 projectoes: (gamma_f vs gamma_r) e (tau_f vs tau_r)

n_per_round = n_grid^4;
n_rounds    = size(history,1) / n_per_round;
colors      = cool(n_rounds);

pairs = {[1,2], [3,4]};
xlabels = {'front camber [deg]', 'front toe [deg]'};
ylabels = {'rear camber [deg]',  'rear toe [deg]'};
tags    = {'camber', 'toe'};

for p = 1:2
    xi = pairs{p}(1);
    yi = pairs{p}(2);

    figure('Name', sprintf('%s search history', tags{p}))
    hold on; grid on

    for r = 1:n_rounds
        idx = (r-1)*n_per_round+1 : r*n_per_round;
        scatter(history(idx, xi), history(idx, yi), 30, ...
            'MarkerFaceColor', colors(r,:), ...
            'MarkerEdgeColor', 'none', ...
            'DisplayName', sprintf('round %d', r));
    end

    plot(best_x(xi), best_x(yi), 'kx', ...
        'MarkerSize', 14, 'LineWidth', 2, 'DisplayName', 'best');

    xlabel(xlabels{p}); ylabel(ylabels{p})
    title(sprintf('%s search history', tags{p}))
    legend('Location', 'eastoutside')
end
end

function plot_search_surfaces_4d(history, best_x)
% history: [gamma_f, gamma_r, tau_f, tau_r, ay, balance]
% best_x : [best_gamma_f, best_gamma_r, best_tau_f, best_tau_r]

gf = history(:,1);
gr = history(:,2);
tf = history(:,3);
tr = history(:,4);
ay = history(:,5);

best_gf = best_x(1);
best_gr = best_x(2);
best_tf = best_x(3);
best_tr = best_x(4);

tol_tf = estimate_tol(tf);
tol_tr = estimate_tol(tr);
tol_gf = estimate_tol(gf);
tol_gr = estimate_tol(gr);

% ------------------------------------------------------------
% surface 1: camber -> ay
% fixa toe perto do melhor setup
% ------------------------------------------------------------
idx_camber = abs(tf - best_tf) <= tol_tf & abs(tr - best_tr) <= tol_tr;

gf_c = gf(idx_camber);
gr_c = gr(idx_camber);
ay_c = ay(idx_camber);

if numel(gf_c) >= 4
    gfq = linspace(min(gf_c), max(gf_c), 40);
    grq = linspace(min(gr_c), max(gr_c), 40);
    [GFQ, GRQ] = meshgrid(gfq, grq);
    AYQ = griddata(gf_c, gr_c, ay_c, GFQ, GRQ, 'natural');

    figure('Name', 'Surface AY vs Camber')
    surf(GFQ, GRQ, AYQ, 'EdgeColor', 'none')
    hold on
    scatter3(gf_c, gr_c, ay_c, 35, ay_c, 'filled')
    plot3(best_gf, best_gr, max(ay_c), 'kx', 'MarkerSize', 14, 'LineWidth', 2)
    xlabel('front camber [deg]')
    ylabel('rear camber [deg]')
    zlabel('lateral accel a_y [g]')
    title('a_y surface vs camber (toe fixed near best)')
    colorbar
    grid on
    view(135, 30)
end

% ------------------------------------------------------------
% surface 2: toe -> ay
% fixa camber perto do melhor setup
% ------------------------------------------------------------
idx_toe = abs(gf - best_gf) <= tol_gf & abs(gr - best_gr) <= tol_gr;

tf_c = tf(idx_toe);
tr_c = tr(idx_toe);
ay_t = ay(idx_toe);

if numel(tf_c) >= 4
    tfq = linspace(min(tf_c), max(tf_c), 40);
    trq = linspace(min(tr_c), max(tr_c), 40);
    [TFQ, TRQ] = meshgrid(tfq, trq);
    AYT = griddata(tf_c, tr_c, ay_t, TFQ, TRQ, 'natural');

    figure('Name', 'Surface AY vs Toe')
    surf(TFQ, TRQ, AYT, 'EdgeColor', 'none')
    hold on
    scatter3(tf_c, tr_c, ay_t, 35, ay_t, 'filled')
    plot3(best_tf, best_tr, max(ay_t), 'kx', 'MarkerSize', 14, 'LineWidth', 2)
    xlabel('front toe [deg]')
    ylabel('rear toe [deg]')
    zlabel('lateral accel a_y [g]')
    title('a_y surface vs toe (camber fixed near best)')
    colorbar
    grid on
    view(135, 30)
end
end


function tol = estimate_tol(x)
u = unique(sort(x));
if numel(u) >= 2
    d = diff(u);
    tol = max(min(d), 1e-6) * 0.51;
else
    tol = 1e-6;
end
end

function save_generated_figures(output_dir, figs_before)

all_figs = findall(0, 'Type', 'figure');
figs = setdiff(all_figs, figs_before);

if isempty(figs)
    warning('Nenhuma figura nova encontrada para guardar.');
    return;
end

for k = 1:numel(figs)

    fig = figs(k);
    fig_name = get(fig, 'Name');

    if isempty(fig_name)
        fig_name = sprintf('figure_%02d', k);
    end

    safe_name = regexprep(fig_name, '[^\w\d-]', '_');
    safe_name = regexprep(safe_name, '_+', '_');
    safe_name = regexprep(safe_name, '^_|_$', '');

    if isempty(safe_name)
        safe_name = sprintf('figure_%02d', k);
    end

    file_name = sprintf('%02d_%s', k, safe_name);

    png_path = fullfile(output_dir, [file_name '.png']);
    fig_path = fullfile(output_dir, [file_name '.fig']);

    drawnow;

    savefig(fig, fig_path);

    try
        exportgraphics(fig, png_path, 'Resolution', 300);
    catch
        saveas(fig, png_path);
    end
end

end