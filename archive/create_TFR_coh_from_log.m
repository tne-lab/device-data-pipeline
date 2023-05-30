function create_TFR()
%testing
% grab data file
[file, logfile_folder] = uigetfile; 

% get data from log file
log_data = load([logfile_folder, '/log_file.mat']);
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
    if ispc
        folder_split = split(logfile_folder, '\');
    else
        folder_split = split(logfile_folder, '/');
    end
    cur_data = load([logfile_folder, cur_path, '_', char(folder_split(end-2)), '_', char(folder_split(end-1)), '_cleandata_struct.mat']);
    data_struct{i} = cur_data.cur_data;
end

for i = 1:size(log_data.paths)
    % get cur path
    cur_path = strtrim(log_data.paths(i,:)); % paths save with whitespace, strtrim makes words looks nice
%     %% Time-Frequency Analysis
% 
%     cfg=[];  
%     cfg.foi=0.5:0.5:30;   
%     cfg.taper='hanning';
%     cfg.output=('powandcsd');
%     cfg.channelcmb = {'BLA*' , 'IL*'};
% 
%     cfg.method='mtmconvol';
%     cfg.t_ftimwin=ones(length(cfg.foi),1)*0.5; % half a second sliding window
%     cfg.pad = 'nextpow2'; % 1 / (total data length) must divide the frequency step evenly
% 
%     cfg.keeptrials='yes'; 
% 
%     cur_time = data_struct{i}.clean_filt_data.time{1};
%     cfg.toi = 0.25:0.01:cur_time(end) - 0.25;
% 
%     TFR=ft_freqanalysis(cfg, data_struct{i}.clean_filt_data);
%     
% 
%     save([logfile_folder, cur_path, '_', char(folder_split(end-2)), '_', char(folder_split(end-1)), '_TFR.mat'], 'TFR');
    
    %% create coherence
    % Time-Frequency Analysis in chunks
    cfg=[];
    cfg.length=8;
    data_chunked = ft_redefinetrial(cfg, data_struct{i}.clean_filt_data);
    % find artifacts automatically and remove corresponding data from TFR
    cfg = [];
    cfg.artfctdef.zvalue.cutoff = 10; % changes sensitivity of rejection. Higher = less sensitive
    % Cutoff is currently the average standard deviation of all 8 channels
    cfg.artfctdef.zvalue.trlpadding = 0;
    cfg.artfctdef.zvalue.artpadding = 0;  % must be defined whether or not they're used
    cfg.artfctdef.zvalue.fltpadding = 0;

    cfg.artfctdef.zvalue.cumulative = 'yes';  % filtering the data only for rejection purposes
    cfg.artfctdef.zvalue.medianfilter = 'no';  % this is temporary. Original data integrity is maintained
    cfg.artfctdef.zvalue.medianfiltord = 9;  % doesn't seem to have any effect (I think)
    cfg.artfctdef.zvalue.absdiff = 'yes';
    cfg.continuous = 'yes';
    cfg.artfctdef.zvalue.channel = data_struct{i}.clean_filt_data.label;

    % disp('Opening interactive menu. This may take a moment.')
    cfg.artfctdef.zvalue.interactive = 'no';  % visually gauge what the zscore cutoff should be

    [cfg, ~] = ft_artifact_zvalue(cfg, data_struct{i}.clean_filt_data);
    clean_chunked_data = ft_rejectartifact(cfg, data_chunked);  % reject artifacts
    
    
    % START_HACK 
    % Must modify the timeline for TFR s/t it is from 0 to Segment length
    % (e.g., 8sec)
    ts =  clean_chunked_data.time{1} -  clean_chunked_data.time{1}(1,1);
    for j =1:length(clean_chunked_data.time)
        clean_chunked_data.time{1,j} = ts;
    end
    % END_HACK
    
    cfg=[];
    cfg.foi=0.5:0.5:30;
    cfg.taper='hanning';
    cfg.output=('powandcsd');
    cfg.channelcmb = {'BLA*' , 'IL*'};
    
    cfg.method='mtmconvol';
    cfg.t_ftimwin=ones(length(cfg.foi),1)*0.5; % half a second sliding window
    
    cfg.pad = 'nextpow2'; % 1 / (total data length) must divide the frequency step evenly
    
    cfg.keeptrials='yes';
    
    times2save = 0.25:0.01:8 - 0.25; % in s
    times2saveidx = dsearchn(ts', times2save'); %s
    
    
    cfg.toi = ts(times2saveidx);
    TFR_chunked=ft_freqanalysis(cfg, clean_chunked_data);
    
    %% calc coherence
    
    cohcfg = [];
    cohcfg.method = 'coh';
    coh = ft_connectivityanalysis(cohcfg, TFR_chunked);
    
    
    %% create excel files per recording file
    freq = coh.freq; %Hz
    powspctrm = squeeze(nanmean(nanmean(TFR_chunked.powspctrm, 4), 1)); %2D matrix chan x freq
    crsspctrm = squeeze(nanmean(nanmean(TFR_chunked.crsspctrm, 4), 1)); %2D matrix chan x freq
    coh_spect = nanmean(coh.cohspctrm, 3);  %2D matrix chan cmb x freq
    for j = 1:size(coh.labelcmb,1)
       cmb_labels{j,1} = [coh.labelcmb{j,2}, ' - ', coh.labelcmb{j,1}];
    end
    
    
    POW = [freq; powspctrm];
    LABELS = [{'Frequency (Hz)'}; clean_chunked_data.label]; chan_labels = clean_chunked_data.label;
    POW = table(LABELS, POW);
    
    CRSS = [freq; crsspctrm];
    LABELS = [{'Frequency (Hz)'}; cmb_labels];
    CRSS = table(LABELS, CRSS);
    
    COH = [freq; coh_spect];
    LABELS = [{'Frequency (Hz)'}; cmb_labels];
    COH = table(LABELS, COH);
    
    save([logfile_folder, cur_path, '_', char(folder_split(end-2)), '_', char(folder_split(end-1)), '_TFR.mat'], 'freq', 'chan_labels', 'cmb_labels', 'powspctrm', 'crsspctrm');
    save([logfile_folder, cur_path, '_', char(folder_split(end-2)), '_', char(folder_split(end-1)), '_coh.mat'], 'freq', 'cmb_labels', 'coh', 'coh_spect');
  
    %% COH file write
    
    fname = [logfile_folder, cur_path, '_', char(folder_split(end-2)), '_', char(folder_split(end-1)), '_TFR_coh.xls'];
    sheet_name = 'coh';
    writetable(COH, fname,'FileType','spreadsheet','Sheet', sheet_name, 'WriteVariableNames', 0)
    
    %% Power file write
    sheet_name = 'pow';
    writetable(POW, fname,'FileType','spreadsheet','Sheet', sheet_name, 'WriteVariableNames', 0)
    
end
end
