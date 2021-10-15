close all
clear all
%    clearvars -except rat
clc


global saveLocation


%main analysis call
% use of Loader version enables  partially processed datasets to be loaded
% in for further analysis


 loadLocation = 'D:\ANALYSIS\';
load([loadLocation, 'rat_prelim_data.mat'], 'rat')
saveLocation = 'D:\ANALYSIS\';


%%
for i = 3 % rat
    for j = 1:10 %1 day
        for k =1:2 % timepoint in experimental session
            

% remove bad channels
% re-refernce
% filter
% auto remove artifacts
            
            %% Clean data
            
            input_field_str = 'time_lfp_lowres';
            
            % 1.) Remove bad channels
            % 2.) Automatic remove time segments with bio-artifacts
            rat = get_clean_data(rat, i, j, k, input_field_str);
            
            %%%%%% also remov from pre if post is bad
            %%%%%%% remove from post if pre is bad
            
            %% Re-reference (do before filter)
            input_field_str = 'clean_data_lfp_filt';
            
            rat = reref_data_ver5(rat, i, j, k , input_field_str, 'bipolar');
            rat = reref_data_ver5(rat, i, j, k , input_field_str, 'CAR by region');
        
            
            %% Filter

            input_field_str = 'clean_data_lfp'; 

            %Apply a Low-Pass filter
            filt_flag = [0 1 0 0]; %set coln to 1 for 60Hz notch, low_pass, high_pass, or bandpass;
            fc = 40; %low-pass cutoff frequency, up to 300 Hz
            rat = filter_func(rat, i, j, k, filt_flag, input_field_str, fc);
            


            %% Clean data again
            
            input_field_str = 'clean_data_lfp_bipolar';
            rat = get_clean_reref_data(rat, i, j, k, input_field_str);
            
            
            input_field_str = 'clean_data_lfp_car';
            rat = get_clean_reref_data(rat, i, j, k, input_field_str);
            
            %% TFR & Coherence
            %This section computes the coherence for both bipolar & CAR
            %signals. 
            %It uses Chronux functions:
            %    'chronux_coh2' calls coherencyc.m --> uses explicitly
            %    defined trials as an input
            %
            %    'chronux_coh2_movwin' calls cohgramc --> [I THINK] uses explicitly
            %    defined trials as an input; & moving window input -->
            %    Confirm the trial formatting
            %
            %Writes an excel file output with all coherence value for every
            %frequency point at each channel combination
            
            % -------------------------------------------------------------
            input_field_str = 'clean_reref_bipolar';
%             [rat, POW, CRSS, COH2] = chronux_coh2(rat, i, j, k, input_field_str);
            [rat, POW, CRSS, COH2] = chronux_coh2_movwin(rat, i, j, k, input_field_str);
            
            %% COH file write
            rat_name = rat(i).id;
            fname = [saveLocation, rat_name, '_prelim_data_COH_bipolar.xls'];
            sheet_name = ['Day', num2str(j), '_', rat(i).day(j).timepoint(k).name(1:4)];
            
            writetable(COH2, fname,'FileType','spreadsheet','Sheet', sheet_name, 'WriteVariableNames', 0)
            
            %% Power file write
            rat_name = rat(i).id;
            fname = [saveLocation, rat_name, '_prelim_data_POW_bipolar.xls'];
            sheet_name = ['Day', num2str(j), '_', rat(i).day(j).timepoint(k).name(1:4)];
            
            writetable(POW, fname,'FileType','spreadsheet','Sheet', sheet_name, 'WriteVariableNames', 0)
            
            
            %% -------------------------------------------------------------
            input_field_str = 'clean_reref_car';
            %             [rat, POW, CRSS, COH2] = chronux_coh2(rat, i, j, k, input_field_str);
            [rat, POW, CRSS, COH2] = chronux_coh2_movwin(rat, i, j, k, input_field_str);
            
            
            rat_name = rat(i).id;
            fname = [saveLocation, rat_name, '_prelim_data_COH_car.xls'];
            sheet_name = ['Day', num2str(j), '_', rat(i).day(j).timepoint(k).name(1:4)];
            
            writetable(COH2, fname,'FileType','spreadsheet','Sheet', sheet_name, 'WriteVariableNames', 0)
            
            
            rat_name = rat(i).id;
            fname = [saveLocation, rat_name, '_prelim_data_POW_car.xls'];
            sheet_name = ['Day', num2str(j), '_', rat(i).day(j).timepoint(k).name(1:4)];
            
            writetable(POW, fname,'FileType','spreadsheet','Sheet', sheet_name, 'WriteVariableNames', 0)
            
            
            close all
        end
    end
end


%%

tic
%save to disk
saveLocation = 'D:\ANALYSIS\';
%  save([saveLocation, 'rat_Dev2102_prelim_data.mat'], 'rat', '-v7.3')

toc