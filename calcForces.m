function [fy, mz] = calcForces(model, alpha, FZ, gamma)

    n = max([numel(alpha), numel(FZ), numel(gamma)]);

    if isscalar(alpha)
        alpha = alpha * ones(n, 1);
    else
        alpha = alpha(:);
    end

    if isscalar(FZ)
        FZ = FZ * ones(n, 1);
    else
        FZ = FZ(:);
    end

    if isscalar(gamma)
        gamma = gamma * ones(n, 1);
    else
        gamma = gamma(:);
    end

    inputs = [FZ, ...
              zeros(n, 1), ...
              alpha, ...
              gamma, ...
              zeros(n, 1), ...
              model.LONGVL * ones(n, 1)];

    res = mfeval(model, inputs, 221);

    fy = res(:, 2);
    mz = res(:, 6);

end