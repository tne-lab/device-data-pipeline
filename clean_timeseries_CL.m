function logfile_folder = clean_timeseries_CL(logfile_folder)
%This function cleans the downsampled *.mat files by removing bad channels
%and bipolar reref. Use file selection dialog to select a log_file.mat and
%this will enable cleaning all *.mat files in the same folder. Assumes
%*.mat files were created by using create_ds_data.m.

% Outputs:
% 1. appends new data to the *.mat files. Specifically data_good_chan which
% has the removed bad channels and clean_filt_data which has been bipolar
% referenced and then lowpass filtered according to the cutoff frequency
% specified  
% 2. returns the folder that the logfile was from
%
% By M. Schatza - Created on 10/9/2021
% Last updated: 10/90


% ft_rejectartifact gives timestamps to remove

% grab data file
%[file, logfile_folder] = uigetfile;
% logfile_folder='E:\fakedatatesting\day3\';

% get data from log file
logfile_folder='Z:\projmon\virginia-dev\01_EPHYSDATA\dev2218\day2_180stim'; % Change this to desired file
dofilt=0; % Set to 1 if you want the butterworth filter on

log_data = load([logfile_folder, '/log_file.mat']);
%load(logfile_path);

% bad channels are saved across a single day
daily_bad_channels = [];
reset_bad_chan = false;

% read-in only the pre- & post- Raw files.
tmp = cellstr(log_data.paths);
log_data.paths = char(tmp(cellfun(@(x) or(contains(x,'CLOSED'), contains(x, 'closed')),tmp)));



