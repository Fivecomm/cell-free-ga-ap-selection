%% ========================================================================
% SCRIPT:      results_performance.m
%
% DESCRIPTION: Extracts and aggregates performance results from executed
%              GA solutions (bitstring GA, probabilistic GA, and random
%              baseline). Produces a summary table with averages, standard 
%              deviations, and success rates, then writes results to Excel
%              for further analysis.
%
% INPUT:
%   Folder: "results"
%     • comparison_M{M}_th-{threshold}_cov{coverage}.mat
%       Each file must contain:
%         - results_GA   [trials x 3] → [fitness, evaluations, success]
%         - results_prob [trials x 3]
%         - results_rand [trials x 3]
%
% OUTPUT:
%   Excel file:
%     • results/summary_table_with_sd.xlsx
%   Table fields include average fitness, std dev, avg evals, std evals, 
%   and success rates for each algorithm.
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

%% ---------------------- Settings ----------------------------------------
results_folder = 'results';  
output_file = fullfile(results_folder, 'summary_table_with_sd.xlsx');

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

    % Initialize entry
    entry = struct();
    entry.M         = s.M;
    entry.threshold = s.threshold;
    entry.coverage  = s.required_coverage;

    % ---- Bitstring GA ----
    entry.ga_avg_fitness    = mean(data.results_GA(:,1));
    entry.ga_std_fitness    = std(data.results_GA(:,1));
    entry.ga_avg_evals      = mean(data.results_GA(:,2));
    entry.ga_std_evals      = std(data.results_GA(:,2));
    entry.ga_success_rate   = mean(data.results_GA(:,3));

    % ---- Probabilistic GA ----
    entry.prob_avg_fitness  = mean(data.results_prob(:,1));
    entry.prob_std_fitness  = std(data.results_prob(:,1));
    entry.prob_avg_evals    = mean(data.results_prob(:,2));
    entry.prob_std_evals    = std(data.results_prob(:,2));
    entry.prob_success_rate = mean(data.results_prob(:,3));

    % ---- Random Selection ----
    entry.rand_avg_fitness  = mean(data.results_rand(:,1));
    entry.rand_std_fitness  = std(data.results_rand(:,1));
    entry.rand_avg_evals    = mean(data.results_rand(:,2));
    entry.rand_std_evals    = std(data.results_rand(:,2));
    entry.rand_success_rate = mean(data.results_rand(:,3));

    summary = [summary; entry];
end

%% ---------------------- Convert & Post-process --------------------------
summary_table = struct2table(summary);

% Scale fitness (× -100) and success rates (× 100 → %)
fitness_fields = {'ga_avg_fitness', 'prob_avg_fitness', ...
    'rand_avg_fitness', 'ga_std_fitness', 'prob_std_fitness', ...
    'rand_std_fitness'};
success_fields = {'ga_success_rate', 'prob_success_rate', ...
    'rand_success_rate'};

for i = 1:numel(fitness_fields)
    summary_table.(fitness_fields{i}) = ...
        -100 * summary_table.(fitness_fields{i});
end

for i = 1:numel(success_fields)
    summary_table.(success_fields{i}) = ...
        100 * summary_table.(success_fields{i});
end

% Round numeric values to 3 significant figures
vars_to_round = [fitness_fields, ...
                 {'ga_avg_evals', 'prob_avg_evals', 'rand_avg_evals' ,...
                  'ga_std_evals', 'prob_std_evals', 'rand_std_evals'}, ...
                 success_fields];

for i = 1:length(vars_to_round)
    var = vars_to_round{i};
    summary_table.(var) = round(summary_table.(var), 3, 'significant');
end

% Sort for clarity
summary_table = sortrows(summary_table, {'M', 'threshold', 'coverage'});

%% ---------------------- Export to Excel ---------------------------------
writetable(summary_table, output_file);
fprintf('✅ Summary written to %s\n', output_file);