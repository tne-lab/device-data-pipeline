function rat = load_rat_Dev2102(ind, rat)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                   Dev21_02
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Implant date: 2021-05-25

rat(ind).id = 'Dev2102';

%% day 1
rat(ind).day(1).path = 'D:\EPHYSDATA\dev2102\day1\';

rat(ind).day(1).condition = {'Positive Control'};

rat(ind).day(1).timepoint(1).name = 'Pre stim';
rat(ind).day(1).timepoint(1).filename = {'RAW_PRE_2021-06-18_18-02-37'}; 

% FORWARD-LOOKING NOTE: 
% ERPs would then become filename(2) for IL and filename(3) for BLA.
% rat(ind).day(1).timepoint(1).filename(2) = {'ERP placeholder1'}; 
% rat(ind).day(1).timepoint(1).filename(3) = {'ERP placeholder2'}; 

%  rat(ind).day(1).timepoint(1).val = 3;


rat(ind).day(1).timepoint(2).name = 'Post stim';
rat(ind).day(1).timepoint(2).filename = {'RAW_POST_2021-06-18_18-38-45'};

% 30 minutes of closed-loop stim locked to the 180deg crossing of theta band
rat(ind).day(1).stimulation = closed_loop_stim_config(30, 'theta', 180);

%calendar date of testing
rat(ind).day(1).testingdate = '2021-06-18';

%% day 2
rat(ind).day(2).path = 'D:\EPHYSDATA\dev2102\day2\';
rat(ind).day(2).condition = {'Positive Control'};

rat(ind).day(2).timepoint(1).name = 'Pre stim';
rat(ind).day(2).timepoint(1).filename = {'RAW_PRE_2021-06-24_14-10-58'}; 

rat(ind).day(2).timepoint(2).name = 'Post stim';
rat(ind).day(2).timepoint(2).filename = {'RAW_POST_2021-06-24_14-46-07'};

rat(ind).day(2).stimulation = closed_loop_stim_config(30, 'theta', 180);

rat(ind).day(2).testingdate = '2021-06-24';

%% day 3
rat(ind).day(3).path = 'D:\EPHYSDATA\dev2102\day3\';
rat(ind).day(3).condition = {'Positive Control'};

rat(ind).day(3).timepoint(1).name = 'Pre stim';
rat(ind).day(3).timepoint(1).filename = {'RAW_PRE_2021-06-25_19-11-10'}; 

rat(ind).day(3).timepoint(2).name = 'Post stim';
rat(ind).day(3).timepoint(2).filename = {'RAW_POST_2021-06-25_19-46-23'};

rat(ind).day(3).stimulation = closed_loop_stim_config(30, 'theta', 180);

rat(ind).day(3).testingdate = '2021-06-25';

%% day 4
rat(ind).day(4).path = 'D:\EPHYSDATA\dev2102\day4\';
rat(ind).day(4).condition = {'Positive Control'};

rat(ind).day(4).timepoint(1).name = 'Pre stim';
rat(ind).day(4).timepoint(1).filename = {'RAW_PRE_2021-07-28_11-19-04'}; 

rat(ind).day(4).timepoint(2).name = 'Post stim';
rat(ind).day(4).timepoint(2).filename = {'RAW_POST_2021-07-28_11-54-14'};

rat(ind).day(4).stimulation = closed_loop_stim_config(30, 'theta', 180);

rat(ind).day(4).testingdate = '2021-07-28';

%% day 5
rat(ind).day(5).path = 'D:\EPHYSDATA\dev2102\day5\';
rat(ind).day(5).condition = {'Positive Control'};

rat(ind).day(5).timepoint(1).name = 'Pre stim';
rat(ind).day(5).timepoint(1).filename = {'RAW_PRE_2021-07-29_12-48-39'}; 

rat(ind).day(5).timepoint(2).name = 'Post stim';
rat(ind).day(5).timepoint(2).filename = {'RAW_POST_2021-07-29_13-30-09'};

rat(ind).day(5).stimulation = closed_loop_stim_config(30, 'theta', 180);

rat(ind).day(5).testingdate = '2021-07-29';

%% day 6
rat(ind).day(6).path = 'D:\EPHYSDATA\dev2102\day6\';
rat(ind).day(6).condition = {'Sham'};

rat(ind).day(6).timepoint(1).name = 'Pre stim';
rat(ind).day(6).timepoint(1).filename = {'RAW_PRE_2021-07-30_11-38-02'}; 

rat(ind).day(6).timepoint(2).name = 'Post stim';
rat(ind).day(6).timepoint(2).filename = {'RAW_POST_2021-07-30_12-21-27'};

rat(ind).day(6).stimulation = 'No stimulation';

rat(ind).day(6).testingdate = '2021-07-30';

%% day 7
rat(ind).day(7).path = 'D:\EPHYSDATA\dev2102\day7\';
rat(ind).day(7).condition = {'Sham'};

rat(ind).day(7).timepoint(1).name = 'Pre stim';
rat(ind).day(7).timepoint(1).filename = {'RAW_PRE_2021-08-04_10-28-58'}; 

rat(ind).day(7).timepoint(2).name = 'Post stim';
rat(ind).day(7).timepoint(2).filename = {'RAW_POST_2021-08-04_11-06-28'};

rat(ind).day(7).stimulation = 'No stimulation';

rat(ind).day(7).testingdate = '2021-08-04';

%% day 8
rat(ind).day(8).path = 'D:\EPHYSDATA\dev2102\day8\';
rat(ind).day(8).condition = {'Sham'};

rat(ind).day(8).timepoint(1).name = 'Pre stim';
rat(ind).day(8).timepoint(1).filename = {'RAW_PRE_2021-08-05_11-23-36'}; 

rat(ind).day(8).timepoint(2).name = 'Post stim';
rat(ind).day(8).timepoint(2).filename = {'RAW_POST_2021-08-05_12-00-04'};

rat(ind).day(8).stimulation = 'No stimulation';

rat(ind).day(8).testingdate = '2021-08-05';

%% day 9
rat(ind).day(9).path = 'D:\EPHYSDATA\dev2102\day9\';
rat(ind).day(9).condition = {'Sham'};

rat(ind).day(9).timepoint(1).name = 'Pre stim';
rat(ind).day(9).timepoint(1).filename = {'RAW_PRE_2021-08-06_11-08-45'}; 

rat(ind).day(9).timepoint(2).name = 'Post stim';
rat(ind).day(9).timepoint(2).filename = {'RAW_POST_2021-08-06_11-43-55'};

rat(ind).day(9).stimulation = 'No stimulation';

rat(ind).day(9).testingdate = '2021-08-06';

%% day 10
rat(ind).day(10).path = 'D:\EPHYSDATA\dev2102\day10\';
rat(ind).day(10).condition = {'Sham'};

rat(ind).day(10).timepoint(1).name = 'Pre stim';
rat(ind).day(10).timepoint(1).filename = {'RAW_PRE_2021-08-10_13-17-35'}; 

rat(ind).day(10).timepoint(2).name = 'Post stim';
rat(ind).day(10).timepoint(2).filename = {'RAW_POST_2021-08-10_13-56-37'};

rat(ind).day(10).stimulation = 'No stimulation';

rat(ind).day(10).testingdate = '2021-08-10';


