%==========================================================================
% FILE:        calculateRSRP_AP.m
% DESCRIPTION: Computes per-Access Point (AP) Reference Signal Received
%              Power (RSRP) values for all UE locations. The resulting
%              per-AP RSRP matrix is used by deterministic baseline
%              algorithms (greedy and local search) that rely on direct
%              aggregation of individual AP contributions.
%
% REFERENCE:   Guillermo García-Barrios, Martina Barbi and Manuel Fuentes,
%              "Access Point Activation for Static Area-Wide Coverage in 
%              Cell-Free Massive MIMO Networks," 2026 Joint European 
%              Conference on Networks and Communications & 6G Summit 
%              (EuCNC/6G Summit), Málaga, Spain, 2026. [Submitted]
%
% VERSION:     1.0 (Last edited: 2026-01-22)
% AUTHOR:      Guillermo García-Barrios, Fivecomm
% LICENSE:     GPLv2 – If you use this code for research that results in
%              publications, please cite our monograph as described above.
%==========================================================================

clc; close all; clear;

%% ---------------------- Parameters --------------------------------------

% Total downlink transmit power per AP [mW]
rho_tot = 200;

% Bandwidth [MHz]
B = 20;

% RSRP-related parameters (consistent with Unity-based simulator)
ant_eff      = 0.8;     % Antenna efficiency (0–1)
subC         = 12;      % Subcarriers per PRB
CSpacing     = 15;      % Subcarrier spacing [kHz]
f            = 2.3;     % Carrier frequency [GHz]
connLoss_dB  = 1.0;     % Connector loss [dB]
cableLoss_dB = 1.0;     % Cable loss [dB]

%% ---------------------- Load Pathloss Data ------------------------------

load('results/pathloss.mat', 'pathlossdB');
[L_MAX, nPosUEs] = size(pathlossdB);

%% ---------------------- PRB Calculation ---------------------------------

[N_PRB, ~, ~, ~, ~] = getThParameters(B, CSpacing, f);

%% ---------------------- Compute Per-AP RSRP -----------------------------

RSRP_AP_dBm = zeros(L_MAX, nPosUEs, 'int16');

for l = 1:L_MAX
    disp(['Processing AP ', num2str(l), '/', num2str(L_MAX)])
    
    % Compute RSRP contribution of AP l to all UE locations
    rsrp_val = computeAggregateRSRP( ...
        rho_tot, ant_eff, N_PRB, subC, ...
        pathlossdB, connLoss_dB, cableLoss_dB, l);
    
    % Store as integer dBm ×10 to reduce memory footprint
    RSRP_AP_dBm(l, :) = int16(round(rsrp_val * 10));
end

%% ---------------------- Save Results ------------------------------------

save('results/RSRP_per_AP.mat', 'RSRP_AP_dBm', '-v7.3');
disp('✅ Saved per-AP RSRP matrix');
