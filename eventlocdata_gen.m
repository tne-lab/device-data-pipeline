% This function outputs the event separated data for a closed loop
% recording. It requires the time series to have been run through
% create_ds_data_CL and clean_timeseries_CL (in that order). The output
% event_sep_data is a fieldtrip structure that has the trial information
% for the event separated data.

% This code is probably pretty buggy still

% By Heather Breidenbach
% Last updated: 11/11/2022

pretime=1; % Number of seconds you want included in the trial before the event
posttime=2; % Number of seconds you want included in the trial after the event

reload=1; % If the data hasn't been loaded in yet, if you have already once this can be 0
disconts=1; % if there are discontinuities in the sample, keep this on



Filetype="CLOSED"; % If closed do "CLOSED"
cur_path="CLOSED_LOOP"; % If closed do "CLOSED_LOOP"

if reload==1
    file='Z:\projmon\virginia-dev\01_EPHYSDATA\dev2218\day2_180stim';
    first= 'Z:\projmon\virginia-dev\01_EPHYSDATA\dev2218\day2_180stim\CLOSED_LOOP_2022-10-21_14-11-22\'; % Change this for CLOSED_LOOP_Pre if desired to run
    loc = [first, 'Record Node 104\experiment1\recording1\structure.oebin'];
    if file==0
        disp('No file specified. Please select the desired log file.')
        [~, logfile_folder] = uigetfile;
    else
        logfile_folder=file;
    end
    % get data from log file
    log_data = load([logfile_folder, '/log_file.mat']);
    %load(logfile_path);

    % bad channels are saved across a single day
    daily_bad_channels = [];
    reset_bad_chan = false;


    % read-in only the pre- & post- Raw files.
    tmp = cellstr(log_data.paths);
    log_data.paths = char(tmp(cellfun(@(x) or(contains(x,Filetype), contains(x, lower(Filetype))),tmp)));


    data_struct = {};
    %% loop through all paths in log file to clean (load in data once)
    for i = 2:size(log_data.paths) % this loops through log file paths, 1st one is the CL_Pre and 2nd is CL
        % get cur path
        cur_path = strtrim(log_data.paths(i,:)); % paths save with whitespace, strtrim makes words looks nice
        % find corresponding data mat
        if ispc
            folder_split = split(logfile_folder, '\');
        else
            folder_split = split(logfile_folder, '/');
        end
        try
            cur_data = load([logfile_folder,'\' cur_path, '_', char(folder_split(end-2)), '_', char(folder_split(end-1)), '_cleandata_struct.mat']);
        catch
            cur_data = load([logfile_folder,'\' cur_path, '_', char(folder_split(end-1)), '_', char(folder_split(end)), '_cleandata_struct.mat']);
        end
        data_struct{i} = cur_data.cur_data;
    end
    data=cur_data.cur_data.clean_filt_data;
    events=load_open_ephys_binary(loc, 'events', 2);
    eventdat=events.Timestamps;
    eventdat=round(eventdat./30);
    eventdat=eventdat-cur_data.cur_data.seconds(1)*1000;
    eventdat=eventdat(1:2:length(eventdat));
end
if disconts==1
    discont=[];
    diffamt=[];
    for i=1:length(data.time{1,1})-1
        if round(data.time{1,1}(i)+0.001,4)~=round(data.time{1,1}(i+1),4)
            discont=[discont,i];
            diffamt=[diffamt,round((data.time{1,1}(i+1)),3)-round(data.time{1,1}(i),3)];
        end
    end
    newdata=data;
    newdata.time{1,1}=[0:0.001:newdata.time{1,1}(end)];

    diffamt=diffamt-0.001;
    diffamt=round(diffamt./0.001);

    cutspots=[1,discont,length(data.trial{1,1})];
    cutamt=[0, diffamt, 0];
    newdata.trials={};
    for i=1:length(cutamt)-1
        newdata.trials{i}=newdata.trial{1,1}(:,[cutspots(i):cutspots(i+1)]);
        newdata.trials{i}=[newdata.trials{i},(nan(8,cutamt(i)))];

    end
    newdata.trial={cat(2,(newdata.trials{1,:}))};
    newdata.time{1,1}=[0:0.001:(length(newdata.trial{1,1})/1000)-0.001];
    %%
    cfg={}; cfg.method='pchip'; cfg.prewindow=5; cfg.postwindow=5; interpdat=ft_interpolatenan(cfg, newdata);
    sum(sum(isnan(interpdat.trial{1, 1})));
else
    interpdat=data;
end
%%


before_event=pretime*1000; %how many samples to include before event
after_event=posttime*1000; %how many samples to include after event

clear tridef
tribegin=eventdat-before_event;
triend=eventdat+after_event;
offset=ones(length(tribegin),1).*(pretime*1000);
tridef=[ tribegin triend offset];

cfg=[];
cfg.trl=tridef;
event_sep_data=ft_redefinetrial(cfg, interpdat );
