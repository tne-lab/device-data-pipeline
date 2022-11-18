close all
clearvars

%% Load data, if needed
%Path to 10m "Pre_CL" recording
data_path =  'Z:\projmon\virginia-dev\01_EPHYSDATA\dev2218\day2_180stim\CLOSED_LOOP_Pre_2022-10-21_14-01-16\Record Node 104\experiment1\recording1';

% fetch LFP time-series at 30kHz
if ~exist(LFP, 'var')
    cont_data = load_open_ephys_binary([data_path, '\structure.oebin'], 'continuous', 1, 'mmap');
    %get the 'already re-referenced' LFP used for real-time phase 
    %estimation & convert to volts
    LFP.data = cont_data.Data.Data.mapped(1,:) * cont_data.Header.channels(1).bit_volts; % convert to volts
    LFP.seconds = double(cont_data.Timestamps) * (1.0/double(cont_data.Header.sample_rate)); % translate from timestamps to time (seconds)


% Fetch event data for sham
if ~exist(evt_sham, 'var')
    evt_data = load_open_ephys_binary([data_path, '\structure.oebin'], 'events', 3);
    evt_sham.timestamps = double(evt_data.Timestamps(evt_data.Data>0));
    evt_sham.seconds = evt_sham.timestamps * (1.0/double(evt_data.Header.sample_rate)); % translate from timestamps to time (seconds)
end


%% Redefine time-series as trials around the sham pulse for gt_phase calculation





%% Calculate the gt_phase


% loop through all sham events, show rose plot (maybe)
%% Compute error between target phase and phase at sham event


%% Compute weighted correction value for the threshold (using learning algorithm)


%% PLOT
% 1.) Adaptive threshold (y-axis) vs sham event number (x-axis)
% Assume we started our threshold at 135deg
% 2.) Error (y-axis) vs sham event number (x-axis)
% 3.) weighted correction factor (y-axis) vs sham event number (x-axis)


%% ANALYSIS
% What impact does the initial condition have on accuracy?
% Is the Pre-CL condition improving our accuracy in the 30m CL recording?