data_struct = {};
%% loop through all paths in log file to clean (load in data once)
for i = 1:size(log_data.paths)
    % get cur path
    cur_path = strtrim(log_data.paths(i,:)); % paths save with whitespace, strtrim makes words looks nice
    cur_path='CLOSED';
    % find corresponding data mat
    if ispc
        folder_split = split(logfile_folder, '\');
    else
        folder_split = split(logfile_folder, '/');
    end
    a=char(folder_split(end));
    try
        cur_data = load([logfile_folder,'\', cur_path, '_', char(folder_split(end-2)), '_', char(folder_split(end-1)), '_cleandata_struct.mat']);
    catch
        cur_data = load([logfile_folder, '/',cur_path, '_', char(folder_split(end-3)), '_', char(folder_split(end-2)), '_cleandata_struct.mat']);
    end
    data_struct{i} = cur_data.cur_data;
end

%% loop through all paths in log file to remove bad channels
for i = 1:size(log_data.paths)
    % Remove bad channels
    data.label = data_struct{i}.labels';
    data.time = {data_struct{i}.seconds'};
    data.trial = {data_struct{i}.ds_data};

    % remove prev bad chan
    chans_to_select = {'all'};
    for j = 1:size(daily_bad_channels, 1)
        chans_to_select{end+1} = ['-', daily_bad_channels{j}];
    end
    cfg = [];
    cfg.channel = ft_channelselection(chans_to_select, data);
    data = ft_selectdata(cfg, data);

    % visual next data path and see if bad channels
    cfg          = [];
    cfg.method   = 'channel';
    cfg.ylim     = [-5000 5000];
    data_good_chan      = ft_rejectvisual(cfg, data);
    data_struct{i}.data_good_chan = data_good_chan;
    data_struct{i}.bad_chan_labels = setdiff(char(data_struct{i}.labels'), data_good_chan.label);

    % check if new bad_chans and append to list if so
    if i == 1
        daily_bad_channels = data_struct{i}.bad_chan_labels;
    elseif size(setdiff(char(data_struct{i}.bad_chan_labels), daily_bad_channels),1) ~= 0
        new_bads = setdiff(char(data_struct{i}.bad_chan_labels), daily_bad_channels);
        if size(new_bads,2) > 0 && size(new_bads{1},1)
            for k = 1:size(new_bads, 1)
                if size(daily_bad_channels,1) == 1
                    daily_bad_channels = [daily_bad_channels; new_bads{k}];
                else
                    daily_bad_channels{end+1} = new_bads{k};
                end
            end
            reset_bad_chan = true;
        end
    end
end


%% Check if we need to change bad channels for the other recordings (ie channels were selected as bad in later recordings for the day)
if reset_bad_chan
    % loop through all paths in log file
    for i = 1:size(log_data.paths)
        % select channels
        chans_to_select = {'all'};
        for j = 1:size(daily_bad_channels, 1)
            chans_to_select{end+1} = ['-', daily_bad_channels{j}];
        end

        cfg = [];
        cfg.channel = ft_channelselection(chans_to_select, data_struct{i}.data_good_chan);
        data_struct{i}.data_good_chan = ft_selectdata(cfg, data_struct{i}.data_good_chan);

        data_struct{i}.bad_chan_labels = daily_bad_channels;
    end
end

%% re-ref and filter

cutoff_freq = 40; %%%%%%%% Make this changeable?
[b,a] = butter(2, cutoff_freq / (data_struct{i}.sample_rate / 2));

for i = 1:size(log_data.paths)
    label = {};
    trial = [];
    cur_index = 1;
    for ILcomb = 1:2:8 % possibly 4 bipolar IL channels;
        if ~ismember(['IL', num2str(ILcomb)], data_struct{i}.bad_chan_labels) && ~ismember(['IL', num2str(ILcomb+1)], data_struct{i}.bad_chan_labels)
            if ILcomb==1 % skip IL1 because reref for ch1 occurs in OE signal chain
                temp_data = data_struct{i}.data_good_chan.trial{1};
                new_data = temp_data(ismember(data_struct{i}.data_good_chan.label, ['IL', num2str(ILcomb)])',:);
                filter_new_data = filtfilt(b,a, new_data);
                label{cur_index} = ['IL', num2str(ILcomb),'-','IL',num2str(ILcomb+1)];
                trial{cur_index}= filter_new_data;
                if dofilt==0
                    trial{cur_index}=new_data;
                end
                cur_index = cur_index + 1;

            else
                temp_data = data_struct{i}.data_good_chan.trial{1};
                new_data = temp_data(ismember(data_struct{i}.data_good_chan.label, ['IL', num2str(ILcomb)])',:) - temp_data(ismember(data_struct{i}.data_good_chan.label, ['IL', num2str(ILcomb+1)])',:);
                filter_new_data = filtfilt(b,a, new_data);
                label{cur_index} = ['IL', num2str(ILcomb),'-','IL',num2str(ILcomb+1)];
                trial{cur_index}= filter_new_data;
                if dofilt==0
                    trial{cur_index}=new_data;
                end
                cur_index = cur_index + 1;
            end
        end
    end

    for BLAcomb = 1:2:8 % possibly 4 bipolar BLA channels
        if ~ismember(['BLA', num2str(BLAcomb)], data_struct{i}.bad_chan_labels) && ~ismember(['BLA', num2str(BLAcomb+1)], data_struct{i}.bad_chan_labels)
            temp_data = data_struct{i}.data_good_chan.trial{1};
            new_data = temp_data(ismember(data_struct{i}.data_good_chan.label, ['BLA', num2str(BLAcomb)])',:) - temp_data(ismember(data_struct{i}.data_good_chan.label, ['BLA', num2str(BLAcomb+1)])',:);
            filter_new_data = filtfilt(b,a, new_data);
            label{cur_index} = ['BLA', num2str(BLAcomb),'-','BLA',num2str(BLAcomb+1)];
            trial{cur_index} = filter_new_data;
            if dofilt==0
                trial{cur_index}=new_data;
            end
            cur_index = cur_index + 1;
        end
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

    data_struct{i}.clean_filt_data = data;

    % get cur path
    cur_path = strtrim(log_data.paths(i,:)); % paths save with whitespace, strtrim makes words looks nice
    % overwrite corresponding data mat
    if ispc
        folder_split = split(logfile_folder, '\');
    else
        folder_split = split(logfile_folder, '/');
    end
    cur_data=data_struct{i};
    save([logfile_folder, '/', cur_path, '_', char(folder_split(end-2)), '_', char(folder_split(end-1)), '_cleandata_struct.mat'], 'cur_data');
end

end