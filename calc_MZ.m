function MZ = calc_MZ(P_mz, P_fy, FZ0, alpha, FZ, gamma, R0)
    FY = calc_FY(P_fy, FZ0, alpha, FZ, gamma);
    
    QBZ1 = P_mz(1);
    QBZ2 = P_mz(2);
    QBZ3 = P_mz(3);
    QBZ4 = P_mz(4);
    QBZ5 = P_mz(5);
    QBZ9 = P_mz(6);
    QBZ10 = P_mz(7);
    QCZ1 = P_mz(8);
    QDZ1 = P_mz(9);
    QDZ2 = P_mz(10);
    QDZ3 = P_mz(11);
    QDZ4 = P_mz(12);
    QDZ6 = P_mz(13);
    QDZ7 = P_mz(14);
    QDZ8 = P_mz(15);
    QDZ9 = P_mz(16);
    QEZ1 = P_mz(17);
    QEZ2 = P_mz(18);
    QEZ3 = P_mz(19);
    QEZ4 = P_mz(20);
    QEZ5 = P_mz(21);
    QHZ1 = P_mz(22);
    QHZ2 = P_mz(23);
    QHZ3 = P_mz(24);
    QHZ4 = P_mz(25);
    
    PCY1 = P_fy(1);
    PDY1 = P_fy(2);
    PDY2 = P_fy(3);
    PDY3 = P_fy(4);
    PKY1 = P_fy(9);
    PKY2 = P_fy(10);
    PKY3 = P_fy(11);
    PHY1 = P_fy(12);
    PHY2 = P_fy(13);
    PHY3 = P_fy(14);
    PVY1 = P_fy(15);
    PVY2 = P_fy(16);
    PVY3 = P_fy(17);
    PVY4 = P_fy(18);
    
    eps = 0.0001;
    dfz = (FZ - FZ0) ./ FZ0;
    
    Sht = QHZ1 + QHZ2 .* dfz + (QHZ3 + QHZ4 .* dfz) .* gamma;
    alpha_t = alpha + Sht;
    
    Bt = (QBZ1 + QBZ2 .* dfz + QBZ3 .* dfz.^2) .* (1 + QBZ4 .* gamma + QBZ5 .* abs(gamma));
    Ct = QCZ1;
    Dt = FZ .* (QDZ1 + QDZ2 .* dfz) .* (1 + QDZ3 .* gamma + QDZ4 .* gamma.^2) .* (R0 ./ FZ0);
    Et = (QEZ1 + QEZ2 .* dfz + QEZ3 .* dfz.^2) .* (1 + (QEZ4 + QEZ5 .* gamma) .* (2 ./ pi) .* atan(Bt .* Ct .* alpha_t));
    
    t = Dt .* cos(Ct .* atan(Bt .* alpha_t - Et .* (Bt .* alpha_t - atan(Bt .* alpha_t)))) .* cos(alpha);
    
    mu_y = (PDY1 + PDY2 .* dfz) .* (1 - PDY3 .* gamma.^2);

    Dy = mu_y .* FZ;
    Cy = PCY1;
    Ky = PKY1 .* FZ0 .* sin(2 .* atan(FZ ./ ((PKY2 .* FZ0) + eps))) .* (1 - PKY3 .* abs(gamma));
    By = Ky ./ (Cy .* Dy + eps);
    Shy = (PHY1 + PHY2 .* dfz) + PHY3 .* gamma;
    Svy = FZ .* ((PVY1 + PVY2 .* dfz) + (PVY3 + PVY4 .* dfz) .* gamma);
    
    Shf = Shy + Svy ./ (Ky + eps);
    alpha_r = alpha + Shf;
    
    Br = QBZ9 + QBZ10 .* By .* Cy;
    Dr = FZ .* ((QDZ6 + QDZ7 .* dfz) + (QDZ8 + QDZ9 .* dfz) .* gamma) .* R0;
    
    Mzr = Dr .* cos(atan(Br .* alpha_r)) .* cos(alpha);
    
    MZ = -t .* FY + Mzr;
end