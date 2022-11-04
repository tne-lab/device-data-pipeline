%% Function information
% Code written by Heather Breidenbach
% Version 11/4/2022: Contains powplot/crsplot options
% Required : The logfile selected to run must have an associated
% _cleandata_struct with it, see cleandsgen.

% file should be the file path of the desired day to run. This path should
% include the log_file structure.  If file is not specified, will prompt the user to select from folders.

% toRun is a 1x3 vector that describes which of the pre, post, and closed
% files should be run for the given day. For example, toRun=[1,0,0] would
% specify to only run the RAW_PRE recording.

% TFRwin describes the size of the window being used during the TFR
% analysis. Larger windows will have less noise. The TFR window should not
% generally be smaller than ~1 second for our purposes.

% Chunksize determines the size of the chunks that the time series is split into.
% This number does not impact much of the analysis, but should be as
% large as possible given the data. Chunking improves processing time.

% tapsmofrq and toi define the fieldtrip settings used during
% ft_freqanalysis, the TFR processing. The defaults are defined below.


%% Function
function [cohfig, avthetaband,avtot]=mtmcoh(file, toRun, TFRwin, chunksize, tapsmofrq, toi,recalcTFR, PowPlot, CrsPlot)

arguments
    file = ''
    toRun = [1,1,0] % Default runs through RAW_PRE and RAW_POST
    TFRwin(1,1) {mustBeNumeric} = 2 % Default TFR window size is 2 seconds
    chunksize(1,1) {mustBeNumeric} = 100 % Chunks data for processing speed. Defaults into 100 second chunks.
    tapsmofrq(1,1) {mustBeNumeric} = 2 % Default taper smoothing of 2Hz
    toi = '50%' % Default time of interest looking at all of the time points, with time windows overlapping by 50%
    recalcTFR = 1 % 0 if TFR is already run, 1 if the script should run it again.
    PowPlot=0  % 0 if don't need the power plots output
    CrsPlot=0 % 0 if don't need the cross spectra output
end

%% Initializing variables

if strcmp(file, '')
    disp('No file specified. Please select the desired log file.')
    [~, logfile_folder] = uigetfile;
else
    if file(end)=='\'
        logfile_folder=file(1:end-1);
    else
        logfile_folder=file;
    end
end

if contains(logfile_folder, 'OB')
    toRunVect=["Pre_Raw","Post_0_Raw"];
else
    toRunVect=["RAW_PRE", "RAW_POST", "CLOSED"];
end
toRunVect=toRunVect(toRun==1);  % Selects only the recordings specified

log_data = load([logfile_folder, '/log_file.mat']);
tmp = cellstr(log_data.paths);

log_data.paths = char(tmp(cellfun(@(x) or(contains(x,toRunVect), contains(x, lower(toRunVect))),tmp)));


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
d=dir(file);
subfol={d.name};
subfol=subfol(contains(subfol,'cleandata'));
% [idx,tf]=listdlg('ListString', subfol);

if contains(logfile_folder, 'OB')
    idxlook=1:4;
else
    idxlook=4:8;
end

    if i==1 && (contains(subfol{1}(idxlook),'PRE') ||contains(subfol{1}(idxlook),'pre') )
        path=subfol{1};
    else
    if i==1 && (contains(subfol{2}(idxlook),'PRE') ||contains(subfol{2}(idxlook),'pre') )
        path=subfol(2);
    end
end
if i==2 && (contains(subfol{1}(idxlook),'POST') ||contains(subfol{1}(idxlook),'post') )
    path=subfol{1};
else
    if i==2 && (contains(subfol{2}(idxlook),'POST') ||contains(subfol{2}(idxlook),'post') )
        path=subfol(2);
    end
end
cur_data=load([logfile_folder,'/',char(path)]);
    data_struct{i} = cur_data.cur_data;
   
end

%% Chunk and run TFR


if recalcTFR==1
    for i = 1:size(log_data.paths)
        cur_path = strtrim(log_data.paths(i,:));
        cfg=[];
        cfg.showcallinfo='no';

        if chunksize*1000>size(data_struct{1, i}.clean_filt_data.trial{1,1}  ,2 )
            disp('Requested chunksize greater than data length. Automatically updating chunk size.')
            chunksize= size(data_struct{1, i}.clean_filt_data.trial{1,1} ,2 )/1000;
        end
        cfg.length=chunksize; %in seconds
        data_chunked = ft_redefinetrial(cfg, data_struct{i}.clean_filt_data);
        %
        cfg = [];
        cfg.artfctdef.zvalue.cutoff = 1.5; % changes sensitivity of rejection. Higher = less sensitive
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
        cfg.artfctdef.reject= 'nan';
