function rat = reref_data_ver4(rat, ind, nday, ntime, field_str, ref)
%The purpose of this file is to rereference time-series LFP data into either
%bipolar or common average referenced with an a priori brain region.
%This step removes the effect of volume conductor with single-ended
%recordings.
%Here, the code is hardcoded for ch 1-8 in IL, and ch9-16 in BLA.
%This uses some Fieldtrip functions.
%
%
%
%9/15 (ver3) - Removed the "random removal" of a bipolar pair; forced the bipolar
%pairing of: IL1-2 = "IL1", IL3-4 = "IL2", etc. Therefore, if 1 channel of
%the pair is bad, then discard the other - such that channel pairing will
%be uniform across days.
%8/30 - Add LUT to excel for bipolar channel re-mapping across days
%8/27 - Added check for when there are an odd number of channels for bipolar
% rereferencing that the same channel get disgard across all time-points
% for consistent comparisons within Day.
%8/24 - Version 2 has checks for removing "bad" channels, when passed "clean_data"


%INPUTS:
%Keep dynamic fieldname to account for both filtered data or non-filtered
%data as inputs
%data_in = 'high_res', 'low_res', '_bipolar', '_car', & their filtered vers
%OUTPUTS:
%Re-referenced time-series data


%% Reconfigure dataset into fieldtrip format


global saveLocation


switch field_str
    
    case 'mmap_lfp_highres'
        disp('Captain, we have a problem. The code is written to trial data for this Test Case!')
        return
        
    case 'time_lfp_lowres'
        
        nchan = 16;
        data.trial = {rat(ind).day(nday).timepoint(ntime).(field_str)(1:nchan,:)};
        
        
        %create new channel labels for use with Fieldtrip
        % assumes half of channels are IL & half are BLA
        a = isfield(rat(ind).day(nday).timepoint(ntime), 'labels_lowres');
        
        if ~a
            %call to chan_label_maker
            rat = chan_label_maker(rat, ind, nday, ntime, nchan);
            
        end
        
        data.label = rat(ind).day(nday).timepoint(ntime).labels_lowres;
        data.time = {rat(ind).day(nday).timepoint(ntime).timeline};
        
        
    case 'time_lfp_lowres_filt'
        
        nchan = 16;
        data.trial = {rat(ind).day(nday).timepoint(ntime).(field_str)(1:nchan,:)};
        
        %create new channel labels for use with Fieldtrip
        % assumes half of channels are IL & half are BLA
        a = isfield(rat(ind).day(nday).timepoint(ntime), 'labels_lowres');
        
        if ~a
            %call to chan_label_maker
            rat = chan_label_maker(rat, ind, nday, ntime, nchan);
            
        end
        
        data.label = rat(ind).day(nday).timepoint(ntime).labels_lowres;
        
        data.time = {rat(ind).day(nday).timepoint(ntime).timeline};
        
    case 'clean_data_lfp_filt'
        
        %this format has no trial info
        data.trial = rat(ind).day(nday).timepoint(ntime).(field_str);
        data.label = rat(ind).day(nday).timepoint(ntime).labels_lowres;
        data.time = rat(ind).day(nday).timepoint(ntime).clean_data_time;
        
          
    case 'time_lfp_car'
        data.trial = {rat(ind).day(nday).timepoint(ntime).(field_str)};
        data.label = rat(ind).day(nday).timepoint(ntime).labels_car;
        data.time = {rat(ind).day(nday).timepoint(ntime).timeline};
    case 'time_lfp_bipolar'
        data.trial = {rat(ind).day(nday).timepoint(ntime).(field_str)};
        data.label = rat(ind).day(nday).timepoint(ntime).labels_bipolar;
        data.time = {rat(ind).day(nday).timepoint(ntime).timeline};
    case 'time_lfp_car_filt'
        data.trial ={ rat(ind).day(nday).timepoint(ntime).(field_str)};
        data.label = rat(ind).day(nday).timepoint(ntime).labels_car;
        data.time = {rat(ind).day(nday).timepoint(ntime).timeline};
    case 'time_lfp_bipolar_filt'
        data.trial = {rat(ind).day(nday).timepoint(ntime).(field_str)};
        data.label = rat(ind).day(nday).timepoint(ntime).labels_bipolar;
        data.time = {rat(ind).day(nday).timepoint(ntime).timeline};
    otherwise
        warning('I am not sure which time-series has been sent for filtering. Please re-do function call.')
