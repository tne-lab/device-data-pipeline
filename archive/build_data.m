function rat = build_data(rat, ind, nday, ntime, nfile)
%This function does the *.binary to *.mat conversion of Open Ephys
%recordings.
% Key Assumptions for this script:
% 1. Assumes an a priori understanding of Recording Nodes (& their names) 
%    within the OEP signal chain used for recording.
% 2. Assumes data to be analyzed is located at "\experiment1\recording1\"
% 3. Assumes we are phase-locking to channel 1 

% Inputs:
% 1. Rat structure with all info about Open Ephys *.binary files to be
% converted for Matlab analysis 
% 2. Indices for batch processing according to specified rat, day, &
% testing timepoint.

% Outputs:
% 1. A memory-mapped object to the high-resolution data (sampled at 30 kHz) 
% is saved in the rat structure as a memmapfile object
% 2. An array of lower-resolution data (sampled at 1 kHz) and converted to
% voltages is saved in the rat structure under the fieldname
% "time_lfp_lowres".
%
%
% By V. Woods - Created on 6/30/2021
% Last updated: 8/12
%
% Changes to code:
% Version 8/12 - updated field names in rat structure, added error check to
% look that both Node 112's Timestamp & Data lengths when looking for the
% minimum length across both Recording Nodes.
% Version 6/30 - initial release


folderLocation = rat(ind).day(nday).path  ;
foldername = rat(ind).day(nday).timepoint(ntime).filename{nfile} ;


%% Get Headstage ch1 LFP data from Recording Node 111, ch 1.
pretext = 'Record Node 111\experiment1\recording1\'; 
filename = [folderLocation, foldername, '\', pretext];

% Create the memory-mapped object to all data at Recording Node 111
jsonFile = [filename,'structure.oebin'];
type = 'continuous'; %can be continuous, spikes, events
index = 1;
temp_obj1 = load_open_ephys_binary(jsonFile, type, index, 'mmap');

% get time-series LFP data on Ch1
time_lfp_Ch1 = temp_obj1.Data.Data.mapped(1,:);

% clear object from workspace
clear temp_obj1

%% Get Headstage ch1 LFP data from Recording Node 111, ch 1.
pretext = 'Record Node 112\experiment1\recording1\'; 
filename = [folderLocation, foldername, '\', pretext];

% Create the memory-mapped object to all data at Recording Node 111
jsonFile = [filename,'structure.oebin'];
type = 'continuous'; %can be continuous, spikes, events
index = 1;
temp_obj2 = load_open_ephys_binary(jsonFile, type, index, 'mmap');

% get time-series phase data on Ch1
time_phase_highres = temp_obj2.Data.Data.mapped(1,:);

% trim files from different Recording Nodes to same length of time, & check
% that the timestamp and Data fields have the same length; if not, take the
% shorter duration & trim all files to shortest duration.
t_steps_Node111 = numel(time_lfp_Ch1);
t_steps_Node112 = min(numel(temp_obj2.Timestamps), numel(time_phase_highres));

len_time = min(t_steps_Node111, t_steps_Node112);


%save phase data to disk
fileID = fopen([filename, 'time_phase_highres.dat'],'w');
fwrite(fileID, time_phase_highres(1:len_time),'double');
fclose(fileID);

%create a memory-mapped object to this disk location & store in rat struct
phase_obj = memmapfile([filename, 'time_phase_highres.dat'], 'Format', 'double', 'Writable', true );

rat(ind).day(nday).timepoint(ntime).mmap_phase_highres = phase_obj;

% create matrix with LFP data from both Recording Nodes
myData = double([time_lfp_Ch1(1:len_time); temp_obj2.Data.Data.mapped(2:end,1:len_time)]);
size_myData = size(myData);

%save high-resolution LFP data to disk
fileID = fopen([filename, 'time_lfp_highres.dat'],'w');
fwrite(fileID, myData, 'double');
fclose(fileID);

%create a memory-mapped object to this disk location & store in rat struct
lfp_obj = memmapfile([filename, 'time_lfp_highres.dat'], 'Format', {'double', size_myData, 'trimmed_data'}, 'Writable', true );

rat(ind).day(nday).timepoint(ntime).mmap_lfp_highres = lfp_obj;


%% Downsample LFP matrix and timeline
ds = 30; %downsample to 1kHz

% Explicitly go channel-by-channel 
temp = [];
for i = 1:size_myData(1)
    temp(i,:) = downsample(myData(i,:), ds); 
end

% downsample timestamps (be sure its length matches the trimmed length)
timeline = downsample(temp_obj2.Timestamps(1:len_time), ds);
timeline = timeline - timeline(1); %remove temporal offset

%% Get all other recording parameters or settings for this file & convert to voltage

% get & write sample_rate & downsampled rate
rat(ind).day(nday).timepoint(ntime).fsample = temp_obj2.Header.sample_rate;
rat(ind).day(nday).timepoint(ntime).downsampled_rate = temp_obj2.Header.sample_rate / ds; 

% get channel labels
rat(ind).day(nday).timepoint(ntime).chan_labels = {temp_obj2.Header.channels.channel_name};


% get info for the headstage channels
cHeadstage = 0;
for i = 1:temp_obj2.Header.num_channels
    if contains(temp_obj2.Header.channels(i).description, 'Headstage')
    cHeadstage = cHeadstage+1;
    end
end
rat(ind).day(nday).timepoint(ntime).headstage_nchan = cHeadstage;

% to ensure data is input-referred (see Intan chip manual for bit2voltage spec)
factor_headstage = temp_obj2.Header.channels(1).bit_volts;
rat(ind).day(nday).timepoint(ntime).headstage_bit2uV = factor_headstage;

% Convert headstage channels to microvolts
myData_volts(1:cHeadstage,:) = myData(1:cHeadstage,:).*factor_headstage; %in uV




% if there are ADC channels
cADC = 0;
if temp_obj2.Header.num_channels > cHeadstage
    
    for i = 1:temp_obj2.Header.num_channels
        if contains(temp_obj2.Header.channels(i).description, 'ADC')
            cADC = cADC+1;
        end
    end
    rat(ind).day(nday).timepoint(ntime).ADC_nchan = cADC;
    
    
    % to ensure data is input-referred (see Intan chip manual for bit2voltage spec)
    factor_ADC = temp_obj2.Header.channels(end).bit_volts;
    rat(ind).day(nday).timepoint(ntime).ADC_bit2uV = factor_ADC;
    
    % convert ADC channels to volts
    myData_volts(cHeadstage+1:cHeadstage+cADC,:) = myData(cHeadstage+1:end,:).*factor_ADC; %in volts

end


%% Save to disk & write memory-mapped object to rat struct


% convert downsampled Time to seconds & save to rat structure
rat(ind).day(nday).timepoint(ntime).timeline= (double(timeline)./temp_obj2.Header.sample_rate)';


%save high-resolution LFP data to disk
fileID = fopen([filename, 'time_lfp_uV_highres.dat'],'w');
fwrite(fileID, myData_volts, 'double');
fclose(fileID);

%create a memory-mapped object to this disk location & store in rat struct
lfp_obj = memmapfile([filename, 'time_lfp_uV_highres.dat'], 'Format', {'double', size_myData, 'trimmed_data'}, 'Writable', true );
rat(ind).day(nday).timepoint(ntime).mmap_lfp_highres = lfp_obj;


%% Add downsample LFP to rat struct
rat(ind).day(nday).timepoint(ntime).time_lfp_lowres = temp;



clear temp_obj2
