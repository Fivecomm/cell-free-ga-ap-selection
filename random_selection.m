function result = random_selection(RSRP, threshold, ...
    required_coverage_percent, max_evals)
%=========================================================================%
% FUNCTION:    random_selection
% DESCRIPTION: Pure random baseline for Access Point (AP) subset selection.
%              Randomly samples AP combinations (from precomputed RSRP 
%              values) and evaluates their UE coverage performance against 
%              a given RSRP threshold. Serves as a benchmark for GA-based 
%              approaches.
%
% INPUTS:
%   RSRP_matrix - [N_comb x N_UE] precomputed RSRP values (dBm)
%                 • Rows = AP combinations
%                 • Columns = UEs
%   threshold   - RSRP threshold in dBm (e.g., -90)
%   required_coverage_percent - Target coverage ratio (0–1)
%   max_evals   - Maximum number of random evaluations (e.g., 1000)
%
% OUTPUT:
%   result = struct with fields:
%       .best_index       - Index of best AP combination in RSRP_matrix
%       .best_fitness     - Best coverage ratio achieved
%       .evaluations_used - Number of evaluations performed
%
% NOTES:
%   - Random selection is done *with replacement*.
%   - Early stops if a combination meets the required coverage.
%   - Coverage = fraction of UEs with RSRP ≥ threshold.
%
% REFERENCE:   Guillermo García-Barrios, Martina Barbi and Manuel Fuentes,
%              "Access Point Activation for Static Area-Wide Coverage in 
%              Cell-Free Massive MIMO Networks," 2026 Joint European 
%              Conference on Networks and Communications & 6G Summit 
%              (EuCNC/6G Summit), Málaga, Spain, 2026. [Submitted]
%
% VERSION:     1.0 (Last edited: 2025-11-10)
% AUTHOR:      Guillermo García-Barrios, Fivecomm
% LICENSE:     GPLv2 – If you use this code for research that results in 
%              publications, please cite our monograph as described above.
%=========================================================================%

%% -------------------- Initialization ----------------------------------
num_combinations = size(RSRP, 1);
num_UEs = size(RSRP, 2);
best_fitness = 0;
best_index = 0;
avg_rsrp = -Inf; % Initial placeholder

%% -------------------- Random Search Loop ------------------------------
for evals = 1:max_evals
    % Randomly select a combination index
    idx = randi(num_combinations);
    rsrp = RSRP(idx, :);

    % Compute coverage ratio
    coverage = sum(rsrp >= threshold) / num_UEs;

    % Update best solution if improved
    if coverage > best_fitness
        best_fitness = coverage;
        best_index = idx;
        avg_rsrp = mean(rsrp); % Calculate average RSRP for best combo
    end

    % Early stopping if requirement is satisfied
    if coverage >= required_coverage_percent
        break;
    end
end

%% -------------------- Return Results ----------------------------------
result.best_index       = best_index;
result.best_fitness     = best_fitness;
result.evaluations_used = evals;
result.avg_rsrp         = avg_rsrp;

end
