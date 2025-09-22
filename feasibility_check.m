%=========================================================================%
% SCRIPT:      feasibility_check.m
% DESCRIPTION: This script evaluates the percentage of valid AP 
%              combinations for different numbers of APs, RSRP thresholds, 
%              and coverage requirements. A combination is valid if the 
%              fraction of UEs with RSRP above a threshold meets or exceeds
%              the coverage.
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

%% CONFIGURATION

% List of RSRP .mat files to process
rsrp_files = {
    'results/RSRP_20_APs.mat', ...
    'results/RSRP_18_APs.mat', ...
    'results/RSRP_16_APs.mat'
};

% RSRP thresholds [dBm] and coverage percentages [0–1]
rsrp_thresholds = -1000:20:-800;
coverage_percentages = 0.80:0.02:1.00;

% Storage structure
results = struct();

%% PROCESS EACH RSRP MATRIX

for f = 1:length(rsrp_files)
    filename = rsrp_files{f};
    
    % Load RSRP data
    try
        data = load(filename, 'RSRPdBm');
        RSRPdBm = data.RSRPdBm;
        [N_comb, N_UE] = size(RSRPdBm);
        fprintf("✅ Loaded %s with %d combinations, %d UEs.\n", ...
            filename, N_comb, N_UE);
    catch
        warning("❌ Failed to load RSRPdBm from %s. Skipping...", filename);
        continue;
    end

    % Initialize matrix for percentage of valid combinations
    percent_valid = zeros(length(rsrp_thresholds), ...
        length(coverage_percentages));

    %% LOOP OVER THRESHOLDS AND COVERAGE

    for i = 1:length(rsrp_thresholds)
        for j = 1:length(coverage_percentages)
            thr = rsrp_thresholds(i);
            cov_req = coverage_percentages(j);

            valid = 0; % counter for valid combinations
            for row = 1:N_comb
                rsrp_vals = RSRPdBm(row, :);
                % fraction of UEs meeting threshold
                coverage = mean(rsrp_vals >= thr); 
                if coverage >= cov_req
                    valid = valid + 1;
                end
            end
            
            % Store percentage of valid combinations
            percent_valid(i, j) = 100 * valid / N_comb;
        end
    end

    %% SAVE RESULTS

    [~, name, ~] = fileparts(filename);  % e.g., 'RSRP_20_APs'
    result_struct = struct();
    result_struct.percent_valid = percent_valid;
    result_struct.rsrp_thresholds = rsrp_thresholds;
    result_struct.coverage_percentages = coverage_percentages;

    save_filename = fullfile('results', ['feasibility_' name '.mat']);
    save(save_filename, '-struct', 'result_struct');

    fprintf("📁 Saved results to %s\n", save_filename);

end