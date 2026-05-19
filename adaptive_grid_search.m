function [best_x, best_ay, best_bal, x_history] = adaptive_grid_search( ...
    x_min, x_max, ...
    n_grid, n_rounds, n_keep, ...
    ymd_args, balance_limit)
% ADAPTIVE_GRID_SEARCH  busca 4D direta (camber + toe simultaneamente)
%                       com refinamento iterativo da janela de busca.
%
%   x_min, x_max   : vetores [1x4] — [gamma_f, gamma_r, tau_f, tau_r]
%   n_grid         : pontos por dimensao (recomendado: 5)
%   n_rounds       : rounds de refinamento (recomendado: 3)
%   n_keep         : top-K pontos para definir nova janela (recomendado: 3)
%   ymd_args       : cell array de argumentos para evaluate_ymd_setup
%   balance_limit  : limite de balance aceitavel
%
%   NOTA: interface simplificada — nao ha mais fixed_vals/fixed_idx
%         a busca e sempre 4D completa (ponto A).

% --- sanidade ---
assert(numel(x_min) == 4 && numel(x_max) == 4, ...
    'x_min e x_max devem ser vetores [1x4]: [gamma_f, gamma_r, tau_f, tau_r]');

bounds_min = x_min(:)';
bounds_max = x_max(:)';

best_x     = [];
best_ay    = -inf;
best_bal   = inf;
best_score = -inf;

x_history = [];

for round = 1:n_rounds

    fprintf('  round %d/%d\n', round, n_rounds);
    fprintf('    gamma_f [%.3f  %.3f]  gamma_r [%.3f  %.3f]\n', ...
        bounds_min(1), bounds_max(1), bounds_min(2), bounds_max(2));
    fprintf('    tau_f   [%.3f  %.3f]  tau_r   [%.3f  %.3f]\n', ...
        bounds_min(3), bounds_max(3), bounds_min(4), bounds_max(4));

    % --- gera grid 4D como lista de pontos ---
    v = cell(1,4);
    for d = 1:4
        v{d} = linspace(bounds_min(d), bounds_max(d), n_grid);
    end

    % produto cartesiano via ndgrid
    [G1, G2, G3, G4] = ndgrid(v{1}, v{2}, v{3}, v{4});
    n_pts = numel(G1);

    pts = [G1(:), G2(:), G3(:), G4(:)];   % [n_pts x 4]

    ay_vec  = zeros(n_pts, 1);
    bal_vec = zeros(n_pts, 1);

    % --- avaliacao em paralelo ---
    for k = 1:n_pts
        [ay_vec(k), bal_vec(k)] = evaluate_ymd_setup(pts(k,:), ymd_args{:});
    
        if mod(k, 25) == 0 || k == n_pts
            fprintf('      ponto %d/%d\n', k, n_pts);
        end
    end

    x_history = [x_history; pts, ay_vec, bal_vec]; %#ok<AGROW>

    fprintf('    avaliados %d pontos | melhor ay=%.4fg  bal=%.6f\n', ...
        n_pts, max(ay_vec), bal_vec(ay_vec == max(ay_vec), 1));

    % --- scoring: prioridade ao balance, depois ao ay ---
    valid = bal_vec <= balance_limit;

    if any(valid)
        score = ay_vec;
        score(~valid) = -inf;
    else
        % nenhum valido: minimiza balance como proxy
        score = -bal_vec;
    end

    [sorted_score, sort_idx] = sort(score, 'descend');
    top_idx = sort_idx(1:min(n_keep, n_pts));

    % actualiza melhor global
    if isempty(best_x) || sorted_score(1) > best_score
        best_x     = pts(top_idx(1), :);
        best_ay    = ay_vec(top_idx(1));
        best_bal   = bal_vec(top_idx(1));
        best_score = sorted_score(1);
    end
    % --- nova janela = bounding box dos top-K + 1 passo de margem ---
    top_pts = pts(top_idx, :);
    margin  = (bounds_max - bounds_min) / (n_grid - 1);

    bounds_min = max(x_min(:)', min(top_pts) - margin);
    bounds_max = min(x_max(:)', max(top_pts) + margin);

    % evita janela degenerada em qualquer dimensao
    for d = 1:4
        if bounds_max(d) - bounds_min(d) < 1e-6
            bounds_min(d) = max(x_min(d), best_x(d) - margin(d));
            bounds_max(d) = min(x_max(d), best_x(d) + margin(d));
        end
    end

end

end
