function FY = calc_FY(P, FZ0, alpha, FZ, gamma)
    PCY1 = P(1);
    PDY1 = P(2);
    PDY2 = P(3);
    PDY3 = P(4);
    PEY1 = P(5);
    PEY2 = P(6);
    PEY3 = P(7);
    PEY4 = P(8);
    PKY1 = P(9);
    PKY2 = P(10);
    PKY3 = P(11);
    PHY1 = P(12);
    PHY2 = P(13);
    PHY3 = P(14);
    PVY1 = P(15);
    PVY2 = P(16);
    PVY3 = P(17);
    PVY4 = P(18);

    eps = 0.0001;
    dfz = (FZ - FZ0) ./ FZ0;

    mu_y = (PDY1 + PDY2 .* dfz) .* (1 - PDY3 .* gamma.^2);
    
    Dy = mu_y .* FZ;
    Cy = PCY1;

    Ky = PKY1 .* FZ0 .* sin(2 .* atan(FZ ./ ((PKY2 .* FZ0) + eps))) .* (1 - PKY3 .* abs(gamma));
    By = Ky ./ (Cy .* Dy + eps);

    Shy = (PHY1 + PHY2 .* dfz) + PHY3 .* gamma;
    Svy = FZ .* ((PVY1 + PVY2 .* dfz) + (PVY3 + PVY4 .* dfz) .* gamma);

    alpha_y = alpha + Shy;

    Ey = (PEY1 + PEY2 .* dfz) .* (1 - (PEY3 + PEY4 .* gamma) .* sign(alpha_y));
    
    FY = Dy .* sin(Cy .* atan(By .* alpha_y - Ey .* (By .* alpha_y - atan(By .* alpha_y)))) + Svy;
end