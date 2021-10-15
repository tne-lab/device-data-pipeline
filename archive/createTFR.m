function createTFR(file, path)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Mark Schaza @ TNEL 2020
% Function that is given a file and path and creates the TFR
% for the data. Note that whatever processor is selected in the file will
% be used for the TFR for channels 1-16 (eventually will be added as an
% input arg for scalability).
%
% Inputs
%   - file: contains the processorID to get looked at
%   - path: folder that file is located in

% Returns
%   - Void: TFR files are created in the folder with the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load data from the disk and format into fieldtrip compatible structure.
if isstring(file)
    file = char(file);
    path = char(path);
end

if ~(isfile([path,'time_data.mat']))
    data.trial={};
    data.label={};
    data.time={};
    cfg=struct;

    chans = 16;
    rawdata = cell(1, chans);

    procID = file(1:3);
    for i=1:chans
        % from Rhythm FPGA plugin:
        [rawdata{:,i}, timestamps] = load_open_ephys_data([path,procID,'_CH', num2str(i),'.continuous']);
    end
    rawdata = cell2mat(rawdata);
    data_len = size(rawdata, 1);


    %% re-reference channels, grouping them into pairs
    il_chans = 8;
    il_offset = 0;
    amyg_chans = 8;
    amyg_offset = 8;

    il_data = rawdata(:, il_offset + (1:2:il_chans)) - ...
        rawdata(:, il_offset + (2:2:il_chans));

    amyg_data = rawdata(:, amyg_offset + (1:2:amyg_chans)) - ...
        rawdata(:, amyg_offset + (2:2:amyg_chans));

    %% make Fieldtrip structs
    BLA_data = struct;
    IL_data = struct;

    % Labels
    BLA_data.label = arrayfun(@(i) sprintf('Amygdala%d', i), ...
        (1:size(amyg_data, 2))', 'uni', false);
    IL_data.label = arrayfun(@(i) sprintf('IL%d', i), ...
        (1:size(il_data, 2))', 'uni', false);

    % Time
    BLA_data.time = {timestamps'};
    IL_data.time = {timestamps'};

    % Data
    BLA_data.trial = {amyg_data'};
    IL_data.trial = {il_data'};

    % Sampling Rate
    BLA_data.fsample = 30000;
    IL_data.fsample = 30000;

    %%
    cfg=[];
    cfg.length=8; %7; % seconds.

    BLA_data_redefine= ft_redefinetrial(cfg,BLA_data);
    IL_data_redefine= ft_redefinetrial(cfg,IL_data);

    %% Redefine time?

    Fs = IL_data.fsample;
    len = length(IL_data_redefine.time{1});

    for j=1:length(IL_data_redefine.time)
        IL_data_redefine.time{j} = (0:len-1) / Fs;
        BLA_data_redefine.time{j} = (0:len-1) / Fs;
    end


    %%
    cfg=[];
    cfg.keepsampleinfo = 'yes';
    time_data=ft_appenddata(cfg,IL_data_redefine,BLA_data_redefine);

    %% single parameter set
    cfg=[];
    cfg=ft_databrowser(cfg,time_data);  
    time_data=ft_rejectartifact(cfg,time_data); 

    %%
    save([path,'time_data.mat'],'time_data','-v7.3');
else
    time_data_mat = load([path,'time_data.mat']);
    time_data = time_data_mat.time_data;
end

%% Time-Frequency Analysis
cfg=[];  
cfg.foi=0.5:0.5:30;   
cfg.taper='hanning';
cfg.output=('powandcsd');
% cfg.channelcmb = { 'IL*', 'Amygdala*' }; % Whats the difference here???
cfg.channelcmb = {'Amygdala*' , 'IL*'};

cfg.method='mtmconvol';
cfg.t_ftimwin=ones(length(cfg.foi),1)*0.5;
cfg.pad = 8; % 1 / (total data length) must divide the frequency step evenly

cfg.keeptrials='yes'; 

cfg.toi = 0.25:0.01:6.74;

TFR=ft_freqanalysis(cfg,time_data);

%% Save the Time Frequency Analysis results 
TFR_1=TFR;  
% TFR=TFR_BLA;  
save ([path, 'TFR.mat'],'TFR_1','-v7.3');

end
