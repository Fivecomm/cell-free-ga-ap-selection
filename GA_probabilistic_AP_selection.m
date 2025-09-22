function result = GA_probabilistic_AP_selection(RSRP, L, M, ...
    numGenerations, threshold, required_coverage_percent, popSize, ...
    alpha, patience)
%=========================================================================%
% FUNCTION:    GA_probabilistic_AP_selection
% DESCRIPTION: Estimation-of-Distribution-like Genetic Algorithm (EDA/GA) 
%              for selecting a subset of Access Points (APs) that maximizes 
%              UE coverage in a cell-free massive MIMO network.
%
% INPUTS:
%   RSRP_matrix               - [N_comb x N_UE] precomputed RSRP values 
%                               (dBm), where rows correspond to AP 
%                               combinations and columns to UEs
%   L                         - Total number of APs
%   M                         - Number of APs to select in each solution
%   numGenerations            - Maximum number of generations
%   threshold                 - RSRP threshold (dBm), e.g., -90
%   required_coverage_percent - Minimum coverage to consider solution 
%                               valid (0–1)
%   popSize                   - Population size per generation
%   alpha                     - Learning rate for probability update (0–1, 
%                               e.g., 0.2)
%   patience                  - Early stopping patience (# generations 
%                               without improvement)
%
% OUTPUT:
%   result = struct with fields:
%       .best_combination   - Best set of AP indices found
%       .best_coverage      - Best coverage ratio achieved
%       .coverage_percent   - Same as best_coverage (alias)
%       .generations_run    - Number of generations executed
%       .generation_found   - First generation when valid solution is found
%       .fitness_history    - Max fitness per generation
%       .avg_rsrp_history   - Avg RSRP across population per generation
%       .coverage_history   - Avg coverage across population per generation
%       .total_evaluations  - Total number of evaluated individuals
%       .p                  - Final learned AP selection probability vector
%
% NOTES:
%   - Starts with uniform AP selection probability (M/L).
%   - Updates probabilities based on elite (top 20%) solutions.
%   - Maintains exactly M selected APs per individual.
%   - Uses patience-based early stopping.
%
% REFERENCE:   Guillermo García-Barrios, Martina Barbi and Manuel Fuentes
%              "Genetic Algorithm-Based Optimization of AP Activation for 
%              Static Coverage in Cell-Free," IEEE Isnternational Conference
%              on Communications (ICC), Glasgow, Scotland, UK, 2025. 
%              [Submitted]
%
% VERSION:     1.0 (Last edited: 2025-09-19)
% AUTHOR:      Guillermo García-Barrios, Fivecomm
% LICENSE:     GPLv2 – If you use this code for research that results in 
%              publications, please cite our monograph as described above.
%=========================================================================%

%% -------------------- Initialization ----------------------------------
K = size(RSRP, 2); % Number of UEs

% Initial AP selection probabilities (uniform)
p = ones(L, 1) * M / L;

% Precompute all possible AP combinations for indexing into RSRP
all_combinations = nchoosek(1:L, M);

best_fitness = 0;
no_improvement = 0;
generation_found = [];
total_evaluations = 0;

fitness_history = zeros(numGenerations, 1);
avg_rsrp_history = zeros(numGenerations, 1);
coverage_history = zeros(numGenerations, 1);

%% -------------------- GA Loop -----------------------------------------
for gen = 1:numGenerations
    tic;
    population = zeros(popSize, M);
    fitness = zeros(popSize, 1);
    avgRSRP = zeros(popSize, 1);
    coverage = zeros(popSize, 1);

    % --- Generate individuals ---
    for i = 1:popSize
        valid = false;
        while ~valid
            % Randomly include APs with probability p(i)
            candidate = rand(L,1) < p;
            % Accept only if exactly M APs are selected
            if sum(candidate) == M
                % Store the selected AP indices
                ap_indices = find(candidate);
                valid = true;
            end
        end
        population(i, :) = ap_indices;

        % Convert to index in RSRP matrix
        sorted_ap = sort(ap_indices); % Ensure it's sorted for comparison
        [~, idx] = ismember(sorted_ap', all_combinations, 'rows');

        row = RSRP(idx, :);
        coverage_ratio = sum(row >= threshold) / K;
        fitness(i) = coverage_ratio;
        avgRSRP(i) = mean(row);
        coverage(i) = coverage_ratio;
    end

    total_evaluations = total_evaluations + popSize;

    % Record statistics
    fitness_history(gen) = max(fitness);
    avg_rsrp_history(gen) = mean(avgRSRP);
    coverage_history(gen) = mean(coverage);

    % --- Track best solution ---
    [max_fit, idx_best] = max(fitness);
    if max_fit > best_fitness
        best_fitness = max_fit;
        best_solution = population(idx_best, :);
        no_improvement = 0;

        if isempty(generation_found) && ...
                max_fit >= required_coverage_percent
            generation_found = gen;
            fprintf(["\n✅ Valid solution found at generation %d " ...
                "with coverage %.2f%%\n"], gen, 100 * max_fit);
        end
    else
        no_improvement = no_improvement + 1;
    end
    
    % --- Early stopping ---
    if no_improvement >= patience
        fprintf("\n🛑 Early stopping at generation %d due to no improvement.\n", gen);
        break;
    end

    % --- Probability update (EDA-style) ---
    num_elites = ceil(0.2 * popSize);
    [~, idx_sorted] = sort(fitness, 'descend');
    elites = population(idx_sorted(1:num_elites), :);

    elite_counts = zeros(L,1);
    for i = 1:num_elites
        elite_counts(elites(i, :)) = elite_counts(elites(i, :)) + 1;
    end
    elite_freq = elite_counts / num_elites;

    % Smooth probability update with learning rate
    p = (1 - alpha) * p + alpha * elite_freq;

    % Optional: Normalize to maintain M APs per individual
    p = p * (M / sum(p));
    p = min(p, 1); % Ensure prob <= 1

end

%% -------------------- Return Results ----------------------------------
result.best_combination  = best_solution;
result.best_coverage     = best_fitness;
result.coverage_percent  = best_fitness;
result.generations_run   = gen;
result.generation_found  = generation_found;
result.fitness_history   = fitness_history(1:gen);
result.avg_rsrp_history  = avg_rsrp_history(1:gen);
result.coverage_history  = coverage_history(1:gen);
result.total_evaluations = total_evaluations;
result.p                 = p;

end