end




cfg = [];
cfg.channel = data.label; %{rat(ind).day(nday).timepoint(ntime).chan_labels{1:nchan}};
cfg.continuous = 'yes';
% cfg.keeptrials = 'yes';
cfg.blocksize = 10;
cfg.ylim = [-2000 2000]; %in uV
ft_databrowser(cfg, data)
grid on




%% This version has updates to remove the previously selected "bad" channels
switch ref
    case 'bipolar'
        %% Bipolar re-referencing
        %         bipolar_montage.labelold = {rat(ind).day(nday).timepoint(ntime).chan_labels{1:nchan}}';
        
        
        
        if or( strcmpi(field_str, 'clean_data_filt'), strcmpi(field_str, 'clean_data_lfp_filt'))
            
            bipolar_montage.labelold = rat(ind).day(nday).timepoint(ntime).labels_lowres';
            
 
                %This section implements the assumption that a channel's
                %function is categorically good or bad within a day.
                % So when we remove 1 channel for bipolar re-referencing
                % within a day at time =1, then for all other times we need
                % to omit the same channel. So save omitted IL channel &
                % omitted BLA channel to rat structure.
                
                % if odd number of IL channels
                
                n = cellfun(@(x) contains(x,'IL'), bipolar_montage.labelold, 'UniformOutput', 0);
                master_chans2plot_labels = getMaster_chans2plot_labels('not_applicable');
 % Commented out, 10/4 {                
%                 n = zeros(size(master_chans2plot_labels));
%                 for i = 1:size(bipolar_montage.labelold, 2)
%                     x = bipolar_montage.labelold(i);
%                     if contains(x,'IL')
%                         idxx = find(strcmpi(x,master_chans2plot_labels));
%                         n(idxx) = 1;
%                     end
%                 end
                    
%                 n = logical(n); %  } Commented out, 10/4
                n = cell2mat(n); %make a logical array
                
           
                
                nIL = sum(n);
                tmp_dataIL = [];
                if isequal(mod(nIL, 2), 1)
                    
                    if ~isfield(rat(ind).day(nday).timepoint(ntime), 'rmILchanidx')
                        %Knowing that the bipolar channel configuration is
                        %1-2, 3-4, etc.., identify which bipolar pair to
                        %remove from calculations. Log that channel in the
                        %rat_struct field.
                        
                        
                        %compare the "screened" or channel that was removed 
                        %by user against master_chan_labels 
                        master_chans2plot_labels = getMaster_chans2plot_labels('not_applicable');
                        screenedCHAN = setdiff(master_chans2plot_labels(1:8),  bipolar_montage.labelold(n));
                        screenedCHANidx = str2num(cell2mat((cellfun(@(x) regexp(x,'\d*','Match'), screenedCHAN))));
                         
                        idx = bipolar_LUT(screenedCHANidx);
%                         %odd number of IL channels, then remove one of them at random
%                         idx = randperm(nIL,1); %pick a random entry

                        %write to rat structure
                        rat(ind).day(nday).timepoint(ntime).rmILchanidx = idx;
                        
                    elseif isfield(rat(ind).day(nday).timepoint(ntime), 'rmILchanidx')
                        
                         if isempty(rat(ind).day(nday).timepoint(ntime).rmILchanidx)
                            %get entry from rat structure at previous
                            %time-point
                            idx = rat(ind).day(nday).timepoint(ntime-1).rmILchanidx ;
                            
                            %also write this value to current time-point
                            rat(ind).day(nday).timepoint(ntime).rmILchanidx = idx;
                        end
                    end
                    
                    n(idx) = 0; %remove one IL channel to make even number of channels
                
                nIL = nIL -1;
                end
                %update trial info
                    if strcmpi(field_str, 'clean_data_filt')
                        tmp_dataIL = data.trial{1}(n,:);
                    elseif strcmpi(field_str, 'clean_data_lfp_filt')
                        tmp_dataIL = data.trial(n,:);
                    end
                    
                
                
                
                % if odd number of BLA channels
                 master_chans2plot_labels = getMaster_chans2plot_labels('not_applicable');
