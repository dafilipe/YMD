

clc;
clear;

root = fileparts(mfilename('fullpath'));

addpath(genpath(root));


fprintf("\n");
fprintf("╔════════════════════════════════════════════════════════════╗\n");
fprintf("║                                                            ║\n");
fprintf("║        NOVA FORMULA STUDENT - YAW MOMENT DIAGRAM           ║\n");
fprintf("║                                                            ║\n");
fprintf("╚════════════════════════════════════════════════════════════╝\n");
fprintf("\n");
fprintf("  Welcome to the Yaw Moment Diagram simulator.\n");
fprintf("  Please choose the tyre model you want to load.\n");
fprintf("\n");
fprintf("  ┌──────────────────────────────────────────────┐\n");
fprintf("  │             [1]  Hoosier 10 inch             │\n");
fprintf("  │             [2]  Hoosier 13 inch             │\n");
fprintf("  └──────────────────────────────────────────────┘\n");
fprintf("\n");

tyre_choice = input("  Option: ");

while tyre_choice ~= 1 && tyre_choice ~= 2
    fprintf("\n");
    fprintf("  Invalid option. Please choose 1 or 2.\n");
    fprintf("\n");
    tyre_choice = input("  Option: ");
end

fprintf("\n");

if tyre_choice == 1
    tiremodel = "tiremodels/Hoosier 43100 18.0x6.0-10 R20, 7 inch rim.tir";
    fprintf("  Selected model: Hoosier 10 inch\n");
elseif tyre_choice == 2
    tiremodel = "tiremodels/Hoosier 43164 20.5x7.0-13 R20, 7 inch rim.tir";
    fprintf("  Selected model: Hoosier 13 inch\n");
end

ymdV3(tiremodel)