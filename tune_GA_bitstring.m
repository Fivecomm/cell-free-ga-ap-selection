%% ========================================================================
% SCRIPT:      tune_GA_bitstring.m
% DESCRIPTION: Grid search over Genetic Algorithm (bitstring version) 
%              hyperparameters for Access Point (AP) selection in cell-free
%              massive MIMO. Evaluates coverage performance, convergence, 
%              and robustness.
%
% REFERENCE:   Guillermo García-Barrios, Martina Barbi and Manuel Fuentes
%              "Genetic Algorithm-Based Optimization of AP Activation for 
%              Static Coverage in Cell-Free," IEEE International Conference
%              on Communications (ICC), Glasgow, Scotland, UK, 2025. 
%              [Submitted]
%
% VERSION:     1.0 (Last edited: 2025-09-22)
% AUTHOR:      Guillermo García-Barrios, Fivecomm
% LICENSE:     GPLv2 – If you use this code for research that results in 
%              publications, please cite our monograph as described above.
% ======================================================================= %

clc; clear; close all;

%% ---------------------- Load Data ---------------------------------------
load('results/RSRP_18_APs.mat', 'RSRPdBm');  % [N_comb x N_UE]
fprintf("✅ Loaded RSRP matrix with %d combinations and %d UEs.\n", ...
    size(RSRPdBm,1), size(RSRPdBm,2));

%% ---------------------- GA Parameters ----------------------------------
threshold = -90;                       % Coverage threshold [dBm]
required_coverage_percent = 0.90;      % Target UE coverage
L = 24;                                % Total APs
M = 18;                                % APs selected
num_trials = 30;                       % Independent runs per config
numGenerations = 50;                   % Max GA generations
patience = 10;                         % Early stopping tolerance

% Tuning grid
pop_sizes       = [10, 20, 50];
mutation_rates  = [0.1, 0.3, 0.6, 0.9];
tournament_sizes= [2, 3, 5];

%% ---------------------- Results Storage --------------------------------
results = [];  % Struct array to store each setting

%% ---------------------- Grid Search ------------------------------------
AP_combinations = nchoosek(1:L, M);  % [N_comb x M]
exp_id = 1;

for p = 1:length(pop_sizes)
    for m = 1:length(mutation_rates)
        for t = 1:length(tournament_sizes)

            fprintf( ...
                "\n🔍 Testing config %d: pop=%d, mut=%.2f, tourn=%d\n",...
                exp_id, pop_sizes(p), mutation_rates(m), ...
                tournament_sizes(t));

            all_fitness = zeros(num_trials, 1);
            all_success = zeros(num_trials, 1);
            all_evals = zeros(num_trials, 1);

            for trial = 1:num_trials
                result = GA_bitstring_AP_selection( ...
                    RSRPdBm, AP_combinations, M, L, threshold, ...
                    required_coverage_percent, ...
                    pop_sizes(p), numGenerations, ...
                    mutation_rates(m), patience, tournament_sizes(t));

                all_fitness(trial) = result.best_fitness;
                all_success(trial) = result.coverage >= ...
                                     required_coverage_percent;
                all_evals(trial)   = result.evaluations;
            end
            
            % Store aggregated results
            results(exp_id).popSize         = pop_sizes(p);
            results(exp_id).mutationRate    = mutation_rates(m);
            results(exp_id).tournamentSize  = tournament_sizes(t);
            results(exp_id).avgFitness      = mean(all_fitness);
            results(exp_id).successRate     = mean(all_success);
            results(exp_id).avgEvaluations  = mean(all_evals);

            exp_id = exp_id + 1;
        end
    end
end

%% ---------------------- Display Summary --------------------------------
fprintf("\n==================== TUNING SUMMARY ====================\n");
for i = 1:length(results)
    fprintf(["pop=%2d, mut=%.2f, tourn=%d | success=%.1f%% |", ...
        " avgFit=%.3f | evals=%.1f\n"],  results(i).popSize, ...
        results(i).mutationRate, results(i).tournamentSize, ...
        100 * results(i).successRate, results(i).avgFitness, ...
        results(i).avgEvaluations);
end

%% ---------------------- Best Configuration -----------------------------
[~, best_idx] = max([results.successRate]);
best = results(best_idx);

fprintf("\n🏆 Best config: pop=%d, mut=%.2f, tourn=%d\n", ...
    best.popSize, best.mutationRate, best.tournamentSize);
fprintf("   Success Rate: %.1f%%\n", 100 * best.successRate);
fprintf("   Avg Fitness:  %.3f\n", best.avgFitness);
fprintf("   Avg Evals:    %.1f\n", best.avgEvaluations);
