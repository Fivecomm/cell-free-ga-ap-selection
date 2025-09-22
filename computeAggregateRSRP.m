function RSRP_dBm = computeAggregateRSRP(Pt_mW, ant_eff, N_PRB, subC, ...
    pathloss_dB, connLoss_dB, cableLoss_dB, activeAPs)
%=========================================================================%
% FUNCTION:    computeAggregateRSRP
% DESCRIPTION: Computes the aggregate Reference Signal Received Power 
%              (RSRP) at each UE from a set of active Access Points (APs) 
%              in a cell-free massive MIMO setup.
%
% INPUTS:
%   Pt_mW        - Transmit power per AP in milliwatts (scalar)
%   ant_eff      - Antenna efficiency (scalar, 0–1)
%   N_PRB        - Number of Physical Resource Blocks (scalar)
%   subC         - Number of subcarriers per PRB (typically 12)
%   pathloss_dB  - L x K matrix of pathloss values in dB
%                  (L = total APs, K = total UEs)
%   connLoss_dB  - Connector loss per AP in dB (scalar)
%   cableLoss_dB - Cable loss per AP in dB (scalar)
%   activeAPs    - Vector of indices of active APs (e.g., [1 4 7 10])
%
% OUTPUT:
%   RSRP_dBm     - 1 x K vector containing the aggregate RSRP (in dBm) 
%                  at each UE
%
% DESCRIPTION:
%   Computes the RSRP by summing the received powers from active APs. 
%   Each AP's received power accounts for transmit power, antenna 
%   efficiency, number of resource elements, pathloss, connector and cable 
%   losses. RSRP for each link is calculated as:
%       RSRP = 10*log10(Pt * ant_eff / (N_PRB * subC)) - pathloss_dB 
%              - connLoss_dB - cableLoss_dB
%
%   Then, linear powers (mW) from all active APs are summed and converted 
%   back to dBm to give the total RSRP per UE.
%
% REFERENCE:   Guillermo García-Barrios, Martina Barbi and Manuel Fuentes
%              "Genetic Algorithm-Based Optimization of AP Activation for 
%              Static Coverage in Cell-Free," IEEE International Conference
%              on Communications (ICC), Glasgow, Scotland, UK, 2025. 
%              [Submitted]
%
% VERSION:     1.0 (Last edited: 2025-09-19)
% AUTHOR:      Guillermo García-Barrios, Fivecomm
% LICENSE:     GPLv2 – If you use this code for research that results in 
%              publications, please cite our monograph as described above.
%=========================================================================%

% Total number of APs and UEs
L = size(pathloss_dB,1);  
K = size(pathloss_dB,2);  

% Convert transmit power to linear scale per subcarrier
powerPerSubcarrier_mW = (Pt_mW * ant_eff) / (N_PRB * subC);

% Preallocate total RSRP in mW
RSRP_mW_total = zeros(1, K);

% Loop over active APs to compute received power per UE
for m = activeAPs
    % Total loss in dB for this AP
    loss_dB = pathloss_dB(m,:) + connLoss_dB + cableLoss_dB;

    % Received power per UE in dBm
    rxPower_dBm = 10 * log10(powerPerSubcarrier_mW) - loss_dB;

    % Convert to linear scale (mW) for aggregation
    rxPower_mW = 10.^(rxPower_dBm / 10);

    % Accumulate received powers
    RSRP_mW_total = RSRP_mW_total + rxPower_mW;
end

% Convert aggregate RSRP back to dBm
RSRP_dBm = 10 * log10(RSRP_mW_total + eps);  % eps avoids log(0)

end


