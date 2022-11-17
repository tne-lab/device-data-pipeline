close all 
clear all

%for collecting means and sdevs of all the graphs

tic

data_channel=30; % INPUT DATA CHANNEL HERE ** channel for phase calc, look at data channel on roseplot

closedloopPath_1 = 'C:\Users\TNEL\Documents\ephysdata\DF07\day1\CLOSED_LOOP_2022-11-08_16-06-26\Record Node 101\experiment1\recording1\structure.oebin';



% closedloopPath_1 = ['C:\ephysdata\dev2218\day10_ASIC\CLOSED_LOOP_2022-11-04_10-36-50\Record Node 104\experiment1\recording1\structure.oebin'];
% closedloopPath_2 = 'C:\ephysdata\dev2218\day10_ASIC\CLOSED_LOOP_2022-11-04_10-36-50\Record Node 108\experiment1\recording1\structure.oebin';

%% Determine Bipolar Channel References %pairs them 
% if data_channel==8 %references 
%     data_channel1=1;
% else
%     data_channel1=data_channel+1;
% end

%% Get binary data (LFP on 1st Node)
% Convert both continuous LFP  *.mat
RawData = load_open_ephys_binary(closedloopPath_1, 'continuous',1,'mmap');

lfpdata = double(RawData.Data.Data.mapped(data_channel,:));

% lfpdata = double(RawData.Data.Data.mapped(data_channel,:)-RawData.Data.Data.mapped(data_channel1,:)); %already re-referenced in signal chain!
%lfpdata = double(RawData.Data.Data.mapped(7,:));
lfptime=RawData.Timestamps;


%% Get binary data (Phase on 2nd Node)
RawData_ev3=load_open_ephys_binary(closedloopPath_1, 'events',3); %edit to grab 2 as well (STIM); %NO NEED to use Node #2.
% RawData_Phase=load_open_ephys_binary(closedloopPath_2,'continuous',1,'mmap');
% phasedata = double(RawData_Phase.Data.Data.mapped(1,:))*RawData_Phase.Header.channels(1).bit_volts;
% phasetime=RawData_Phase.Timestamps;



%% Compute Gnd Truth phase
% bandpass filter
band = [4 8]; % 4 to 8hz bandpass
Fs = 30000;
[b, a] = butter(2, band/(Fs/2)); % 2nd order butterworth filter
data_filt = nan(size(lfpdata,1),size(lfpdata,2));
data_complex = data_filt; %#ok<NASGU>
phase = data_filt; %#ok<NASGU>
% calculate phases
   
        data_filt = filtfilt(b, a, lfpdata); % bandpassed data
        data_complex = hilbert(data_filt); % perform a hilbert transform on the data to get the complex component.
        phase = angle(data_complex); % phase in radians! Use rad2deg() if you prefer things in degrees.
        
        %% Marks changes %%
        % have to convert event timestamps into continuous data index
         event_ts = RawData_ev3.Timestamps(RawData_ev3.Data==3);
         [dat, data_inds] = ismember(event_ts, RawData.Timestamps);
         data_inds_clean = data_inds(data_inds~=0); %all 0s erased
         data2plot2 = phase(data_inds_clean);
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
% 
 %figure()
 %plot(phasetime,phasedata);
 %hold on; 
 %plot(lfptime,rad2deg(phase));
 %plot(event_ts,ones(length(event_ts))*180,'x');
 %ylim([-190 190])
 %legend('Calculated Phase', 'Ground Truth Phase', 'Stim Events')

mean=rad2deg(circ_mean(data2plot2));
if mean<0
    mean=mean+360;
%else
    %data2plot=-data2plot-pi/6;
end

figure()
ph = polarhistogram(data2plot2,24,'BinWidth',pi/12);
%set(gca, 'FontName', 'Arial', 'FontSize', 34, 'FontWeight', 'bold')
% ax = polaraxes;
% ax.FontSize = 10;
set(gca,'FontSize',10)
ax = gca;
%ax.RTickLabel = [];
hold on
polarplot([circ_mean(data2plot2');circ_mean(data2plot2')], [0;max(ph.Values)],'Color','r','LineWidth',3)   
title('ASIC Accuracy')

%RawData2=load_open_ephys_binary(closedloopPath1, 'continuous',1,'mmap');
%phase =  double(RawData1.Data.Data.mapped(3,:));

mean=mean
sdev=rad2deg(circ_std(data2plot2))


toc
