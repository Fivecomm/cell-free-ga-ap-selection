function [N_PRB, OH_DL, OH_UL, Numerology, Ts] = getThParameters(BW, ...
    C_Spacing, Frequency)
%=========================================================================%
% FUNCTION:    getThParameters
% DESCRIPTION: Computes 5G NR Physical Resource Block (PRB) configuration 
%              and timing parameters based on system bandwidth, subcarrier 
%              spacing, and carrier frequency.
%
% INPUTS:
%   BW        - System bandwidth in MHz (e.g., 20, 50, 100)
%   C_Spacing - Subcarrier spacing in kHz (e.g., 15, 30, 60, 120, 480, 960)
%   Frequency - Carrier frequency in GHz (used to determine FR1/FR2)
%
% OUTPUTS:
%   N_PRB      - Number of Physical Resource Blocks (PRBs) as per 3GPP
%   OH_DL      - Downlink overhead fraction
%   OH_UL      - Uplink overhead fraction
%   Numerology - Numerology index μ, where Δf = 2^μ * 15 kHz
%   Ts         - Slot duration in seconds, computed as (1 ms)/(14 × 2^μ)
%
% DESCRIPTION:
%   Determines the appropriate 5G NR numerology, number of PRBs, and slot
%   duration according to 3GPP TS 38.104. Supports both FR1 (Sub-6 GHz) 
%   and FR2 (mmWave) operating bands.
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

%% --------------------- Determine Frequency Range ----------------------
if Frequency >= 1.0 && Frequency <= 7.0
    FR = 1; % FR1: Sub-6 GHz
elseif Frequency >= 24.0 && Frequency <= 52.0
    FR = 2; % FR2: mmWave
else
    error('Frequency must be in FR1 (1–7 GHz) or FR2 (24–52 GHz).');
end

%% --------------------- Initialize Default Values ---------------------
N_PRB = 0;

%% --------------------- Lookup N_PRB Table ----------------------------
switch C_Spacing
    case 15
        PRBtable = [5 25; 10 52; 15 79; 20 106; 25 133; 30 160; ...
                    35 188; 40 216; 45 242; 50 270];
    case 30
        PRBtable = [5 11; 10 24; 15 38; 20 51; 25 65; 30 78; ...
                    35 92; 40 106; 45 119; 50 133; 60 162; 70 189; ...
                    80 217; 90 245; 100 273];
    case 60
        PRBtable = [10 11; 15 18; 20 24; 25 31; 30 38; 35 44; ...
                    40 51; 45 58; 50 65; 60 79; 70 93; 80 107; ...
                    90 121; 100 135];
        if BW == 50 && FR == 2, N_PRB = 66; end
        if BW == 100 && FR == 2, N_PRB = 132; end
        if BW == 200 && FR == 2, N_PRB = 264; end
    case 120
        if FR == 2
            PRBtable = [50 32; 100 66; 200 132; 400 264];
        else
            PRBtable = [];
        end
    case 480
        if FR == 2
            PRBtable = [400 66; 800 124; 1600 248];
        else
            PRBtable = [];
        end
    case 960
        if FR == 2
            PRBtable = [400 33; 800 62; 1600 124; 2000 148];
        else
            PRBtable = [];
        end
    otherwise
        PRBtable = [];
end

% Lookup N_PRB if not pre-defined
if N_PRB == 0 && ~isempty(PRBtable)
    idx = find(PRBtable(:,1) == BW, 1);
    if ~isempty(idx)
        N_PRB = PRBtable(idx, 2);
    else
        error('Unsupported bandwidth for the given subcarrier spacing.');
    end
end

%% --------------------- Overheads -------------------------------------
if FR == 2
    OH_DL = 0.18;  % Downlink overhead for FR2
    OH_UL = 0.10;  % Uplink overhead for FR2
elseif FR == 1
    OH_DL = 0.14;  % Downlink overhead for FR1
    OH_UL = 0.08;  % Uplink overhead for FR1
end

%% --------------------- Numerology Index μ ----------------------------
switch C_Spacing
    case 15, Numerology = 0;
    case 30, Numerology = 1;
    case 60, Numerology = 2;
    case 120, Numerology = 3;
    case 480, Numerology = 5;
    case 960, Numerology = 6;
    otherwise, Numerology = -1;  % Invalid
end

%% --------------------- Slot Duration Ts -------------------------------
if Numerology >= 0
    Ts = (1e-3) / (14 * 2^Numerology);  % Slot duration in seconds
else
    Ts = NaN;
end

end