% { Commented out, 10/4
%                 m = zeros(size(master_chans2plot_labels));
%                 for i = 1:size(bipolar_montage.labelold, 2)
%                     x = bipolar_montage.labelold(i);
%                     if contains(x,'BLA')
%                         idxx = find(strcmpi(x,master_chans2plot_labels));
%                         m(idxx) = 1;
%                     end
%                 end
%                                 m = logical(m);
% % } Commented out, 10/4

m = cellfun(@(x) contains(x,'BLA'), bipolar_montage.labelold, 'UniformOutput', 0);
                                m = cell2mat(m); %make a logical array, 15 x1
                mBLA = sum(m); 
                            
                tmp_dataBLA = [];
                if isequal(mod(mBLA, 2), 1)
                    
                    if ~isfield(rat(ind).day(nday).timepoint(ntime), 'rmBLAchanidx')
                        
                        %Knowing that the bipolar channel configuration is
                        %1-2, 3-4, etc.., identify which bipolar pair to
                        %remove from calculations. Log that channel in the
                        %rat_struct field.
                        
%                          m = cellfun(@(x) contains(x,'BLA'), bipolar_montage.labelold, 'UniformOutput', 0);
%                                 m = cell2mat(m); %make a logical array
%                       mBLA = sum(m);
                        %compare against master_chan_labels:
                        master_chans2plot_labels = getMaster_chans2plot_labels('not_applicable');
                        
                        screenedCHAN = setdiff(master_chans2plot_labels(9:16),  bipolar_montage.labelold(m));
                        [C , IA, IB] =  intersect( bipolar_montage.labelold(m), master_chans2plot_labels(9:16));
                        clear m
                        m(8+IB,1) = ones(size(IB)); %note that this is 16x1 now, for stupid labels
                        m = logical(m); 
                        
                        
%                       screenedCHAN = setdiff(master_chans2plot_labels(9:16),  bipolar_montage.labelold(m)); %channel to remove
                        screenedCHANidx = str2num(cell2mat((cellfun(@(x) regexp(x,'\d*','Match'), screenedCHAN)))); %index of chan 2 remove
                         
                        idx = bipolar_LUT(screenedCHANidx); %index of bipolar pair to remove
  
                         
%                         %odd number of BLA channels, then remove one of them at random
%                         idx = randperm(mBLA,1); %pick a random entry
                        

                        %write to rat structure
                        rat(ind).day(nday).timepoint(ntime).rmBLAchanidx = idx;
                        
                    elseif isfield(rat(ind).day(nday).timepoint(ntime), 'rmBLAchanidx')
                        
                        m = cellfun(@(x) contains(x,'BLA'), bipolar_montage.labelold, 'UniformOutput', 0);
                        m = cell2mat(m); %make a logical array, 
                        mBLA = sum(m);

                       
                        if isempty(rat(ind).day(nday).timepoint(ntime).rmBLAchanidx)
                            %get entry from rat structure at previous
                            %time-point
                            idx = rat(ind).day(nday).timepoint(ntime-1).rmBLAchanidx ;
                            
                            %write to rat structure at current time-point
                            rat(ind).day(nday).timepoint(ntime).rmBLAchanidx = idx;
                            
                            
                        end
                        
                        m(nIL +idx) = 0; %is this 15x1 or 16x1, & why?
                    end
                    
%                     COMMENT { 10/4 -
%                     tmp(nIL + idx) = 0; %remove one BLA channel to make even number of channels
%                     tmp(nIL + screenedCHANidx) = 0;
%                     tmp(nIL+Ind_2keep) = 1;
%                     m = logical(tmp);
                    % } COMMENT, 10/4
