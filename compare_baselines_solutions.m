%==========================================================================
% FILE:        compare_baselines_solutions.m
% DESCRIPTION: Executes deterministic baseline AP selection algorithms
%              (Greedy and Local Search) for static coverage scenarios.
%              Results are stored for comparison with GA-based methods.
%
%              This script relies on per-AP RSRP values to avoid exhaustive
%              precomputation of all AP combinations.
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
clc; clear; close all;

%% --------------------- Define Scenarios -------------------------------
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

%% --------------------- General Parameters -----------------------------
num_trials = 100;   % Same number of trials as GA experiments
L = 24;             % Total number of APs

%% -------------------- Loop Through Scenarios ---------------------------
results_greedy(num_trials) = struct('coverage', [], ...
                                    'avg_rsrp', [], ...
                                    'evaluations', [], ...
                                    'meets_coverage', [], ...
                                    'best_idx', []);

results_local = results_greedy;

for s = 1:length(scenarios)

    M = scenarios(s).M;
    threshold = scenarios(s).threshold;
    required_coverage_percent = scenarios(s).required_coverage;

    fprintf('\n=== Baselines | Scenario %d: M=%d, Th=%ddBm, Cov=%.0f%% ===\n', ...
        s, M, threshold/10, 100 * required_coverage_percent);

    % Load RSRP matrix
    rsrp_file = sprintf('results/RSRP_%d_APs.mat', M);
    if ~isfile(rsrp_file)
        fprintf('⚠️ File not found: %s. Skipping scenario.\n', rsrp_file);
        continue;
    end

    load('results/RSRP_per_AP.mat', 'RSRP_AP_dBm');

    % Runtime storage
    time_greedy = zeros(num_trials, 1);
    time_local  = zeros(num_trials, 1);

    %% --------------------- Run Trials ---------------------
    for t = 1:num_trials
        fprintf('  Trial %3d/%d\r', t, num_trials);

        % -------------------- Greedy ------------------------
        tic;
        res_greedy = greedy_AP_selection(RSRP_AP_dBm, L, M, threshold);
        time_greedy(t) = toc;

        results_greedy(t) = struct( ...
            'coverage', res_greedy.coverage, ...
            'avg_rsrp', res_greedy.avg_rsrp * 0.1, ...
            'evaluations', res_greedy.evaluations, ...
            'meets_coverage', res_greedy.meets_coverage, ...
            'best_idx', []);

        % -------------------- Local Search ------------------
        tic;
        res_local = local_search_AP_selection( ...
            RSRP_AP_dBm, L, M, threshold, required_coverage_percent);
        time_local(t) = toc;

        results_local(t) = struct( ...
            'coverage', res_local.coverage, ...
            'avg_rsrp', res_local.avg_rsrp * 0.1, ...
            'evaluations', res_local.evaluations, ...
            'meets_coverage', res_local.meets_coverage, ...
            'best_idx', []);
    end

    %% --------------------- Save Results --------------------
    out_file = sprintf('results/baselines_M%d_th%d_cov%.0f.mat', ...
        M, threshold/10, 100 * required_coverage_percent);

    threshold = threshold / 10;

    save(out_file, ...
        'results_greedy', 'results_local', ...
        'time_greedy', 'time_local', ...
        'M', 'threshold', 'required_coverage_percent');

    fprintf('✅ Saved baseline results to: %s\n', out_file);
end

fprintf('\n✅ All baseline scenarios completed.\n');
