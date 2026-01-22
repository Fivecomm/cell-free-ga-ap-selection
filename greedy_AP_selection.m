function result = greedy_AP_selection(RSRP_AP_dBm, L, M, threshold)
%==========================================================================
% FUNCTION:    greedy_AP_selection
% DESCRIPTION: Deterministic greedy baseline for Access Point (AP)
%              selection in a cell-free massive MIMO system. APs are
%              incrementally selected to maximize spatial coverage at
%              each step, based on aggregated RSRP.
%
% INPUTS:
%   RSRP_AP_dBm    - [L x K] matrix of per-AP RSRP values (dBm × 10)
%   L              - Total number of APs
%   M              - Number of APs to select
%   threshold      - RSRP threshold in dBm
%
% OUTPUT:
%   result = struct with fields:
%       .best_APs     - Indices of selected APs
%       .coverage     - Achieved coverage ratio
%       .avg_rsrp     - Average aggregated RSRP (dBm)
%       .evaluations  - Total number of fitness evaluations
%
% NOTES:
%   - No early stopping is applied: exactly M APs are always selected.
%   - This method serves as a fast deterministic baseline and does not
%     guarantee feasibility under strict coverage constraints.
%
% REFERENCE:   Guillermo García-Barrios, Martina Barbi and Manuel Fuentes,
%              "Access Point Activation for Static Area-Wide Coverage in 
%              Cell-Free Massive MIMO Networks," 2026 Joint European 
%              Conference on Networks and Communications & 6G Summit 
%              (EuCNC/6G Summit), Málaga, Spain, 2026. [Submitted]
%
% VERSION:     1.0 (Last edited: 2026-01-22)
% AUTHOR:      Guillermo García-Barrios, Fivecomm
% LICENSE:     GPLv2
%==========================================================================

selected_APs = [];
remaining_APs = 1:L;

total_evaluations = 0;
best_coverage = 0;
best_avg_rsrp = -Inf;

%% -------------------- Greedy construction ------------------------------
for k = 1:M

    best_candidate = -1;
    best_cov = -Inf;
    best_avg = -Inf;

    for ap = remaining_APs
        candidate_APs = [selected_APs ap];

        [cov, avg] = evaluate_AP_set_direct( ...
            candidate_APs, RSRP_AP_dBm, threshold);

        total_evaluations = total_evaluations + 1;

        if cov > best_cov || (cov == best_cov && avg > best_avg)
            best_candidate = ap;
            best_cov = cov;
            best_avg = avg;
        end
    end

    selected_APs = [selected_APs best_candidate];
    remaining_APs = setdiff(remaining_APs, best_candidate);

    best_coverage = best_cov;
    best_avg_rsrp = best_avg;
end

%% -------------------- Output --------------------------------------------
result.best_APs    = sort(selected_APs);
result.coverage    = best_coverage;
result.avg_rsrp    = best_avg_rsrp;
result.evaluations = total_evaluations;

end
