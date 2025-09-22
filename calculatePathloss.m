%=========================================================================%
% SCRIPT:      calculatePathloss.m
% DESCRIPTION: This script calculates pathloss based on channel traces
%              generated from digital twin of the Port of Valencia.
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

clc; close all; clear;

%% PARAMETERS

% Maximum number of allowed APs
L_MAX = 24;

% Number of antennas per AP
N = 4; 

% Noise figure [dB]
noiseFigure = 7;

% Bandwidth [Hz]
B = 20e6;

% Shadow fading parameters
sigma_sf = 4;    % standard deviation [dB]
decorr   = 9;    % decorrelation distance

% Paths for input data
PATH_DATA  = fullfile('data', 'coordinates');
PATH_UNITY = fullfile('data', 'channels');

% Select active APs for this scenario
idxAPs_logical = false(64, 1);
idxAPs_logical([1, 4:2:16, 25, 28:2:40, 49, 52:2:64]) = true;
idxAPs = find(idxAPs_logical); % indices of active APs

%% CONSTANTS

EPSILON = 1e-20;   % numerical safeguard for zero values

%% LOAD DATA

% Load AP positions and select those under study
load([PATH_DATA, '\posAPs.mat'], 'posAPs');
posAPs = posAPs(idxAPs, :);
APpositions = posAPs(:,1) + 1j * posAPs(:,2); % complex form

% Load UE positions (valid UEs only)
load([PATH_DATA, '\gridUEs.mat'], 'posUEs', 'idxValidUEs');
posUEs          = posUEs(idxValidUEs, :);
nPosUEs         = length(posUEs);
posUEs_complex  = posUEs(:,1) + 1j * posUEs(:,2);

%% PREPARE VARIABLES

% Pathloss matrix [dB]
pathlossdB = zeros(L_MAX, nPosUEs);

% UE positions (for spatial correlation)
UEpositions = complex(zeros(nPosUEs,1));

% Noise power (in dBm and linear scale)
noiseVariancedBm        = -174 + 10*log10(B) + noiseFigure;
noiseVarianceLinear     = 10^((noiseVariancedBm) / 10);

% Shadowing correlation matrix and realizations
shadowCorrMatrix        = sigma_sf^2*ones(nPosUEs,nPosUEs);
shadowAPrealizations    = zeros(nPosUEs,L_MAX);

%% MAIN LOOP OVER UEs

for k = 1:nPosUEs

    disp(['Position ', num2str(k), ' / ', num2str(nPosUEs)])

    % UE ID in the global set
    idUE = idxValidUEs(k);

    % Load channel data from Unity (per-UE text file)
    filename = [PATH_UNITY,'\Receptor_',num2str(idUE),'.txt'];
    data = readtable(filename, ...
                     'Delimiter','\t', ...
                     'ReadVariableNames',false);
    
    %% GAIN OVER NOISE (Large-scale fading coefficients)

    gainOverNoisedB = zeros(L_MAX,1);

    for l = 1:L_MAX

        % AP ID in the global set
        idAP = idxAPs(l);

        % Indices of this AP's antenna data in the file
        idxData = (1 + N * (idAP-1)):(N * idAP);
        
        % Replace zero values with EPSILON to avoid numerical issues
        zeroIndices = data{idxData, 5} == 0;
        data{idxData(zeroIndices), 5} = EPSILON;
        zeroIndices = data{idxData, 6} == 0;
        data{idxData(zeroIndices), 6} = EPSILON;
        
        % Channel matrix H (scaled by noise variance)
        H = data{idxData,5} + 1i * data{idxData,6} / ...
            sqrt(noiseVarianceLinear);
          
        % Correlation matrix (N x N) for UE k and AP l
        R = H * H';

        % Large-scale fading coefficients (linear and dB)
        gainOverNoise       = trace(R) / N;
        gainOverNoisedB(l)  = 10 * log10(gainOverNoise);

    end

    %% SHADOWING (Spatially correlated)

    UEposition = posUEs_complex(k); % current UE position
    
    % If this is not the first UE
    if k-1>0  
        % Compute distances from this UE to all previous ones
        shortestDistances = abs(UEposition - UEpositions(1:k-1));
        
        % Compute conditional mean and standard deviation necessary to
        % obtain the new shadow fading realizations, when the previous
        % UEs' shadow fading realization have already been generated.
        % This computation is based on Theorem 10.2 in "Fundamentals of
        % Statistical Signal Processing: Estimation Theory" by S. Kay
        newcolumn   = sigma_sf^2 * 2.^(-shortestDistances/decorr);
        term1       = newcolumn' / shadowCorrMatrix(1:k-1,1:k-1);
        meanvalues  = term1 * shadowAPrealizations(1:k-1,:);
        stdvalue    = sqrt(sigma_sf^2 - term1 * newcolumn); 
    else
        % First UE → independent shadow fading
        meanvalues = 0;
        stdvalue = sigma_sf;
        newcolumn = [];     
    end

    % Generate the shadow fading realizations
    shadowing = meanvalues + stdvalue*randn(1,L_MAX);

    % Update shadowing correlation matrix and store realizations
    shadowCorrMatrix(1:k-1,k) = newcolumn;
    shadowCorrMatrix(k,1:k-1) = newcolumn';
    shadowAPrealizations(k,:) = shadowing;

    % Store the UE position
    UEpositions(k) = UEposition; 

    %% PATHLOSS
    pathlossdB(:,k) = -gainOverNoisedB + shadowing' - noiseVariancedBm;

end

%% SAVE RESULTS

folderName = 'results/';
if ~exist(folderName, 'dir')
    mkdir(folderName);
end

save(fullfile(folderName, 'pathloss.mat'), 'pathlossdB', '-v7.3');