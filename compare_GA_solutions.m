%=========================================================================%
% FILE:        compare_GA_solutions.m
% DESCRIPTION: This script executes two GA-based AP selection algorithms 
%              (bitstring GA and probabilistic GA) and a random 
%              selection algorithm for multiple scenarios. Results for 
%              coverage, number of evaluations, and runtime selected APs, 
%              and resulting RSRP vectors are saved for later comparison.
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

clc; clear; close all;

%% --------------------- Define Scenarios -----------------------------
scenarios = [
    struct('M', 20, 'threshold', -960, 'required_coverage', 0.98);
    struct('M', 18, 'threshold', -900, 'required_coverage', 0.88);
    struct('M', 16, 'threshold', -980, 'required_coverage', 0.98);
    struct('M', 18, 'threshold', -880, 'required_coverage', 0.82);
    struct('M', 16, 'threshold', -900, 'required_coverage', 0.86);
    struct('M', 20, 'threshold', -880, 'required_coverage', 0.86);
    struct('M', 18, 'threshold', -900, 'required_coverage', 0.90);
    struct('M', 16, 'threshold', -880, 'required_coverage', 0.80);
    struct('M', 18, 'threshold', -880, 'required_coverage', 0.84);
    struct('M', 16, 'threshold', -960, 'required_coverage', 0.98)
];

%% --------------------- Algorithm Hyperparameters ---------------------

num_trials = 100;        % Number of trials per scenario
L = 24;                  % Total number of APs in the system

% Deterministic GA settings
popSize_GA      = 10;
numGenerations  = 50;
mutationRate    = 0.6;
tournamentSize  = 3;
patience_GA     = 10;

% Probabilistic GA settings
popSize_PROB    = 10;
alpha           = 0.1;
patience_PROB   = 15;

% Random selection settings
max_evals_random = 1000;

%% -------------------- Loop Through All Scenarios ---------------------

% Initialize result arrays
results_bit(num_trials) =   struct('coverage', [], ...
                                   'avg_rsrp', [], ...
                                   'evaluations', [], ...
                                   'meets_coverage', [], ...
                                   'best_idx', []);
results_prob =  results_bit;
results_rand =  results_bit;

for s = 1:length(scenarios)

    M = scenarios(s).M;
    threshold = scenarios(s).threshold;
    required_coverage_percent = scenarios(s).required_coverage;

    fprintf('\n=== Running Scenario %d: M=%d, Threshold=%ddBm, Coverage=%.0f%% ===\n', ...
        s, M, threshold/10, 100 * required_coverage_percent);

    % Load corresponding RSRP matrix
    rsrp_file = sprintf('results/RSRP_%d_APs.mat', M);
    if ~isfile(rsrp_file)
        fprintf('⚠️ Skipping: File not found: %s\n', rsrp_file);
        continue;
    end

    load(rsrp_file, 'RSRPdBm');
    AP_combinations = nchoosek(1:L, M);

    % Preallocate runtime storage
    time_bit  = zeros(num_trials, 1);
    time_prob = zeros(num_trials, 1);
    time_rand = zeros(num_trials, 1);
    
    %% --------------------- Run Trials ---------------------
    for t = 1:num_trials
        fprintf('  Trial %3d/%d\r', t, num_trials);

        % -------------------- Bitstring GA --------------------
        tic;
        result_bit = GA_bitstring_AP_selection( ...
            RSRPdBm, AP_combinations, M, L, threshold, ...
            required_coverage_percent, popSize_GA, numGenerations, ...
            mutationRate, patience_GA, tournamentSize);
        time_bit(t) = toc;

        results_bit(t) = struct( ...
            'coverage', result_bit.coverage, ...
            'avg_rsrp', result_bit.avg_rsrp * 0.1, ...
            'evaluations', result_bit.evaluations, ...
            'meets_coverage', result_bit.coverage >= required_coverage_percent, ...
            'best_idx', result_bit.best_index);
        

        % -------------------- Probabilistic GA --------------------
        tic;
        result_prob = GA_probabilistic_AP_selection( ...
            RSRPdBm, L, M, numGenerations, threshold, ...
            required_coverage_percent, popSize_PROB, alpha, patience_PROB);
        time_prob(t) = toc;

        results_prob(t) = struct( ...
            'coverage', result_prob.best_coverage, ...
            'avg_rsrp', result_prob.avg_rsrp * 0.1, ...
            'evaluations', result_prob.total_evaluations, ...
            'meets_coverage', result_prob.best_coverage >= required_coverage_percent, ...
            'best_idx', result_prob.best_index);

        % -------------------- Random Selection --------------------
        tic;
        result_rand = random_selection( ...
            RSRPdBm, threshold, required_coverage_percent, ...
            max_evals_random);
        time_rand(t) = toc;

        results_rand(t) = struct( ...
            'coverage', result_rand.best_fitness, ...
            'avg_rsrp', result_rand.avg_rsrp * 0.1, ...
            'evaluations', result_rand.evaluations_used, ...
            'meets_coverage', result_rand.best_fitness >= required_coverage_percent, ...
            'best_idx', result_rand.best_index);
    end

    %% --------------------- Save Results --------------------
    result_filename = sprintf('results/comparison_M%d_th%d_cov%.0f.mat',...
        M, threshold/10, 100 * required_coverage_percent);
    threshold = threshold/10;
    save(result_filename, ...
        'results_bit', 'results_prob', 'results_rand', ...
        'time_bit', 'time_prob', 'time_rand', ...
        'M', 'threshold', 'required_coverage_percent');
    fprintf('✅ Saved results to: %s\n', result_filename);
end

fprintf('\n✅ All scenarios completed.\n');