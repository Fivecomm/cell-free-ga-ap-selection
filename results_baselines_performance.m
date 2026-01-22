%==========================================================================
% FILE:        results_baselines_performance.m
% DESCRIPTION: Extracts and aggregates performance results from baseline
%              AP selection algorithms (Greedy and Local Search). Produces
%              a summary table with average fitness, number of evaluations,
%              and success rates, and exports the results to Excel.
%
% INPUT:
%   Folder: "results"
%     • baselines_M{M}_th{threshold}_cov{coverage}.mat
%       Each file must contain:
%         - results_greedy [trials x struct]
%         - results_local  [trials x struct]
%
% OUTPUT:
%   Excel file:
%     • results/summary_baselines.xlsx
%
% REFERENCE:   Guillermo García-Barrios, Martina Barbi and Manuel Fuentes,
%              "Access Point Activation for Static Area-Wide Coverage in
%              Cell-Free Massive MIMO Networks," 2026 Joint European
%              Conference on Networks and Communications & 6G Summit
%              (EuCNC/6G Summit), Málaga, Spain, 2026. [Submitted]
%
% VERSION:     1.0 (Last edited: 2026-01-22)
% AUTHOR:      Guillermo García-Barrios, Fivecomm
% LICENSE:     GPLv2 – If you use this code for research that results in
%              publications, please cite our monograph as described above.
%==========================================================================

clc; clear; close all;

%% ---------------------- Settings ----------------------------------------
results_folder = 'results';
output_file = fullfile(results_folder, 'summary_baselines_with_sd.xlsx');

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

%% ---------------------- Process Scenarios -------------------------------
summary = [];

for i = 1:length(scenarios)
    s   = scenarios(i);
    th  = abs(s.threshold/10);
    cov = round(s.required_coverage * 100);

    filename = sprintf('baselines_M%d_th-%d_cov%d.mat', s.M, th, cov);
    filepath = fullfile(results_folder, filename);

    if ~isfile(filepath)
        warning('File not found: %s', filepath);
        continue;
    end

    data = load(filepath);

    % Extract vectors
    greedy_cov   = [data.results_greedy.coverage];
    greedy_eval  = [data.results_greedy.evaluations];
    greedy_succ  = [data.results_greedy.meets_coverage];

    local_cov    = [data.results_local.coverage];
    local_eval   = [data.results_local.evaluations];
    local_succ   = [data.results_local.meets_coverage];

    entry = struct();
    entry.M         = s.M;
    entry.threshold = s.threshold;
    entry.coverage  = s.required_coverage;

    % ---- Greedy ----
    entry.greedy_avg_fitness  = mean(greedy_cov);
    entry.greedy_std_fitness  = std(greedy_cov);
    entry.greedy_avg_evals    = mean(greedy_eval);
    entry.greedy_std_evals    = std(greedy_eval);
    entry.greedy_success_rate = mean(greedy_succ);

    % ---- Local Search ----
    entry.local_avg_fitness   = mean(local_cov);
    entry.local_std_fitness   = std(local_cov);
    entry.local_avg_evals     = mean(local_eval);
    entry.local_std_evals     = std(local_eval);
    entry.local_success_rate  = mean(local_succ);

    summary = [summary; entry];
end

%% ---------------------- Convert & Post-process --------------------------
summary_table = struct2table(summary);

% Scale coverage and success rate to %
fitness_fields = {'greedy_avg_fitness','local_avg_fitness',...
                  'greedy_std_fitness','local_std_fitness'};
success_fields = {'greedy_success_rate','local_success_rate'};

for f = fitness_fields
    summary_table.(f{1}) = 100 * summary_table.(f{1});
end

for f = success_fields
    summary_table.(f{1}) = 100 * summary_table.(f{1});
end

% Round values
vars_to_round = summary_table.Properties.VariableNames;
for v = 1:numel(vars_to_round)
    if isnumeric(summary_table.(vars_to_round{v}))
        summary_table.(vars_to_round{v}) = ...
            round(summary_table.(vars_to_round{v}), 3, 'significant');
    end
end

summary_table = sortrows(summary_table, {'M','threshold','coverage'});

%% ---------------------- Export ------------------------------------------
writetable(summary_table, output_file);
fprintf('✅ Baseline summary written to %s\n', output_file);
