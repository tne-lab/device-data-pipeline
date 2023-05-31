function [chunked_voltdata,artifacts]=DataRejection(cleaned_voltdata, params)

arguments
    cleaned_voltdata=[];
    params.chunksize=50;
    params.zthresh=1.5; % changes sensitivity of rejection. Higher = less sensitive.
    params.visual='no'; % see where the z-score cutoff is in the data
    params.trialpad=0; % adds padding around the trials in seconds
    params.artpad=0.1; % adds padding around the artifact in seconds
    params.filtpad=0; % adds padding around the filter for edge effects
    % For more definitions on what the paddings do, visit https://www.fieldtriptoolbox.org/tutorial/automatic_artifact_rejection/#padding
end

%% Chunking data;
cfg.length=params.chunksize; %in seconds

chunked_voltdata = ft_redefinetrial(cfg, cleaned_voltdata);

%% Detecting z-artifacts

cfg = [];
cfg.artfctdef.zvalue.cutoff = params.zthresh; % changes sensitivity of rejection. Higher = less sensitive.
cfg.artfctdef.zvalue.trlpadding = params.trialpad;
cfg.artfctdef.zvalue.artpadding = params.artpad;  % must be defined whether or not they're used; adds 0.01s of time padding around the artifact
cfg.artfctdef.zvalue.fltpadding = params.filtpad;

cfg.artfctdef.zvalue.cumulative = 'yes';  % filtering the data only for rejection purposes
cfg.artfctdef.zvalue.medianfilter = 'no';  % this is temporary. Original data integrity is maintained
cfg.artfctdef.zvalue.medianfiltord = 9;  % doesn't seem to have any effect (I think)
cfg.artfctdef.zvalue.absdiff = 'yes';
cfg.continuous = 'yes';
cfg.artfctdef.zvalue.channel = chunked_voltdata;
cfg.artfctdef.reject= 'nan';

cfg.artfctdef.zvalue.interactive = params.visual;  % visually gauge what the zscore cutoff should be
[~, artifacts] = ft_artifact_zvalue(cfg, chunked_voltdata);