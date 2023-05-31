function logfile_folder = create_ds_data(logfile_folder)
%This function does the *.binary to *.mat conversion of Open Ephys
%recordings and downsamples to 1 kHz.
% Key Assumptions for this script:
% 1. Assumes an a priori understanding of Recording Nodes (& their names)
%    within the OEP signal chain used for recording. (111 for raw data and
%    112 for event/phase data, 114 for bipolar data) ---- not sure if these
%    nodes are right - we check it with ConfirmNode_quick_check.m
% 2. Assumes data to be analyzed is located at "\experiment1\recording1\"

% Outputs:
% 1. creates *.mat files next to log_file.mat for each corresponding
% recording
% 2. returns the folder that the logfile was from
%
% By M. Schatza - Created on 10/9/2021
% Last updated: 5/31/2023 JT - consolidated script to delete commented
% lines that havent been used in our analysis

[file, logfile_folder] = uigetfile;
if isempty(logfile_folder)
    [~, logfile_folder]= uigetfile;
end

% get data from log file
log_data = load([logfile_folder, '\log_file.mat']);

% get all folders next to log file
folder_list = ls(logfile_folder);

tmp = cellstr(log_data.paths);
log_data.paths = char(tmp(cellfun(@(x) or(or(contains(x,'RAW'), contains(x, 'raw')), contains(x, 'Raw')),tmp)));

% loop through all paths in log file
for i = 1:size(log_data.paths)
    % get cur path
    cur_path = strtrim(log_data.paths(i,:)); % paths save with whitespace, strtrim makes words looks nice
    cur_data = struct();
    % find corresponding folder in path
    for j = 1:size(folder_list)
        if contains(folder_list(j,:), cur_path)
            % this is my folder
            cur_data.path = [logfile_folder, strtrim(folder_list(j,:))];
            cur_data.label = cur_path;


            %is *.continuous or binary data?
            existingfiles = [numel(dir(fullfile(cur_data.path,'*continuous')))>0, ...
                numel(dir(fullfile(cur_data.path,'*oebin')))>0];
            fullfile(cur_data.path, '*continuous')


            cont_data_111 = load_open_ephys_binary([cur_data.path, '\Record Node 114\experiment1\recording1\structure.oebin'], 'continuous', 1);


            % downsample data and ts
            cur_data.sample_rate = 1000; % ds to 1 kHz
            cur_data.ds_factor = cont_data_111.Header.sample_rate / cur_data.sample_rate;
            tempdata = downsample(cont_data_111.Data', cur_data.ds_factor)';
            tempdata = tempdata * cont_data_111.Header.channels(1).bit_volts; % convert to volts

            temp_seconds = double(cont_data_111.Timestamps) * (1.0/double(cont_data_111.Header.sample_rate)); % translate from timestamps to time (seconds)
            cur_data.seconds = downsample(temp_seconds, cur_data.ds_factor); % cut down to ds_data size

            cur_data.header = cont_data_111.Header;
            cur_data.ds_data = tempdata(1:16,1:size(cur_data.seconds,1)); % only want channels 1 - 16

            cur_data.labels = {'IL1'; 'IL2'; 'IL3'; 'IL4'; 'IL5'; 'IL6'; 'IL7'; 'IL8'; ...
                'BLA1'; 'BLA2'; 'BLA3'; 'BLA4'; 'BLA5'; 'BLA6'; 'BLA7'; 'BLA8'}; % make chan labels


            % save event and log_data
            cur_data.log_data = log_data;

            % write new mat file with only relevant info
            if ispc
                folder_split = split(logfile_folder, '\');
            else
                folder_split = split(logfile_folder, '/');
            end
            save([logfile_folder, cur_data.label, '_', char(folder_split(end-2)), '_', char(folder_split(end-1)), '_cleandata_struct.mat'], 'cur_data');
            break;
        end
    end
end
end