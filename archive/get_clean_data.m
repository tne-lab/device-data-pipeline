function rat = get_clean_data(rat, ind, nday, ntime, field_str)
%REVISION HISTORY -
%This version is modified for the NeuroDevice R01 Project, 2021.
%VERSION from Eric Song, 8/25: 
% clean_data = get_clean_data_no_behav_automatic_ES(data,timestamps)
%VERSION from TNE Lab: clean_data = get_clean_data(file,path)



%% Bookeeping 

if strcmpi(field_str, 'bipolar') % for bipolar rereferenced dataset
    data_to_screen = 'time_lfp_bipolar'; 
    labels_to_screen = 'labels_bipolar'; 
    struct_fieldname = 'rejectTrials_bipolar';
    struct_dataname = 'clean_data_bipolar';

elseif strcmpi(field_str, 'car') % for car rereferenced dataset
    data_to_screen = 'time_lfp_car'; 
    labels_to_screen = 'labels_car';
    struct_fieldname = 'rejectTrials_car';
    struct_dataname = 'clean_data_car';
    
elseif contains(field_str, '_filt') % for filtered not-yet-rereferenced dataset
    data_to_screen ='time_lfp_lowres_filt';
    labels_to_screen = 'labels_filt';
    struct_fieldname = 'rejectTrials';
    struct_dataname = 'clean_data_lfp_filt';
    
elseif strcmpi(field_str, 'time_lfp_lowres') % for not filtered, not-yet-rereferenced dataset
    data_to_screen ='time_lfp_lowres';
    
    %call to chan_label_maker
    nchan = 16;
    rat = chan_label_maker(rat, ind, nday, ntime, nchan);

    labels_to_screen = 'labels_lowres';
    struct_fieldname = 'rejectTrials';
    struct_dataname = 'clean_data_lfp';
    
end

%% get data from rat structure, build Fieldtrip structure

% Fs = rat(ind).day(nday).timepoint(ntime).downsampled_rate;

data.trial = {rat(ind).day(nday).timepoint(ntime).(data_to_screen)(1:nchan,:)};
data.time = {rat(ind).day(nday).timepoint(ntime).timeline};
data.label = rat(ind).day(nday).timepoint(ntime).(labels_to_screen);



%% Cut data into uniform segments
cfg = [];
cfg.length = 6; % 6 second segments
cfg.overlap = 0; % 0% percent overlap

data_segments = ft_redefinetrial(cfg, data);

%% Remove bad channels
cfg          = [];
cfg.method   = 'channel';
cfg.ylim     = [-5000 5000];
messageBox = msgbox(['Rat ', num2str(ind), ', Day ', num2str(nday), ', Time = ', num2str(ntime)]);


data_good_chan      = ft_rejectvisual(cfg, data_segments);

%% Remove Artifacts _ automatic
cfg = [];
cfg.artfctdef.zvalue.channel = data_good_chan.label;
cfg.artfctdef.zvalue.cutoff = 30; % changes sensitivity of rejection. Higher = less sensitive
% Cutoff is currently the average standard deviation of all 8 channels
cfg.artfctdef.zvalue.trlpadding = 0;
cfg.artfctdef.zvalue.artpadding = 0;  % must be defined whether or not they're used
cfg.artfctdef.zvalue.fltpadding = 0;

cfg.artfctdef.zvalue.cumulative = 'yes';  % filtering the data only for rejection purposes
cfg.artfctdef.zvalue.medianfilter = 'no';  % this is temporary. Original data integrity is maintained
cfg.artfctdef.zvalue.medianfiltord = 9;  % doesn't seem to have any effect (I think)
cfg.artfctdef.zvalue.absdiff = 'yes';

% disp('Opening interactive menu. This may take a moment.')
cfg.artfctdef.zvalue.interactive = 'no';  % visually gauge what the zscore cutoff should be

[cfg, ~] = ft_artifact_zvalue(cfg,data_good_chan);
clean_data = ft_rejectartifact(cfg,data_good_chan);  % reject artifacts


%% save to rat structure
rat(ind).day(nday).timepoint(ntime).(struct_dataname) = clean_data;
rat(ind).day(nday).timepoint(ntime).labels_lowres = clean_data.label;



end
