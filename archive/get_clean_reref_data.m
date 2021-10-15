function rat = get_clean_reref_data(rat, ind, nday, ntime, field_str)
%REVISION HISTORY -
%This version is modified for the NeuroDevice R01 Project, 2021.
%VERSION from Eric Song, 8/25: 
% clean_data = get_clean_data_no_behav_automatic_ES(data,timestamps)
%VERSION from TNE Lab: clean_data = get_clean_data(file,path)



%% Bookeeping

if strcmpi(field_str, 'clean_data_lfp_car') % for car rereferenced dataset
    %have to make these be in trial format for redefinetrial to work!
    data.trial = {rat(ind).day(nday).timepoint(ntime).time_lfp_car};
    data.label = rat(ind).day(nday).timepoint(ntime).labels_car;
    data.time =  {rat(ind).day(nday).timepoint(ntime).clean_data_time};
    data.fsample =  rat(ind).day(nday).timepoint(ntime).clean_data_lfp.fsample;
    
    struct_fieldname = 'car';
    
elseif strcmpi(field_str, 'clean_data_lfp_bipolar') % for bipolar rereferenced dataset
    %have to make these be in trial format for redefinetrial to work!
    data.trial = {rat(ind).day(nday).timepoint(ntime).time_lfp_bipolar};
    data.label = rat(ind).day(nday).timepoint(ntime).labels_bipolar;
    data.time =  {rat(ind).day(nday).timepoint(ntime).clean_data_time};
    data.fsample =  rat(ind).day(nday).timepoint(ntime).clean_data_lfp.fsample;
   
    
    struct_fieldname = 'bipolar';
    
end


%% Cut data into uniform segments
cfg = [];
cfg.length = 6; % 6 second segments
cfg.overlap = 0; % 0% percent overlap

data_segments = ft_redefinetrial(cfg, data);


%% Remove Artifacts _ automatic
cfg = [];
cfg.artfctdef.zvalue.channel = data_segments.label;
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

[cfg, ~] = ft_artifact_zvalue(cfg,data_segments);
clean_data = ft_rejectartifact(cfg,data_segments);  % reject artifacts


%% Save to rat structure

time_fieldname = ['clean_reref_', struct_fieldname, '_time'];
rat(ind).day(nday).timepoint(ntime).(time_fieldname) = clean_data.time;

data_fieldname = ['clean_reref_', struct_fieldname, '_datatrl'];
rat(ind).day(nday).timepoint(ntime).(data_fieldname) = clean_data.trial;
