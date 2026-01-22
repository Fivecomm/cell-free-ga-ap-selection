%==========================================================================
% FILE:        results_computationTime_baselines.m
% DESCRIPTION: Extracts and aggregates execution time results for
%              deterministic baseline algorithms (Greedy and Local Search).
%              Computes average and standard deviation of runtime across
%              multiple trials and exports the results to Excel.
%
% INPUT:
%   Folder: "results"
%     • baselines_M{M}_th{threshold}_cov{coverage}.mat
%       Each file must contain:
%         - time_greedy [trials x 1]
%         - time_local  [trials x 1]
%
% OUTPUT:
%   Excel file:
%     • results/summary_execution_times_baselines.xlsx
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
output_file = fullfile(results_folder, ...
    'summary_execution_times_baselines.xlsx');

% Define test scenarios (same as GA experiments)
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

    filename = sprintf('baselines_M%d_th-%d_cov%d.mat', ...
        s.M, th, cov);
    filepath = fullfile(results_folder, filename);

    if ~isfile(filepath)
        warning('File not found: %s', filepath);
        continue;
    end

    data = load(filepath);

    if ~isfield(data, 'time_greedy') || ~isfield(data, 'time_local')
        warning('Missing timing data in: %s', filepath);
        continue;
    end

    % Initialize entry
    entry = struct();
    entry.M         = s.M;
    entry.threshold = s.threshold;
    entry.coverage  = s.required_coverage;

    % ---- Greedy ----
    entry.greedy_avg_time = mean(data.time_greedy);
    entry.greedy_std_time = std(data.time_greedy);

    % ---- Local Search ----
    entry.local_avg_time = mean(data.time_local);
    entry.local_std_time = std(data.time_local);

    summary = [summary; entry];

end

%% ---------------------- Convert & Post-process --------------------------
summary_table = struct2table(summary);

% Round timing fields (3 significant figures)
vars_to_round = {
    'greedy_avg_time', 'greedy_std_time', ...
    'local_avg_time',  'local_std_time'
};

for i = 1:numel(vars_to_round)
    summary_table.(vars_to_round{i}) = ...
        round(summary_table.(vars_to_round{i}), 3, 'significant');
end

% Sort for clarity
summary_table = sortrows(summary_table, {'M', 'threshold', 'coverage'});

%% ---------------------- Export to Excel ---------------------------------
writetable(summary_table, output_file);
fprintf('✅ Baseline execution time summary written to %s\n', output_file);
