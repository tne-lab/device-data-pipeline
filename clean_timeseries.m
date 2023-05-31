function logfile_folder = clean_timeseries(logfile_folder)
%This function cleans the downsampled *.mat files by removing bad channels
%and bipolar reref. Use file selection dialog to select a log_file.mat and
%this will enable cleaning all *.mat files in the same folder. Assumes
%*.mat files were created by using create_ds_data.m.

% Outputs:
% 1. appends new data to the *.mat files. Specifically data_good_chan which
% has the removed bad channels and clean_filt_data which has been bipolar
% referenced and then lowpass filtered according to the cutoff frequency
% specified.
% 2. returns the folder that the logfile was from
%
% By M. Schatza - Created on 10/9/2021
% Last updated: 05/31/2023 JT to consolidate and clean up parts we arent
% using, left in some to make other things work

% grab data file
[file, logfile_folder] = uigetfile;
if isempty(logfile_folder)
    [~, logfile_folder]= uigetfile;
end

addpath("") %addpath to ft_channelselection

% get data from log file
log_data = load([logfile_folder, '/log_file.mat']);

% read-in only the pre- & post- Raw files.
tmp = cellstr(log_data.paths);
log_data.paths = char(tmp(cellfun(@(x) or(or(contains(x,'RAW'), contains(x, 'raw')), contains(x,'Raw')),tmp)));


data_struct = {};
%% loop through all paths in log file to clean (load in data once)
for i = 1:size(log_data.paths)
    % get cur path
    cur_path = strtrim(log_data.paths(i,:)); % paths save with whitespace, strtrim makes words looks nice
    % find corresponding data mat
    if ispc
        folder_split = split(logfile_folder, '\');
    else
        folder_split = split(logfile_folder, '/');
    end

    try
        cur_data = load([logfile_folder, cur_path, '_', char(folder_split(end-2)), '_', char(folder_split(end-1)), '_cleandata_struct.mat']);
    catch
        cur_data = load([logfile_folder, cur_path, '_', char(folder_split(end-3)), '_', char(folder_split(end-1)), '_cleandata_struct.mat']);  %'_', char(folder_split(end-2))   char(folder_split(end-3)
    end
    data_struct{i} = cur_data.cur_data;
end

%% loop through all paths in log file to remove bad channels
for i = 1:size(log_data.paths)
    % Remove bad channels
    data.label = data_struct{i}.labels';
    data.time = {data_struct{i}.seconds'};
    data.trial = {data_struct{i}.ds_data};

    % kept in to not mess with subsequent loops
    cfg          = [];
    cfg.method   = 'channel';
    cfg.ylim     = [-5000 5000];
    data_good_chan      = ft_rejectartifact(cfg, data);
    data_struct{i}.data_good_chan = data_good_chan;
end


%% re-ref and filter
cutoff_freq = 40; %%%%%%%% Make this changeable?
[b,a] = butter(2, cutoff_freq / (data_struct{i}.sample_rate / 2));
for i = 1:size(log_data.paths)
    label = {};
    trial = [];
    cur_index = 1;
    for ILcomb = 1:2:8 % possibly 4 bipolar IL channels
        if ILcomb==1
            temp_data = data_struct{i}.data_good_chan.trial{1};
            new_data = temp_data(ismember(data_struct{i}.data_good_chan.label, ['IL', num2str(ILcomb)])',:);
            filter_new_data = filtfilt(b,a, new_data);
            label{cur_index} = ['IL', num2str(ILcomb),'-','IL',num2str(ILcomb+1)];
            trial{cur_index}= filter_new_data;
            cur_index = cur_index + 1;
        else
            temp_data = data_struct{i}.data_good_chan.trial{1};
            new_data = temp_data(ismember(data_struct{i}.data_good_chan.label, ['IL', num2str(ILcomb)])',:) - temp_data(ismember(data_struct{i}.data_good_chan.label, ['IL', num2str(ILcomb+1)])',:);
            filter_new_data = filtfilt(b,a, new_data);
            label{cur_index} = ['IL', num2str(ILcomb),'-','IL',num2str(ILcomb+1)];
            trial{cur_index}= filter_new_data;
            cur_index = cur_index + 1;
        end

    end

    for BLAcomb = 1:2:8 % possibly 4 bipolar BLA channels
        temp_data = data_struct{i}.data_good_chan.trial{1};
        new_data = temp_data(ismember(data_struct{i}.data_good_chan.label, ['BLA', num2str(BLAcomb)])',:) - temp_data(ismember(data_struct{i}.data_good_chan.label, ['BLA', num2str(BLAcomb+1)])',:);
        filter_new_data = filtfilt(b,a, new_data);
        label{cur_index} = ['BLA', num2str(BLAcomb),'-','BLA',num2str(BLAcomb+1)];
        trial{cur_index} = filter_new_data;
        cur_index = cur_index + 1;

    end

    temp_trial = zeros(size(trial,2), size(trial{1},2));
    for j = 1:size(trial,2)
        temp_trial(j,:) = trial{j};
    end

    data = {};
    data.trial = {temp_trial};
    data.label = label';
    data.time = data_struct{i}.data_good_chan.time;
    data.lowpass_cutoff = cutoff_freq;
    data.fsample = 1000;
    data.ratID = log_data.rat;
    data.recday_cond = log_data.day;
    data.label = data_struct{i}.label;
    data.path = data_struct{i}.path;

    data_struct{i}.clean_filt_data = data;
    cur_data = data_struct{i}.clean_filt_data;

    % get cur path
    cur_path = strtrim(log_data.paths(i,:)); % paths save with whitespace, strtrim makes words looks nice

    % overwrite corresponding data mat
    if ispc
        folder_split = split(logfile_folder, '\');
    else
        folder_split = split(logfile_folder, '/');
    end

    save([logfile_folder, cur_path, '_', char(folder_split(end-2)), '_', char(folder_split(end-1)), '_cleandata_struct.mat'], 'cur_data');
end
end