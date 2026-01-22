%=========================================================================%
% FILE:        calculateRSRP.m
% DESCRIPTION: This script calculates the Reference Signal Received Power
%              (RSRP) for UEs based on the pathloss computed in 
%              simulate_downlink.m. It considers different numbers of APs
%              and saves RSRP values for each combination.
%
% REFERENCE:   Guillermo García-Barrios, Martina Barbi and Manuel Fuentes,
%              "Access Point Activation for Static Area-Wide Coverage in 
%              Cell-Free Massive MIMO Networks," 2026 Joint European 
%              Conference on Networks and Communications & 6G Summit 
%              (EuCNC/6G Summit), Málaga, Spain, 2026. [Submitted]
%
% VERSION:     1.0 (Last edited: 2025-09-19)
% AUTHOR:      Guillermo García-Barrios, Fivecomm
% LICENSE:     GPLv2 – If you use this code for research that results in 
%              publications, please cite our monograph as described above.
%=========================================================================%

clc; close all; clear;

%% PARAMETERS

% Number of APs for each combination
L = [22, 20, 18, 16];

% Total downlink transmit power per AP [mW]
rho_tot = 200;  

% Bandwidth [MHz]
B = 20;

% RSRP parameters (from Unity)
ant_eff      = 0.8;     % Antenna efficiency (0–1)
subC         = 12;      % Subcarriers per PRB
CSpacing     = 15;      % Subcarrier spacing [kHz]
f            = 2.3;     % Carrier frequency [GHz]
connLoss_dB  = 1.0;     % Connector loss [dB]
cableLoss_dB = 1.0;     % Cable loss [dB]


%% LOAD PATHLOSS DATA

load('results\pathloss.mat', 'pathlossdB');
[L_MAX, nPosUEs] = size(pathlossdB);

%% MAIN LOOP OVER AP COMBINATIONS

for l = L
    % Generate all combinations of L APs
    combAll = nchoosek(1:L_MAX, l);
    nComb = length(combAll);
    
    % Estimate number of PRBs for given bandwidth
    [N_PRB, ~, ~, ~, ~] = getThParameters(B, CSpacing, f);
    
    % Initialize RSRP array
    RSRPdBm = zeros(nComb, nPosUEs, 'int16');
    
    %% CALCULATE RSRP

    for c = 1:nComb
        disp(['Processing combination ', num2str(c), '/', num2str(nComb)])
        
        % Compute aggregate RSRP for this combination of APs
        RSRPdBm_val = computeAggregateRSRP(rho_tot, ant_eff, N_PRB, ...
            subC, pathlossdB, connLoss_dB, cableLoss_dB, combAll(c,:));

        % Store as integer dBm ×10 (to save memory)
        RSRPdBm(c,:) = int16(round(RSRPdBm_val * 10));
    end
    
    %% SAVE RESULTS
    
    folderName = 'results/';
    if ~exist(folderName, 'dir')
        mkdir(folderName);
    end
    
    fileName = ['RSRP_', num2str(l), '_APs.mat'];
    save(fullfile(folderName, fileName), 'RSRPdBm', '-v7.3');

end



