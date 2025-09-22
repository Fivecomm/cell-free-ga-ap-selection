%=========================================================================%
% FILE:        compare_GA_solutions.m
% DESCRIPTION: This script executes two GA-based AP selection algorithms 
%              (bitstring GA and probabilistic GA) and a random 
%              selection algorithm for multiple scenarios. Results for 
%              coverage, number of evaluations, and runtime are saved 
%              for later comparison.
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

    % Initialize result arrays
    results_GA   = zeros(num_trials, 3);
    results_prob = zeros(num_trials, 3);
    results_rand = zeros(num_trials, 3);

    % Preallocate runtime storage
    time_GA   = zeros(num_trials, 1);
    time_prob = zeros(num_trials, 1);
    time_rand = zeros(num_trials, 1);
    
    %% --------------------- Run Trials ---------------------
    for t = 1:num_trials
        fprintf('  Trial %3d/%d\r', t, num_trials);

        % -------------------- Bitstring GA --------------------
        tic;
        result_ga = GA_bitstring_AP_selection( ...
            RSRPdBm, AP_combinations, M, L, threshold, ...
            required_coverage_percent, popSize_GA, numGenerations, ...
            mutationRate, patience_GA, tournamentSize);
        time_GA(t) = toc;

        results_GA(t, :) = [...
            result_ga.coverage, result_ga.evaluations, ...
            result_ga.coverage >= required_coverage_percent];
        

        % -------------------- Probabilistic GA --------------------
        tic;
        result_prob = GA_probabilistic_AP_selection( ...
            RSRPdBm, L, M, numGenerations, threshold, ...
            required_coverage_percent, popSize_PROB, alpha, patience_PROB);
        time_prob(t) = toc;

        results_prob(t, :) = [ ...
            result_prob.best_coverage, ...
            result_prob.total_evaluations, ...
            result_prob.best_coverage >= required_coverage_percent ...
        ];

        % -------------------- Random Selection --------------------
        tic;
        result_rand = random_selection( ...
            RSRPdBm, threshold, required_coverage_percent, ...
            max_evals_random);
        time_rand(t) = toc;

        results_rand(t, :) = [ ...
            result_rand.best_fitness, ...
            result_rand.evaluations_used, ...
            result_rand.best_fitness >= required_coverage_percent ...
        ];
    end

    %% --------------------- Save Results ---------------------
    result_filename = sprintf('results/comparison_M%d_th%d_cov%.0f.mat',...
        M, threshold/10, 100 * required_coverage_percent);
    save(result_filename, ...
        'results_GA', 'results_prob', 'results_rand', ...
        'time_GA', 'time_prob', 'time_rand', ...
        'M', 'threshold', 'required_coverage_percent');
    fprintf('✅ Saved results to: %s\n', result_filename);
end

fprintf('\n✅ All scenarios completed.\n');