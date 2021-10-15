function rat = filter_func(rat, ind, nday, ntime,  filt_flag, field_str, fc)
%The purpose of this function is to filter the time-series LFP series. 
%Filters are reconfigurable; can cases for low-pass, high-pass, & bandpass
%INPUTS:
%
%data_in is specified in (field_str) 
%data_in can be 'high_res', 'low_res', '_bipolar', '_car' fields in rat
%structure. As of 8-12-2021, I've only tested this with 'low_res' data.
%
%OUTPUTS:
%The output is time-series saved in structure field: (field_str)_filt

% assumes half of channels are IL & half are BLA

%filt_flag has flags for 1-60Hz notch, 2-lowpass, 3-highpass, 4-bandpass
notch60Hz = filt_flag(1);
low_pass = filt_flag(2); 





%build input_data Fieldtrip strcuture
input_data.trial = rat(ind).day(nday).timepoint(ntime).(field_str);




%data_in = 'high_res', 'low_res', '_bipolar', '_car'
% OR 'clean_data_lfp_filt' or 'clean_data_lfp'
switch field_str
    
    case 'mmap_lfp_highres'
        disp('Captain, we have a problem. The code is written to trial data for this Test Case!')
        return
        
    case 'time_lfp_lowres'
        
        nchan = 16;
        input_data.trial = {rat(ind).day(nday).timepoint(ntime).(field_str)(1:nchan,:)};
        
        %create new channel labels for use with Fieldtrip
        % assumes half of channels are IL & half are BLA
        a = isfield(rat(ind).day(nday).timepoint(ntime), 'labels_lowres');
        
        if ~a
            %call to chan_label_maker
            rat = chan_label_maker(rat, ind, nday, ntime, nchan);
            
            
            rat(ind).day(nday).timepoint(ntime).labels_lowres = temp;
        elseif a
            input_data.label = rat(ind).day(nday).timepoint(ntime).labels_lowres;
        end
        
        input_data.time = {rat(ind).day(nday).timepoint(ntime).timeline};
    
    case 'clean_data_lfp'
        
        nchan = 16;
        input_data.trial = rat(ind).day(nday).timepoint(ntime).(field_str).trial;
        
        %create new channel labels for use with Fieldtrip
        % assumes half of channels are IL & half are BLA
        a = isfield(rat(ind).day(nday).timepoint(ntime), 'labels_lowres');
        
        if ~a
            %call to chan_label_maker
            rat = chan_label_maker(rat, ind, nday, ntime, nchan);
            
        end
        
        
        input_data.label = rat(ind).day(nday).timepoint(ntime).labels_lowres;
        
        
        
        
        input_data.time = rat(ind).day(nday).timepoint(ntime).(field_str).time;        
        
    case 'time_lfp_car'
        %As of 8/16/2021 - I have not tested this case
        input_data.trial = {rat(ind).day(nday).timepoint(ntime).(field_str)};
        input_data.label = rat(ind).day(nday).timepoint(ntime).labels_car;
        input_data.time = {rat(ind).day(nday).timepoint(ntime).timeline};
    case 'time_lfp_bipolar'
        %As of 8/16/2021 - I have not tested this case
        input_data.trial = {rat(ind).day(nday).timepoint(ntime).(field_str)};
        input_data.label = rat(ind).day(nday).timepoint(ntime).labels_bipolar;
        input_data.time = {rat(ind).day(nday).timepoint(ntime).timeline};
    otherwise
        warning('I am not sure which time-series has been sent for filtering. Please re-do function call.')
end

if notch60Hz %mains notch filter
    
    %get sample rate
    if contains(field_str, 'highres')
        input_data.fsample = rat(ind).day(nday).timepoint(ntime).fsample;
    else
        input_data.fsample = rat(ind).day(nday).timepoint(ntime).downsampled_rate;
    end
    
    %60Hz band-stop filter
    cfg = []; 
    cfg.bsfilter = 'yes';
    cfg.bsfreq = [58 62]; 
    input_data = ft_preprocessing(cfg, input_data);
    
    %120Hz band-stop filter
    cfg = []; 
    cfg.bsfilter = 'yes';
    cfg.bsfreq = [118 122]; 
    input_data = ft_preprocessing(cfg, input_data);
    
end


if low_pass %low-pass filter
    
    %get sample rate
    if contains(field_str, 'highres')
        input_data.fsample = rat(ind).day(nday).timepoint(ntime).fsample;
    else
        input_data.fsample = rat(ind).day(nday).timepoint(ntime).downsampled_rate;
    end
    
       
    
    %Call to low-pass filter
    cfg = [];
    cfg.lpfilter = 'yes';
    cfg.lpfreq = fc;
    output_data = ft_preprocessing(cfg, input_data);
    
    
end


%% save to rat structure
A = rat(ind).day(nday).timepoint(ntime).clean_data_lfp.time;
rat(ind).day(nday).timepoint(ntime).clean_data_time = cell2mat(A);

str = [field_str, '_filt'];
rat(ind).day(nday).timepoint(ntime).(str) = cell2mat(output_data.trial);





