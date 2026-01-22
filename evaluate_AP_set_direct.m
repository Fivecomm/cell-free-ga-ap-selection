function [coverage, avg_rsrp] = evaluate_AP_set_direct( ...
    ap_indices, RSRP_AP_dBm, threshold)
%==========================================================================
% FUNCTION:    evaluate_AP_set_direct
% DESCRIPTION: Evaluates spatial coverage and average RSRP for a given
%              subset of active Access Points (APs) by aggregating their
%              per-AP RSRP contributions in linear scale.
%
% INPUTS:
%   ap_indices     - Vector with indices of the selected active APs
%   RSRP_AP_dBm    - [L x K] matrix of per-AP RSRP values in dBm,
%                    where rows correspond to APs and columns to UE 
%                    locations
%   threshold      - RSRP threshold in dBm for coverage evaluation
%
% OUTPUTS:
%   coverage       - Fraction of UE locations with aggregated RSRP
%                    above the threshold (0–1)
%   avg_rsrp       - Average aggregated RSRP across all UE locations (dBm)
%
% NOTES:
%   - RSRP values are aggregated in linear scale (mW) and converted
%     back to dBm.
%   - This function is used by greedy and local search baselines, where
%     AP subsets are constructed incrementally.
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
%              publications, please cite the above reference.
%==========================================================================

%% -------------------- Aggregate RSRP ------------------------------------

% Convert per-AP RSRP from dBm to linear scale and aggregate
power_lin = sum(10.^(double(RSRP_AP_dBm(ap_indices, :)) / 10), 1);

% Convert aggregated power back to dBm
rsrp_agg = 10 * log10(power_lin);

%% -------------------- Metrics -------------------------------------------

coverage = mean(rsrp_agg >= threshold);
avg_rsrp = mean(rsrp_agg);

end
