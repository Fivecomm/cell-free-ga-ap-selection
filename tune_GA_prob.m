%% ========================================================================
% SCRIPT:      tune_GA_prob.m
% DESCRIPTION: Hyperparameter tuning for the probabilistic Genetic 
%              Algorithm (GA) used in Access Point (AP) selection for 
%              cell-free massive MIMO. Evaluates combinations of population
%              size, learning rate α, and early stopping patience to 
%              maximize coverage performance.
%
% REFERENCE:   Guillermo García-Barrios, Martina Barbi and Manuel Fuentes,
%              "Access Point Activation for Static Area-Wide Coverage in 
%              Cell-Free Massive MIMO Networks," 2026 Joint European 
%              Conference on Networks and Communications & 6G Summit 
%              (EuCNC/6G Summit), Málaga, Spain, 2026. [Submitted]
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

%% ---------------------- Fixed Parameters --------------------------------
L  = 24;                % Total APs
M  = 18;                % Number of APs to select
threshold = -90;        % Coverage threshold [dBm]
required_coverage_percent = 0.90;
numGenerations = 50;    % Max GA generations
numTrials      = 30;    % Independent runs per configuration

%% ---------------------- Tuning Grid -------------------------------------
pop_sizes = [10, 20, 50];
alphas    = [0.1, 0.3, 0.5, 0.8];
patiences = [5, 10, 15];

%% ---------------------- Results Container -------------------------------
results = struct([]);
exp_id = 1;

%% ---------------------- Grid Search -------------------------------------
for ps = 1:length(pop_sizes)
    for a = 1:length(alphas)
        for p = 1:length(patiences)

            fprintf("\n🔧 Config %d: pop=%d, α=%.2f, patience=%d\n", ...
                exp_id, pop_sizes(ps), alphas(a), patiences(p));

            fitness_all = zeros(numTrials,1);
            success_all = zeros(numTrials,1);
            evals_all   = zeros(numTrials,1);

            for trial = 1:numTrials
                result = GA_probabilistic_AP_selection( ...
                    RSRPdBm, L, M, numGenerations, threshold, ...
                    required_coverage_percent, ...
                    pop_sizes(ps), alphas(a), patiences(p));

                fitness_all(trial) = result.coverage_percent;
                success_all(trial) = result.coverage_percent >= ...
                                     required_coverage_percent;
                evals_all(trial)   = result.total_evaluations;
            end

            % Store aggregated results
            results(exp_id).popSize         = pop_sizes(ps);
            results(exp_id).alpha           = alphas(a);
            results(exp_id).patience        = patiences(p);
            results(exp_id).avgFitness      = mean(fitness_all);
            results(exp_id).successRate     = mean(success_all);
            results(exp_id).avgEvaluations  = mean(evals_all);

            exp_id = exp_id + 1;
        end
    end
end

%% ---------------------- Summary Output ----------------------------------
fprintf("\n==================== TUNING SUMMARY ====================\n");
for i = 1:length(results)
    fprintf(["pop=%2d, α=%.2f, patience=%2d | success=%.1f%% | ", ...
        "avgFit=%.3f | evals=%.1f\n"], results(i).popSize, ...
        results(i).alpha, results(i).patience, ...
        100*results(i).successRate, results(i).avgFitness, ...
        results(i).avgEvaluations);
end

%% ---------------------- Best Configuration ------------------------------
[~, best_idx] = max([results.successRate]);
best = results(best_idx);

fprintf("\n🏆 Best config:\n");
fprintf("   pop=%d | α=%.2f | patience=%d\n", ...
    best.popSize, best.alpha, best.patience);
fprintf("   Success Rate: %.1f%%\n", 100 * best.successRate);
fprintf("   Avg Fitness:  %.3f\n", best.avgFitness);
fprintf("   Avg Evals:    %.1f\n", best.avgEvaluations);
