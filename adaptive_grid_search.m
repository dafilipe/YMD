function [best_x, best_ay, best_bal, x_history] = adaptive_grid_search( ...
    x_min, x_max, ...
    n_grid, n_rounds, n_keep, ...
    fixed_vals, fixed_idx, ...
    ymd_args, balance_limit)
% ADAPTIVE_GRID_SEARCH  busca logaritmica por refinamento iterativo
%
%   x_min, x_max   : vetores [1x2] com limites das 2 variaveis a otimizar
%   n_grid         : pontos por dimensao em cada ronda (ex: 7)
%   n_rounds       : numero de rondas (ex: 3)
%   n_keep         : top-K pontos para refinar (ex: 3)
%   fixed_vals     : valores fixos das outras 2 variaveis [1x2]
%   fixed_idx      : indices das variaveis fixas no vetor x [1x2], ex: [3 4]
%   ymd_args       : cell array de argumentos para evaluate_ymd_setup
%   balance_limit  : limite de balance

% indices das variaveis a otimizar
search_idx = setdiff([1 2 3 4], fixed_idx);

bounds_min = x_min;
bounds_max = x_max;

best_x   = [];
best_ay  = -inf;
best_bal = inf;

x_history = [];   % para debug / visualizacao

for round = 1:n_rounds

    fprintf('  round %d/%d | range: [%.3f %.3f] x [%.3f %.3f]\n', ...
        round, n_rounds, bounds_min(1), bounds_max(1), bounds_min(2), bounds_max(2));

    v1 = linspace(bounds_min(1), bounds_max(1), n_grid);
    v2 = linspace(bounds_min(2), bounds_max(2), n_grid);

    n_pts = n_grid * n_grid;
    ay_vec  = zeros(n_pts, 1);
    bal_vec = zeros(n_pts, 1);
    pts     = zeros(n_pts, 2);

    % monta lista de pontos para parfor
    k = 0;
    for i = 1:n_grid
        for j = 1:n_grid
            k = k + 1;
            pts(k,:) = [v1(i), v2(j)];
        end
    end

    % avalia em paralelo
    parfor k = 1:n_pts
        x = zeros(1,4);
        x(fixed_idx)  = fixed_vals;
        x(search_idx) = pts(k,:);
        [ay_vec(k), bal_vec(k)] = evaluate_ymd_setup(x, ymd_args{:});
    end

    x_history = [x_history; pts, ay_vec, bal_vec]; %#ok<AGROW>

    % seleciona top-K com balance aceitavel
    valid = bal_vec <= balance_limit;

    if any(valid)
        score = ay_vec;
        score(~valid) = -inf;
    else
        % nenhum valido: usa balance como criterio inverso
        score = -bal_vec;
    end

    [sorted_score, sort_idx] = sort(score, 'descend');
    top_idx = sort_idx(1:min(n_keep, n_pts));

    % melhor ponto global
    if sorted_score(1) > best_ay || isempty(best_x)
        best_x   = pts(top_idx(1), :);
        best_ay  = ay_vec(top_idx(1));
        best_bal = bal_vec(top_idx(1));
    end

    % nova janela = bounding box dos top-K + margem
    top_pts  = pts(top_idx, :);
    margin   = (bounds_max - bounds_min) / (n_grid - 1);  % 1 passo da grid atual

    bounds_min = max(x_min, min(top_pts) - margin);
    bounds_max = min(x_max, max(top_pts) + margin);

    % evita janela degenerada
    for d = 1:2
        if bounds_max(d) - bounds_min(d) < 1e-6
            bounds_min(d) = max(x_min(d), best_x(d) - margin(d));
            bounds_max(d) = min(x_max(d), best_x(d) + margin(d));
        end
    end

end

end