%         % disp('Opening interactive menu. This may take a moment.')
%         cfg.artfctdef.zvalue.interactive = 'no';  % visually gauge what the zscore cutoff should be

        [cfg, ~] = ft_artifact_zvalue(cfg, data_struct{i}.clean_filt_data);
        clean_chunked_data = ft_rejectartifact(cfg, data_chunked);  % reject artifacts


        cfg=[];
        cfg.method='linear';
        cfg.prewindow=1;
        cfg.postwindow=1;
        cfg.feedback='text';
        for k=1:length(clean_chunked_data.trial)

            while ~isempty(find(isnan(clean_chunked_data.trial{1,k}), 1))==1
                clean_chunked_data=ft_interpolatenan(cfg,clean_chunked_data);
            end
        end
        %    clean_chunked_data=data_chunked;

        %Reset timeline from 0:end for all chunks, necessary for TFR
        ts =  clean_chunked_data.time{1} -  clean_chunked_data.time{1}(1,1);
        for j =1:length(clean_chunked_data.time)
            clean_chunked_data.time{1,j} = ts;
        end

        cfg=[];  % Set TFR config settings
        cfg.foi=0.5:0.5:30;
        cfg.taper='dpss';
        cfg.tapsmofrq=tapsmofrq;
        cfg.output=('powandcsd');
        cfg.channelcmb = {'BLA*'  'IL*'};
        cfg.method='mtmconvol';
        cfg.t_ftimwin=ones(length(cfg.foi),1)*TFRwin; % half a second sliding window
        cfg.pad = 'nextpow2';
        cfg.keeptrials='yes';

        cfg.toi=toi;
        TFR_chunked=ft_freqanalysis(cfg, clean_chunked_data);
        try
            save([logfile_folder, '\',char(data_struct{i}.label), '_', char(folder_split(end-1)), '_', char(folder_split(end)), '_TFR'], 'TFR_chunked')
        catch
            save([logfile_folder, '\',char(data_struct{i}.label), '_', char(folder_split(end-2)), '_', char(folder_split(end-1)), '_TFR'], 'TFR_chunked')
        end
    end
end
clear TFR_chunked
for i=1:size(log_data.paths)
    try
        TFR_chunked{i}=load([logfile_folder, '\',char(data_struct{i}.label), '_', char(folder_split(end-1)), '_', char(folder_split(end)), '_TFR'], 'TFR_chunked');
    catch

        TFR_chunked{i}=load([logfile_folder, '\',char(data_struct{i}.label), '_', char(folder_split(end-2)), '_', char(folder_split(end-1)), '_TFR'], 'TFR_chunked');
    end
end
%% Manual Coherence calculation and Plotting
cohfig=cell(1,size(toRunVect,2));
pow1fig=cell(1,size(toRunVect,2));
pow2fig=cell(1,size(toRunVect,2));
crsfig=cell(1,size(toRunVect,2));
if PowPlot+CrsPlot>0
    pow1=cell(1,16);
    pow2=cell(1,16);
    cross=cell(1,16);
end

for idx=1:length(toRunVect)
    Filetype=toRunVect(idx);
    chlabel=[{'BLA1-2/IL1-2';'BLA3-4/IL1-2';'BLA5-6/IL1-2';'BLA7-8/IL1-2';'BLA1-2/IL3-4';'BLA3-4/IL3-4';'BLA5-6/IL3-4';'BLA7-8/IL3-4';'BLA1-2/IL5-6';'BLA3-4/IL5-6';'BLA5-6/IL5-6';'BLA7-8/IL5-6';'BLA1-2/IL7-8';'BLA3-4/IL7-8';'BLA5-6/IL7-8';'BLA7-8/IL7-8'}]; %Manually labeling channel combs
    coh={};
    chpow1=[1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4];  % Draws the power spectrum of the desired combinations.
    chpow2=[1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4]+4;
    for i = 1:size(TFR_chunked{idx}.TFR_chunked.crsspctrm,1  )
       for chcmb=1:16
            if PowPlot+CrsPlot>0
            pow1{chcmb}=squeeze(TFR_chunked{idx}.TFR_chunked.powspctrm (i, chpow1(chcmb), :,:));
            pow2{chcmb}=squeeze(TFR_chunked{idx}.TFR_chunked.powspctrm (i, chpow2(chcmb), :,:));
            cross{chcmb}=squeeze(TFR_chunked{idx}.TFR_chunked.crsspctrm (i, (chcmb), :,:));
            coh.(Filetype).trial{i}.chcmb{chcmb}=((abs(cross{chcmb})).^2)./(pow1{chcmb}.*pow2{chcmb});  % Magnitude squared coherence
            else
                pow1=squeeze(TFR_chunked{idx}.TFR_chunked.powspctrm (i, chpow1(chcmb), :,:));
            pow2=squeeze(TFR_chunked{idx}.TFR_chunked.powspctrm (i, chpow2(chcmb), :,:));
            cross=squeeze(TFR_chunked{idx}.TFR_chunked.crsspctrm (i, (chcmb), :,:));
            coh.(Filetype).trial{i}.chcmb{chcmb}=((abs(cross)).^2)./(pow1.*pow2);  % Magnitude squared coherence
            end

        end
        try
            save([logfile_folder, '\',char(data_struct{idx}.label(1)), '_', char(folder_split(end-1)), '_', char(folder_split(end)), '_coh'], 'coh');
        catch
            save([logfile_folder, '\',char(data_struct{idx}.label), '_coh'], 'coh');
        end
    end

    ratname=char(folder_split(end-1));
    dayname=char(folder_split(end));

  topLine=['Multitaper Coh/time', Filetype];
    topPowLine=['Power Spect', Filetype];
    topCrsLine=['Cross Spectra', Filetype];
   
    botLine=[ratname, ' ', dayname];

    if PowPlot==1
        pow1fig{idx}=figure;
        for chanselect=1:4
            subplot(2,2,chanselect);
            surf( TFR_chunked{1, 1}.TFR_chunked.time, TFR_chunked{1, 1}.TFR_chunked.freq, pow1{chanselect});
            shading interp
            view(2)
            subtitle(TFR_chunked{1, 1}.TFR_chunked.label(chanselect))
            xlabel('Time (s)')
            ylabel('Freq (Hz)')
            colorbar;
            sgtitle([topPowLine,botLine], 'FontSize', 10, 'interpreter', 'none')
        end
        pow2fig{idx}=figure;
        for chanselect=1:4
            subplot(2,2,chanselect);
            surf(TFR_chunked{1, 1}.TFR_chunked.time,TFR_chunked{1, 1}.TFR_chunked.freq,  pow2{chanselect});
            view(2)
            shading interp
            subtitle(TFR_chunked{1, 1}.TFR_chunked.label(chanselect+4))
             xlabel('Time (s)')
            ylabel('Freq (Hz)')
            colorbar;
             sgtitle([topPowLine,botLine], 'FontSize', 10, 'interpreter', 'none')

        end
    else
        pow1fig{idx}=0;
    end
    if CrsPlot==1
        crsfig{idx}=figure;
        freq=TFR_chunked{idx}.TFR_chunked.freq;
        time=[];
        for chanselect=1:16
            subplot(4,4,chanselect);
            surf(TFR_chunked{1, 1}.TFR_chunked.time,TFR_chunked{1, 1}.TFR_chunked.freq,real(cross{chanselect}));
            view(2)
            shading interp
            xlabel('Time (s)')
            ylabel('Freq (Hz)')
            colorbar;
             sgtitle([topCrsLine,botLine], 'FontSize', 10, 'interpreter', 'none')
             subtitle(chlabel(chanselect),'FontSize', 8)

        end
    else
        pow1fig{idx}=0;
    end

    cohfig{idx}=figure;
    for chanselect=1:16
        plott=[];
        time=[];
        freq=TFR_chunked{idx}.TFR_chunked.freq;
        for i=1:length(coh.(Filetype).trial)
            plott=cat(2,plott,coh.(Filetype).trial{i}.chcmb{chanselect});
            time=[time, TFR_chunked{idx}.TFR_chunked.time+((i-1)*chunksize)];
        end

        subplot(4,4,chanselect);
        mesh(time, freq, plott)
        view(2)
        sgtitle([topLine,botLine], 'FontSize', 10, 'interpreter', 'none')
        subtitle(chlabel(chanselect),'FontSize', 8)
        yline(4,'w.-')
        yline(8,'w.-')
        colorbar;
        caxis([0 1])


        % caxis([0.3 0.9]);

        ind1=interp1(freq,1:length(freq),4,'nearest');
        ind2=interp1(freq,1:length(freq),8,'nearest');

        avtot.(Filetype).chan{chanselect}=squeeze(nanmean(plott));
        avthetaband.(Filetype).chan{chanselect}=squeeze(nanmean(plott([ind1:ind2],:)));


    end
    h = axes(cohfig{idx},'visible','off');
    h.XLabel.Visible = 'on';
    h.YLabel.Visible = 'on';
    c=colorbar(h, 'Position',[0.93 0.168 0.022 0.7]);
    xlabel(h,'Time (s)', 'FontWeight', 'bold')
    ylabel(h,'Freq(Hz)', 'FontWeight', 'bold')
end

