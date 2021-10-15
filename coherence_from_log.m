function coherence_from_log()

% grab data file
[file, logfile_folder] = uigetfile; 

% get data from log file
log_data = load([logfile_folder, '\log_file.mat']);
%load(logfile_path);

% bad channels are saved across a single day
daily_bad_channels = [];
reset_bad_chan = false;

data_struct = {};
%% loop through all paths in log file to clean (load in data once)
for i = 1:size(log_data.paths)
    % get cur path
    cur_path = strtrim(log_data.paths(i,:)); % paths save with whitespace, strtrim makes words looks nice
    % find corresponding data mat
    folder_split = split(logfile_folder, '\');
    cur_data = load([logfile_folder, cur_path, '_', char(folder_split(end-2)), '_', char(folder_split(end-1)), '_TFR.mat']);
    data_struct{i} = cur_data.cur_data;
end

for i = 1:size(log_data.paths)
    % get cur path
    cur_path = strtrim(log_data.paths(i,:)); % paths save with whitespace, strtrim makes words looks nice
    
    % redefine trial chunks
    
    cohcfg = [];
    cohcfg.channelcmb = TFR.labelcmb;
    cohcfg.method = 'coh';
    coh = ft_connectivityanalysis(cohcfg, TFR);
    coh.cohspctrm = reshape(coh.cohspctrm, [1 16 60 650]);
    temp_coherence = coh.cohspctrm;
    
