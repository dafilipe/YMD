function [a_lat_g, nz_norm, yawaccel] = run_ymd( ...
    si_vec, vs_vec, niter, alpha_lim, ...
    a, b, vx, m, g, ...
    t_f, t_r, wb, ...
    wsn, wufn, wurn, ...
    h2, kphi_f_p, kphi_r_p, den_roll, ...
    rc_f, rc_r, ...
    fz_f0, fz_r0, ...
    gamma_fl, gamma_fr, gamma_rl, gamma_rr, ...
    tau_fl, tau_fr, tau_rl, tau_rr, ...
    model, izz, w)

    nsi = numel(si_vec);
    nvs = numel(vs_vec);

    a_lat = zeros(nsi, nvs);
    nz = zeros(nsi, nvs);
    yawaccel = zeros(nsi, nvs);

    gamma_fl = deg2rad(gamma_fl);
    gamma_fr = deg2rad(gamma_fr);
    gamma_rl = deg2rad(gamma_rl);
    gamma_rr = deg2rad(gamma_rr);
    
    tau_fl = deg2rad(tau_fl);
    tau_fr = deg2rad(tau_fr);
    tau_rl = deg2rad(tau_rl);
    tau_rr = deg2rad(tau_rr);

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
                
                %toe(tau) input
                %si e vs em rad logo tau em rad
                
                alpha_fl = alpha_f + tau_fl;
                alpha_fr = alpha_f - tau_fr;
                alpha_rl = alpha_r + tau_rl;
                alpha_rr = alpha_r - tau_rr;

                if k == 1
                    alpha_vec = [alpha_fl; alpha_fr; alpha_rl; alpha_rr];
                    fz_vec    = [fz_f0;   fz_f0;   fz_r0;   fz_r0];
                    gamma_vec = [gamma_fl; gamma_fr; gamma_rl; gamma_rr];
                    
                    [fy_vec, ~] = calcForces(model, alpha_vec, fz_vec, gamma_vec);
                    
                    fyf = fy_vec(1) + fy_vec(2);
                    fyr = fy_vec(3) + fy_vec(4);
                
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

                alpha_vec = [alpha_fl; alpha_fr; alpha_rl; alpha_rr];
                fz_vec    = [fz_fl;    fz_fr;    fz_rl;    fz_rr];
                gamma_vec = [gamma_fl; gamma_fr; gamma_rl; gamma_rr];
                
                [fy_vec, mz_vec] = calcForces(model, alpha_vec, fz_vec, gamma_vec);
                
                fyf = fy_vec(1) + fy_vec(2);
                fyr = fy_vec(3) + fy_vec(4);
                
                a_lat(i, j) = (fyf + fyr) / m;
                
                mzf = mz_vec(1) + mz_vec(2);
                mzr = mz_vec(3) + mz_vec(4);

                nz(i, j) = fyf * a * cos(si) - fyr * b - mzf - mzr;

                yawaccel(i, j) = nz(i, j) / izz * 180 / pi;

                r = a_lat(i, j) / vx;
            end
        end
    end

    nz_norm = nz / (w * wb);
    a_lat_g = a_lat / g;

end