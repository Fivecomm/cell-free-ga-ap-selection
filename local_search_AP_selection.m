function result = local_search_AP_selection(RSRP_AP_dBm, L, M, ...
    threshold, required_coverage_percent)
%==========================================================================
% FUNCTION:    local_search_AP_selection
% DESCRIPTION: Local search (1-swap hill climbing) baseline for AP 
%              selection, initialized from the greedy solution. Iteratively
%              replaces one active AP with one inactive AP if coverage
%              improves.
%
% INPUTS:
%   RSRP_AP_dBm              - [L x K] per-AP RSRP matrix (dBm × 10)
%   L                        - Total number of APs
%   M                        - Number of APs to select
%   threshold                - RSRP coverage threshold (dBm × 10)
%   required_coverage_percent- Target coverage ratio (0–1)
%
% OUTPUT:
%   result = struct with fields:
%       .coverage        - Achieved coverage ratio
%       .avg_rsrp        - Average aggregated RSRP
%       .evaluations     - Number of evaluated AP subsets
%       .meets_coverage  - Boolean indicating constraint satisfaction
%       .best_APs        - Selected AP indices
%
% NOTES:
%   - Deterministic baseline initialized from greedy selection.
%   - Performs 1-swap neighborhood exploration until convergence.
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

%% --- Initialization from Greedy ---
greedy_res = greedy_AP_selection( ...
    RSRP_AP_dBm, L, M, threshold, required_coverage_percent);

current_APs = greedy_res.best_APs;
[current_cov, current_avg] = evaluate_AP_set_direct( ...
    current_APs, RSRP_AP_dBm, threshold);

total_evaluations = greedy_res.evaluations;
improved = true;

%% --- Local Search Loop ---
while improved
    improved = false;

    active_APs = current_APs;
    inactive_APs = setdiff(1:L, active_APs);

    best_cov = current_cov;
    best_avg = current_avg;
    best_candidate = current_APs;

    for i = 1:length(active_APs)
        for j = 1:length(inactive_APs)

            candidate_APs = active_APs;
            candidate_APs(i) = inactive_APs(j);
            candidate_APs = sort(candidate_APs);

            [cov, avg] = evaluate_AP_set_direct( ...
                candidate_APs, RSRP_AP_dBm, threshold);

            total_evaluations = total_evaluations + 1;

            if cov > best_cov || (cov == best_cov && avg > best_avg)
                best_cov = cov;
                best_avg = avg;
                best_candidate = candidate_APs;
                improved = true;
            end
        end
    end

    if improved
        current_APs = best_candidate;
        current_cov = best_cov;
        current_avg = best_avg;
    end
end

%% --- Output ---
result.coverage       = current_cov;
result.avg_rsrp       = current_avg;
result.evaluations    = total_evaluations;
result.meets_coverage = current_cov >= required_coverage_percent;
result.best_APs       = current_APs;

end