%                     tmp(nIL + screenedCHANidx)
                  
                    
                    
                    mBLA = mBLA -1;
                end
                
                
                
                %update trial info
                if strcmpi(field_str, 'clean_data_filt')
%                     tmp_dataBLA = data.trial{1}(m,:);
                elseif strcmpi(field_str, 'clean_data_lfp_filt')
                    %this is a hack, 10/5
                    if numel(m) == 15
                        tmp_dataBLA = data.trial(m,:);
                        
                        data.label =  data.label(or(n,m));
                    elseif numel(m) == 16
                        
                        if ~and(isequal(nIL,8), isequal(mBLA,8)) %if 1 ch was removed
                            tmp_m = m;
                            tmp_m(idx+nIL) =[];
                            tmp_dataBLA = data.trial(tmp_m,:);
                            data.label =  data.label(or(n',tmp_m));
                        else
                            tmp_dataBLA = data.trial(m,:);
                            
                            data.label =  data.label(or(n,m));
                        end
                    end
                    
                end
                
                
                
                %Remove appropriate channels, update & create new labels
                a = isfield(rat(ind).day(nday).timepoint(ntime), 'rmILchanidx'); % = 1, if removed channels; =0, if no changes
                b = isfield(rat(ind).day(nday).timepoint(ntime), 'rmBLAchanidx');
                
%                 a = ~isempty(tmp_dataIL);  % = 1, if removed channels; =0, if no changes
%                 b = ~isempty(tmp_dataBLA);
                
                if and(a, ~b)
                    
                    if strcmpi(field_str, 'clean_data_lfp_filt')
                        %keep subset of IL data (with channel removed), add BLA data
                        data.trial = [tmp_dataIL; data.trial(m,:)];
                        
                    elseif strcmpi(field_str, 'clean_data_filt')
                        %keep subset of IL data (with channel removed), add BLA data
                        data.trial{1} = [tmp_dataIL; data.trial{1}(m,:)];
                    end
                    
                    
                elseif and(~a, b)
                    
                    if strcmpi(field_str, 'clean_data_lfp_filt')
                        %add all IL data, add subset of BLA data (with channel removed)
                        data.trial = [data.trial(n,:); tmp_dataBLA];
                        
                    elseif strcmpi(field_str, 'clean_data_filt')
                        %add all IL data, add subset of BLA data (with channel removed)
                        data.trial{1} = [data.trial{1}(n,:); tmp_dataBLA];
                        
                    end
                    
                    
                elseif and(a, b)
                    
                    if strcmpi(field_str, 'clean_data_lfp_filt')
                        %keep subset of IL & BLA data (with channels removed)
                        data.trial = [tmp_dataIL; tmp_dataBLA];
                        
                    elseif strcmpi(field_str, 'clean_data_filt')
                        %keep subset of IL & BLA data (with channels removed)
                        data.trial{1} = [tmp_dataIL; tmp_dataBLA];
                        
                    end
                    
                elseif and(~a,~b)
                    
                    %We did not remove any channels, so make no changes here!
                    
                end
                
                
                
                %%       update & create new labels
                %update to "old" labels to disregard the removed channel label
                
                rat_struct = rat(ind).day(nday).timepoint(ntime);
                newlabels = get_bipolar_label_generator_LUT(rat_struct, n, m);
                
                
%                data.label =  data.label(or(n',tmp_m));
                
                
%                 data.label = data.label(or(n,m)); 
%                 for i = 1:(nIL/2)
%                     newlabels{i} = ['IL ', num2str(i)];
%                 end
%                 
%                 for i = 1:(mBLA/2)
%                     newlabels{end+1} = ['BLA ', num2str(i)];
%                 end
                
                
                
                bipolar_montage.labelnew  = newlabels';
                
           
        end
        
        %         bipolar_montage.labelnew  = {'IL 1', 'IL 2', 'IL 3', 'IL 4', 'BLA 1', 'BLA 2', 'BLA 3', 'BLA 4'}';
        %         bipolar_montage.tra       = [
        %             1,-1, 0,0,0,0,0,0,0,0,0,0,0,0,0,0;
        %             0,0,1,-1,0,0,0,0,0,0,0,0,0,0,0,0;
        %             0,0,0,0,1,-1,0,0,0,0,0,0,0,0,0,0;
        %             0,0,0,0,0,0,1,-1,0,0,0,0,0,0,0,0;
        %             0,0,0,0,0,0,0,0,1,-1,0,0,0,0,0,0;
        %             0,0,0,0,0,0,0,0,0,0,1,-1,0,0,0,0;
        %             0,0,0,0,0,0,0,0,0,0,0,0,1,-1,0,0;
        %             0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,-1 ];
        
        
        
        %% Use of montage pattern should work but doesn't!
        cfg = [];
        cfg.channel = 'all'; % this is the default
        cfg.reref = 'yes'; % 'no', use the cfg.montage option instead
        %         cfg.montage = bipolar_montage;
        %          cfg.continuous = 'yes';
        
        
        cfg.refmethod     = 'bipolar'; %could remove if montage worked!
        cfg.refchannel = 'all'; %could remove if montage worked!
        data_bipolar = ft_preprocessing(cfg,data);
        
        
        if strcmpi(field_str, 'clean_data_lfp_filt')
            tmp.trial = data_bipolar.avg(1:2:end,:);
            tmp.label = data_bipolar.label(1:2:end);
            tmp.time = data_bipolar.time;
            
        elseif strcmpi(field_str, 'clean_data_filt')
            tmp.trial = data_bipolar.trial{1}(1:2:end,:);
            tmp.label = {data_bipolar.label{1:2:end, :}};
            tmp.time = data_bipolar.time{1};
            
        end
        
        %write Bipolar channel mapping to Excel (1 sheet per timepoint)
        rat_name = rat(ind).id;
        fname = [saveLocation, rat_name, '_prelim_data_bipolar_LUT.xls'];
        sheet_name = ['Day', num2str(nday), '_', rat(ind).day(nday).timepoint(ntime).name(1:4)];
        
        %Make sure labels are Nx1 cell array
        if size(data.label,1) < size(data.label,2) %if row vector, then transpose
            original_channels = data.label'; %update to "old" labels
        elseif size(data.label,1) > size(data.label,2)
            original_channels =data.label;
        end
        writecell({'Original channels'},  fname ,'FileType','spreadsheet','Sheet', sheet_name,'Range', 'A1')
        writecell(original_channels,  fname ,'FileType','spreadsheet','Sheet', sheet_name,'Range', 'A2')
        
        
        bipolar_channels = tmp.label;
        writecell({'Bipolar channels'}, fname ,'FileType','spreadsheet','Sheet', sheet_name, 'Range', 'B1')
        writecell( bipolar_channels, fname ,'FileType','spreadsheet','Sheet', sheet_name, 'Range', 'B2')
        
        if size(newlabels,1) < size(newlabels,2) %if row vector, then transpose
            new_channels = newlabels'; %update to "old" labels
        elseif size(newlabels,1) > size(newlabels,2)
            new_channels = newlabels;
        end
        writecell( {'New channels'}, fname ,'FileType','spreadsheet','Sheet', sheet_name, 'Range', 'C1')
        writecell( new_channels, fname ,'FileType','spreadsheet','Sheet', sheet_name, 'Range', 'C2')
        
        rat(ind).day(nday).timepoint(ntime).labels_bipolar = new_channels;
        
        % view bipolar-referenced output
        cfg = [];
        cfg.continuous = 'yes';
        cfg.blocksize = 10;
        cfg.ylim = [-2000 2000]; %in uV
        ft_databrowser(cfg, tmp)
        grid on
        
        %save bipolar re-referenced data to rat structure
        rat(ind).day(nday).timepoint(ntime).time_lfp_bipolar = tmp.trial; %cell2mat(data_bipolar.trial);
        
        
    case 'CAR by region'
        %% Common avg reference within a brain region
        
        % Commented out Version 1 dataset
        %         % IL data
        %         dataIL = rat(ind).day(nday).timepoint(ntime).(field_str)(1:(nchan/2),:); %each row is a channel
        %         ILmean = mean(dataIL);
        %         temp_dataIL = dataIL - ILmean;
        %
        %         % BLA data
        %         dataBLA = rat(ind).day(nday).timepoint(ntime).(field_str)((nchan/2)+1:nchan,:); %each row is a channel
        %         BLAmean = mean(dataBLA);
        %         temp_dataBLA = dataBLA - BLAmean;
        %
        %         %create new channel labels for use with Fieldtrip
        %         for i = 1:16
        %             if i<=8
        %                 temp{i} = ['IL ', num2str(i)];
        %             elseif i>8
        %                 temp{i} = ['BLA ', num2str(i-8)];
        %             end
        %         end
        %         rat(ind).day(nday).timepoint(ntime).labels_car = temp;
        
        
        
        if or( strcmpi(field_str, 'clean_data_filt'), strcmpi(field_str, 'clean_data_lfp_filt'))
            % here, we will work with Brain Region #1 (the IL) & then we will work with
            % Brain Region #2 (the BLA)
            % For each region, compute the mean & subtract it out from all channels in
            % the region.
            
            
            %% IL
            if strcmpi(field_str, 'clean_data_filt')
                n = cellfun(@(x) contains(x,'IL'), data.label,  'UniformOutput', 0); %these are the IL channels
                n = cell2mat(n)'; %make a logical array
                ILmean = mean(data.trial{1}(n, :), 1);
                temp_dataIL = data.trial{1}(n,:) - ILmean;
            elseif strcmpi(field_str, 'clean_data_lfp_filt')
                n = cellfun(@(x) contains(x,'IL'), data.label,  'UniformOutput', 0); %these are the IL channels
                n = cell2mat(n)'; %make a logical array
                ILmean = mean(data.trial(n, :), 1);
                temp_dataIL = data.trial(n,:) - ILmean;

            end
            
            %% BLA
            if strcmpi(field_str, 'clean_data_filt')
                m = cellfun(@(x) contains(x,'BLA'), data.label, 'UniformOutput', 0); %these are the BLA channels
                m = cell2mat(m)'; %make a logical array
                BLAmean = mean(data.trial{1}(m, :), 1);
                temp_dataBLA = data.trial{1}(m,:) - BLAmean;
                
            elseif strcmpi(field_str, 'clean_data_lfp_filt')
                m = cellfun(@(x) contains(x,'BLA'), data.label, 'UniformOutput', 0); %these are the BLA channels
                m = cell2mat(m)'; %make a logical array
                BLAmean = mean(data.trial(m, :), 1);
                temp_dataBLA = data.trial(m,:) - BLAmean;
                
                
                
            end
            %Make sure labels are Nx1 cell array
            if size(data.label,1) < size(data.label,2)
                rat(ind).day(nday).timepoint(ntime).labels_car = data.label'; %update to "old" labels
            elseif size(data.label,1) > size(data.label,2)
                rat(ind).day(nday).timepoint(ntime).labels_car = data.label;
            end
        end
        
        % view CAR by region output
        data_CAR.trial = {[temp_dataIL; temp_dataBLA]};
        
        if strcmpi(field_str, 'clean_data_filt')
            data_CAR.time = {rat(ind).day(nday).timepoint(ntime).timeline};
        elseif strcmpi(field_str, 'clean_data_lfp_filt')
            data_CAR.time = {rat(ind).day(nday).timepoint(ntime).clean_data_time};
        end
        
        
        data_CAR.label = rat(ind).day(nday).timepoint(ntime).labels_car;
        
        cfg = [];
        cfg.channel = rat(ind).day(nday).timepoint(ntime).labels_car;
        cfg.continuous = 'yes';
        cfg.blocksize = 10;
        cfg.ylim = [-2000 2000]; %in uV
        ft_databrowser(cfg, data_CAR)
        grid on
        
        
        %save CAR by region re-referenced data to rat structure
        rat(ind).day(nday).timepoint(ntime).time_lfp_car = cell2mat(data_CAR.trial);
        
        
        
        
        
        
        
    otherwise
        warning('Unknown scheme selected for re-referencing.')
end



