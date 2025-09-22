%% ========================================================================
% SCRIPT:      results_computationTime.m
%
% DESCRIPTION: Extracts and aggregates computation time results for GA 
%              solutions (bitstring GA, probabilistic GA, and random 
%              baseline). Produces a summary table with averages and 
%              standard deviations of execution time across multiple 
%              trials, then writes results to Excel for analysis.
%
% INPUT:
%   Folder: "results"
%     • comparison_M{M}_th-{threshold}_cov{coverage}.mat
%       Each file must contain:
%         - time_GA   [trials x 1] → execution times (s) for bitstring GA
%         - time_prob [trials x 1] → execution times (s) for probabilistic GA
%         - time_rand [trials x 1] → execution times (s) for random baseline
%
% OUTPUT:
%   Excel file:
%     • results/summary_execution_times.xlsx
%   Table fields include average and standard deviation of runtime (seconds)
%   for each algorithm under different test scenarios.
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

%% ---------------------- Settings ----------------------------------------
results_folder = 'results';  
output_file = fullfile(results_folder, 'summary_execution_times.xlsx');

% Define test scenarios
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
    th  = abs(s.threshold/10);              % filenames use positive values
    cov = round(s.required_coverage*100);   % convert fraction → int %

    filename = sprintf('comparison_M%d_th-%d_cov%d.mat', s.M, th, cov);
    filepath = fullfile(results_folder, filename);

    if ~isfile(filepath)
        warning('File not found: %s', filepath);
        continue;
    end

    data = load(filepath);

    % Validate required time fields
    if ~isfield(data, 'time_GA') || ~isfield(data, 'time_prob') || ~isfield(data, 'time_rand')
        warning('Missing timing data in: %s', filepath);
        continue;
    end

    % Initialize entry
    entry = struct();
    entry.M         = s.M;
    entry.threshold = s.threshold;
    entry.coverage  = s.required_coverage;

    % ---- Bitstring GA ----
    entry.ga_avg_time = mean(data.time_GA);
    entry.ga_std_time = std(data.time_GA);

    % ---- Probabilistic GA ----
    entry.prob_avg_time = mean(data.time_prob);
    entry.prob_std_time = std(data.time_prob);

    % ---- Random Selection ----
    entry.rand_avg_time = mean(data.time_rand);
    entry.rand_std_time = std(data.time_rand);

    summary = [summary; entry];
end

%% ---------------------- Convert & Post-process --------------------------
summary_table = struct2table(summary);

% Round all timing fields to 3 significant figures
vars_to_round = {'ga_avg_time', 'ga_std_time', ...
                 'prob_avg_time', 'prob_std_time', ...
                 'rand_avg_time', 'rand_std_time'};

for i = 1:numel(vars_to_round)
    summary_table.(vars_to_round{i}) = ...
        round(summary_table.(vars_to_round{i}), 3, 'significant');
end

% Sort for clarity
summary_table = sortrows(summary_table, {'M', 'threshold', 'coverage'});

%% ---------------------- Export to Excel ---------------------------------
writetable(summary_table, output_file);
fprintf('✅ Execution time summary written to %s\n', output_file);
