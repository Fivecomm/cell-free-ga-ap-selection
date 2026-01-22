function result = GA_bitstring_AP_selection(RSRP, AP_indices, M, L, ...
    threshold, required_coverage_percent, popSize, numGenerations, ...
    mutationRate, patience, tournamentSize)
%=========================================================================%
% FUNCTION:    GA_bitstring_AP_selection
% DESCRIPTION: Genetic Algorithm (GA) with bitstring encoding to select
%              the best subset of Access Points (APs) in a cell-free
%              massive MIMO network for maximizing coverage.
%
% INPUTS:
%   RSRP_matrix     - [N_comb x N_UE] matrix of precomputed RSRP values 
%                     (dBm), where rows correspond to AP combinations and 
%                     columns to UEs
%   AP_combinations - [N_comb x M] matrix of AP indices (matching RSRP 
%                     rows)
%   M               - Number of APs to select
%   L               - Total number of APs in the system
%   threshold       - RSRP threshold in dBm
%   required_coverage_percent - Minimum acceptable UE coverage (0–1)
%   popSize         - Population size
%   numGenerations  - Maximum number of generations
%   mutationRate    - Probability of mutation (0–1)
%   patience        - Number of generations with no improvement before 
%                     early stop
%   tournamentSize  - Tournament size for parent selection
%
% OUTPUT:
%   result = struct with fields:
%       .best_AP_selection - Indices of selected APs
%       .best_fitness      - Best fitness (coverage ratio)
%       .coverage          - Best coverage ratio
%       .avg_rsrp          - Average RSRP of best solution
%       .evaluations       - Total number of evaluations performed
%
% NOTES:
%   - Fitness function is currently the coverage ratio (UEs above 
%     threshold).
%   - GA uses elitism (keeps best solution each generation).
%   - Crossover and mutation operators enforce exactly M active APs.
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

%% -------------------- Initialization ----------------------------------
population = generate_initial_population(popSize, L, M);  % [popSize x L]

% Precompute all possible AP combinations for indexing into RSRP
all_combinations = nchoosek(1:L, M);

best_fitness = 0;
no_improvement = 0;
total_evaluations = 0;

%% -------------------- GA Loop -----------------------------------------
for gen = 1:numGenerations

    fitness = zeros(popSize, 1);
    coverage = zeros(popSize, 1);
    avg_rsrp = zeros(popSize, 1);

    % --- Evaluate population ---
    for i = 1:popSize
        ap_idx = find(population(i, :) == 1);  % Selected APs
        [fit, cov, avg] = evaluate_AP_set(ap_idx, RSRP, AP_indices, threshold);
        fitness(i) = fit;
        coverage(i) = cov;
        avg_rsrp(i) = avg;
    end

    total_evaluations = total_evaluations + popSize;

    % --- Track best ---
    [current_best, best_idx] = max(fitness);
    if current_best > best_fitness
        best_fitness = current_best;
        best_solution = population(best_idx, :);
        best_coverage = coverage(best_idx);
        best_avg_rsrp = avg_rsrp(best_idx);
        no_improvement = 0;

        if best_coverage >= required_coverage_percent
            fprintf("✅ Found valid solution with %.2f%% coverage at gen %d.\n", ...
                100 * best_coverage, gen);
            break;
        end
    else
        no_improvement = no_improvement + 1;
    end
    
    % --- Early stopping ---
    if no_improvement >= patience
        fprintf("🛑 Early stopping at generation %d.\n", gen);
        break;
    end

    % --- Generate new population ---
    new_population = zeros(size(population));
    new_population(1, :) = best_solution;  % Elitism

    for i = 2:popSize
        % Tournament
        parent1 = tournament_selection(population, fitness, tournamentSize);
        parent2 = tournament_selection(population, fitness, tournamentSize);

        % Crossover (fixed cardinality)
        child = crossover_fixed_cardinality(parent1, parent2, M);

        % Mutation (fixed cardinality)
        if rand < mutationRate
            child = mutate_fixed_cardinality(child);
        end
        new_population(i, :) = child;
    end

    population = new_population;

end

% Get best combination APs idx
sorted_ap = sort(find(best_solution)); % Ensure it's sorted for comparison
[~, best_index] = ismember(sorted_ap, all_combinations, 'rows');

% --- Return result ---
result.best_index   = best_index;
result.best_fitness = best_fitness;
result.coverage     = best_coverage;
result.avg_rsrp     = best_avg_rsrp;
result.evaluations  = total_evaluations;

end

%=========================================================================%
% Helper Functions
%=========================================================================%

function population = generate_initial_population(N, L, M)
    % Generate initial population with exactly M active APs per individual
    population = zeros(N, L);
    for i = 1:N
        idx = randperm(L, M);
        population(i, idx) = 1;
    end
end

function [fitness, coverage_ratio, avg_rsrp] = evaluate_AP_set(...
    ap_indices, RSRP_matrix, AP_combinations, threshold)
    % Evaluate a given AP set against precomputed RSRP combinations
    sorted = sort(ap_indices);
    match = ismember(AP_combinations, sorted, 'rows');
    idx = find(match, 1);
    if isempty(idx)
        fitness = 0; coverage_ratio = 0; avg_rsrp = -Inf;
        return;
    end
    rsrp = RSRP_matrix(idx, :);
    coverage_ratio = mean(rsrp >= threshold);
    avg_rsrp = mean(rsrp);
    fitness = coverage_ratio;  % optionally add RSRP weighting
end

function selected = tournament_selection(pop, fitness, k)
    % Tournament selection of parents
    idx = randperm(size(pop, 1), k);
    [~, best_idx] = max(fitness(idx));
    selected = pop(idx(best_idx), :);
end

function child = crossover_fixed_cardinality(p1, p2, M)
    % One-point crossover maintaining exactly M active APs
    union_set = (p1 | p2);
    active_indices = find(union_set);
    if length(active_indices) < M
        child = p1;  % fallback if not enough unique APs
        return;
    end
    selected = active_indices(randperm(length(active_indices), M));
    child = zeros(1, length(p1));
    child(selected) = 1;
end

function mutated = mutate_fixed_cardinality(ind)
    % Mutate by swapping one active AP with one inactive AP
    idx = find(ind);
    out_idx = find(~ind);
    % Swap one in and one out
    if isempty(idx) || isempty(out_idx)
        mutated = ind;
        return;
    end
    ind(idx(randi(length(idx)))) = 0;
    ind(out_idx(randi(length(out_idx)))) = 1;
    mutated = ind;
end
