
%{
Script created by JT on 4/3/23 to streamline all the plots we need for
analysis of power and coherence

This script should call on all the required scripts to output all the plots
we want to see which include: -
1. Coherence plots, (x2)
2. Power plots, (x4)
3. Effect size plots of coherence and power, 
4. Average power in theta,
5. Average coherence in theta, (x2)
6. Outputs effect size to excel sheet in main rat file (ex. .../Dev2308)
7. Outputs IL/BLA power, var, coh, coh var to an excel sheet for each day
ran - same idea as #6
%}

clear,clc,close all

dirr = 'Z:\projmon\virginia-dev\01_EPHYSDATA\';
rat = 'Dev2303'; % UPDATE
day_num = 'day20'; %UPDATE
cond = '_TORTE'; % UPDATE %MUST include underscore prefix, case sensitive
day = strcat(day_num, cond);
myDir = strcat(dirr,rat,'\',day,'\');

filestr = 'RAW_PRE_2023-03-27_15-13-58'; % UPDATE

% func_ConfirmNode_quick_check(myDir, filestr, rat, day) %Confirms we're using the right node

% func_cleandsgen(dir, rat, strcat(day,'\')) % UNCOMMENT IF RUNNING A FRESH
% FILE

file = strcat(myDir,'\');
PowPlot = 1;
CrsPlot = 0;
recalcTFR = 1; % CHANGE TO 1 IF YOU WANT TO CALCULATE TFR, 0 IF ITS ALREADY CALCULATED
[IL_chlabel, BLA_chlabel, chlabel, p_mean1, p_mean2,p_var1, p_var2, n_pow1, n_pow2, avthetaband, avthetaband_nsamples, avthetaband_std, avthetaband_var]=mtmcoh_rescaled_lowfreqpwr_clean_AvgThetaOutputs(file, PowPlot,CrsPlot, recalcTFR)
n_pow1 = n_pow1(1:4:end,:);

% ------ Nothing below this should be changed unless troubleshooting
%% Calculation for POWER in IL and BLA
% Calculate standard error of mean of power in IL and BLA
sem_RAW_PRE_IL = sqrt(p_var1(:,1))./sqrt(n_pow1(:,1)); %std error for raw pre IL
sem_RAW_PRE_BLA = sqrt(p_var2(:,1))./sqrt(n_pow2(:,1)); %std error for raw pre BLA

sem_RAW_POST_IL = sqrt(p_var1(:,2))./sqrt(n_pow1(:,2)); %std error for raw pre IL
sem_RAW_POST_BLA = sqrt(p_var2(:,2))./sqrt(n_pow2(:,2)); %std error for raw pre BLA

% Calculate pooled std dev of power in IL and BLA
pooled_stddev_IL = sqrt(((n_pow1(:,1) - 1).*p_var1(:,1) + (n_pow1(:,2) - 1).*p_var1(:,2))./(n_pow1(:,1)+n_pow1(:,2)-2));
pooled_stddev_BLA = sqrt(((n_pow2(:,1) - 1).*p_var2(:,1) + (n_pow2(:,2) - 1).*p_var2(:,2))./(n_pow2(:,1)+n_pow2(:,2)-2));

% Calculate cohens D effect size of power in IL and BLA
effectSize_cohensD_IL = (p_mean1(:,2)-p_mean1(:,1))./pooled_stddev_IL(:,1);
effectSize_cohensD_BLA = (p_mean2(:,2)-p_mean2(:,1))./pooled_stddev_BLA(:,1);

%% creating tables to store raw power values

power_tab = table;
power_tab.Channel = [IL_chlabel' BLA_chlabel']';
tmp_power_tab = table(cat(1, p_mean1, p_mean2));
new_power_tab = [power_tab, tmp_power_tab];
new_power_tab = splitvars(new_power_tab);
new_power_tab.Properties.VariableNames = [new_power_tab.Properties.VariableNames{1}, "RAW PRE pwr", "RAW POST pwr"];

var_tab = table;
% var_tab.Channel = [IL_chlabel' BLA_chlabel']';
tmp_var_tab = table(cat(1, p_var1, p_var2));
new_var_tab = [var_tab, tmp_var_tab];
new_var_tab = splitvars(new_var_tab);
new_var_tab.Properties.VariableNames = ["RAW PRE pwr var", "RAW POST pwr var"];

nsamples_tab = table;
% nsamples_tab.Channel = [IL_chlabel' BLA_chlabel']';
nsamples_var_tab = table(cat(1, n_pow1, n_pow2));
new_nsamples_tab = [nsamples_tab, nsamples_var_tab];
new_nsamples_tab = splitvars(new_nsamples_tab);
new_nsamples_tab.Properties.VariableNames = ["RAW PRE pwr N", "RAW POST pwr N"];

%% POWER PLOTS
% Plot avg power in theta for IL/BLA with std error
figure;
set(gcf, 'position', [250   484   1284   661])
tiledlayout(1,2);

nexttile
plot(cat(1,p_mean1(:,1),p_mean2(:,1)), 'o', MarkerFaceColor='b',LineStyle='none')
hold on;
plot(cat(1,p_mean1(:,2),p_mean2(:,2)), 'o', MarkerFaceColor='r',LineStyle='none')
hold on;
errorbar([1:8],cat(1,p_mean1(:,1),p_mean2(:,1)),cat(1,sem_RAW_PRE_IL,sem_RAW_PRE_BLA),'.',Color='b')
hold on;
errorbar([1:8],cat(1,p_mean1(:,2),p_mean2(:,2)),cat(1,sem_RAW_POST_IL,sem_RAW_POST_BLA),'.',Color='r')
grid on;
title('Average Power in Theta Band for IL/BLA Channels with Standard Error')
xlim([0 9])
xticklabels([' ' [IL_chlabel' BLA_chlabel']])
xticks(0:1:9)
ylabel('Average Power in Theta Band (4-12 Hz)')
xlabel('Channel Labels')
legend("RAW PRE","RAW POST")

% Plot Effect Size of Power After Stim
nexttile
plot(cat(1,effectSize_cohensD_IL,effectSize_cohensD_BLA), 'x', MarkerFaceColor='b',MarkerEdgeColor='b',LineStyle='none', MarkerSize=12)
grid on;
title('Effect Size of Power')
xlim([0 9])
xticklabels([' ' [IL_chlabel' BLA_chlabel']])
xticks(0:1:9)
ylabel('Effect Size')
xlabel('Channel Labels')

%% Calculation for COHERENCE in IL/BLA channel combinations
% Calculate std error
sem_PRE_COH = sqrt([avthetaband_var.RAW_PRE.chan{1,:}])./sqrt([avthetaband_nsamples.RAW_PRE.chan{1,:}]);
sem_POST_COH = sqrt([avthetaband_var.RAW_POST.chan{1,:}])./sqrt([avthetaband_nsamples.RAW_POST.chan{1,:}]);

% Calculate pooled std dev
pooled_stddev_COH = sqrt((([avthetaband_nsamples.RAW_PRE.chan{1,:}] - 1).*[avthetaband_var.RAW_PRE.chan{1,:}] + ([avthetaband_nsamples.RAW_POST.chan{1,:}] - 1).*[avthetaband_var.RAW_POST.chan{1,:}])./...
                    ([avthetaband_nsamples.RAW_PRE.chan{1,:}]+[avthetaband_nsamples.RAW_POST.chan{1,:}]-2));

% Calculate cohens d effect size
effectSize_cohensD_COH = ([avthetaband.RAW_POST.chan{1,:}]-[avthetaband.RAW_PRE.chan{1,:}])./pooled_stddev_COH;

%% creating tables to store raw coh values

coh_tab = table;
coh_tab.Channel = chlabel;
tmp_coh_tab = table([avthetaband.RAW_PRE.chan{1,:}]', [avthetaband.RAW_POST.chan{1,:}]');
new_coh_tab = [coh_tab, tmp_coh_tab];
new_coh_tab = splitvars(new_coh_tab);
new_coh_tab.Properties.VariableNames = [new_coh_tab.Properties.VariableNames{1}, "RAW PRE Coh", "RAW POST Coh"];

coh_var_tab = table;
% coh_var_tab.Channel = chlabel;
tmp_coh_var_tab = table([avthetaband_var.RAW_PRE.chan{1,:}]', [avthetaband_var.RAW_POST.chan{1,:}]');
new_coh_var_tab = [coh_var_tab, tmp_coh_var_tab];
new_coh_var_tab = splitvars(new_coh_var_tab);
new_coh_var_tab.Properties.VariableNames = ["RAW PRE coh var", "RAW POST coh var"];

coh_nsamples_tab = table;
% coh_nsamples_tab.Channel = chlabel;
tmp_coh_nsamples_tab = table([avthetaband_nsamples.RAW_PRE.chan{1,:}]', [avthetaband_nsamples.RAW_POST.chan{1,:}]');
new_coh_nsamples_tab = [coh_nsamples_tab, tmp_coh_nsamples_tab];
new_coh_nsamples_tab = splitvars(new_coh_nsamples_tab);
new_coh_nsamples_tab.Properties.VariableNames = ["RAW PRE coh N", "RAW POST coh N"];

%% COHERENCE PLOTS
% Plot avg coherence in theta for IL/BLA with std error
figure;
set(gcf, 'position', [250    484   1284    661])
tiledlayout(1,2);

nexttile
plot([avthetaband.RAW_PRE.chan{1,:}], 'o', MarkerFaceColor='b',LineStyle='none')
hold on;
plot([avthetaband.RAW_POST.chan{1,:}], 'o', MarkerFaceColor='r',LineStyle='none')
hold on;
errorbar([1:16],[avthetaband.RAW_PRE.chan{1,:}],sem_PRE_COH,'.',Color='b')
hold on;
errorbar([1:16],[avthetaband.RAW_POST.chan{1,:}],sem_POST_COH,'.',Color='r')
grid on;
title('Average Coherence in Theta Band across Time in the 16 Channel Combinations')
xlim([0 17])
yline(0.15, 'HandleVisibility','off');
xticklabels([' ' chlabel'])
xticks(0:1:17)
ylim([0 1])
ylabel('Average Coherence in Theta Band (4-12 Hz)')
xlabel('Channel Labels')
legend("RAW PRE","RAW POST")

% Plot Effect Size of coh After Stim
nexttile
plot(effectSize_cohensD_COH, 'x', MarkerFaceColor='b',MarkerEdgeColor='b',LineStyle='none', MarkerSize=12)
grid on;
title('Effect Size of Coherence')
xlim([0 17])
xticklabels([' ' chlabel'])
xticks(0:1:17)
ylabel('Effect Size')
xlabel('Channel Labels')

%% Save effect size to an excel sheet to run the summary plot

power_chLabel = [IL_chlabel' BLA_chlabel']';

%Power effect size
effectSize_TORTEpower = table;
effectSize_TORTEpower.Channel = power_chLabel;

effectSize_SHAMpower = table;
effectSize_SHAMpower.Channel = power_chLabel;

effectSize_ASICpower = table;
effectSize_ASICpower.Channel = power_chLabel;

effectSize_RNDpower = table;
effectSize_RNDpower.Channel = power_chLabel;

%Coh effect size
effectSize_TORTEcoh = table;
effectSize_TORTEcoh.Channel = chlabel;

effectSize_SHAMcoh = table;
effectSize_SHAMcoh.Channel = chlabel;

effectSize_ASICcoh = table;
effectSize_ASICcoh.Channel = chlabel;

effectSize_RNDcoh = table;
effectSize_RNDcoh.Channel = chlabel;

tmpdir = [dirr,'\',rat];
d = dir(fullfile(tmpdir, '*_EFFECTSIZE.xlsx'));
filename = strcat('Z:\projmon\virginia-dev\01_EPHYSDATA\',rat,'\',rat,"_EFFECTSIZE.xlsx");

if length(d) == 0 % Check if file exists, if not - create it.
    writetable(effectSize_TORTEpower, filename, 'Sheet', 'TORTE Power')
    writetable(effectSize_SHAMpower, filename, 'Sheet', 'Sham Power')
    writetable(effectSize_ASICpower, filename, 'Sheet', 'ASIC Power')
    writetable(effectSize_RNDpower, filename, 'Sheet', 'RND Power')

    writetable(effectSize_TORTEcoh, filename, 'Sheet', 'TORTE Coherence')
    writetable(effectSize_SHAMcoh, filename, 'Sheet', 'Sham Coherence')
    writetable(effectSize_ASICcoh, filename, 'Sheet', 'ASIC Coherence')
    writetable(effectSize_RNDcoh, filename, 'Sheet', 'RND Coherence')
end

switch cond
    case '_TORTE'
        effectSize_TORTEpower = readtable(filename, 'Sheet', "TORTE Power");
        tmp_effectSize_TORTEpower = table(cat(1,effectSize_cohensD_IL,effectSize_cohensD_BLA));
        new_effectSize_TORTEpower = [effectSize_TORTEpower, tmp_effectSize_TORTEpower];
        new_effectSize_TORTEpower.Properties.VariableNames = [new_effectSize_TORTEpower.Properties.VariableNames{1:end-1}, {day_num}];
        writetable(new_effectSize_TORTEpower,filename, 'Sheet', 'TORTE Power')
        
        effectSize_TORTEcoh = readtable(filename, 'Sheet','TORTE Coherence');
        tmp_effectSize_TORTEcoh = table(effectSize_cohensD_COH');
        new_effectSize_TORTEcoh = [effectSize_TORTEcoh, tmp_effectSize_TORTEcoh];
        new_effectSize_TORTEcoh.Properties.VariableNames = [new_effectSize_TORTEcoh.Properties.VariableNames{1:end-1},  {day_num}];
        writetable(new_effectSize_TORTEcoh,filename, 'Sheet', 'TORTE Coherence')

    case '_sham'
        effectSize_SHAMpower = readtable(filename, 'Sheet', "Sham Power");
        tmp_effectSize_SHAMpower = table(cat(1,effectSize_cohensD_IL,effectSize_cohensD_BLA));
        new_effectSize_SHAMpower = [effectSize_SHAMpower, tmp_effectSize_SHAMpower];
        new_effectSize_SHAMpower.Properties.VariableNames = [new_effectSize_SHAMpower.Properties.VariableNames{1:end-1}, {day_num}];
        writetable(new_effectSize_SHAMpower,filename, 'Sheet', 'Sham Power')
        
        effectSize_SHAMcoh = readtable(filename, 'Sheet','Sham Coherence');
        tmp_effectSize_SHAMcoh = table(effectSize_cohensD_COH');
        new_effectSize_SHAMcoh = [effectSize_SHAMcoh, tmp_effectSize_SHAMcoh];
        new_effectSize_SHAMcoh.Properties.VariableNames = [new_effectSize_SHAMcoh.Properties.VariableNames{1:end-1},  {day_num}];
        writetable(new_effectSize_SHAMcoh,filename, 'Sheet', 'Sham Coherence')

    case'_ASIC'
        effectSize_ASICpower = readtable(filename, 'Sheet', "ASIC Power");
        tmp_effectSize_ASICpower = table(cat(1,effectSize_cohensD_IL,effectSize_cohensD_BLA));
        new_effectSize_ASICpower = [effectSize_ASICpower, tmp_effectSize_ASICpower];
        new_effectSize_ASICpower.Properties.VariableNames = [new_effectSize_ASICpower.Properties.VariableNames{1:end-1}, {day_num}];
        writetable(new_effectSize_ASICpower,filename, 'Sheet', 'ASIC Power')
        
        effectSize_ASICcoh = readtable(filename, 'Sheet','ASIC Coherence');
        tmp_effectSize_ASICcoh = table(effectSize_cohensD_COH');
        new_effectSize_ASICcoh = [effectSize_ASICcoh, tmp_effectSize_ASICcoh];
        new_effectSize_ASICcoh.Properties.VariableNames = [new_effectSize_ASICcoh.Properties.VariableNames{1:end-1},  {day_num}];
        writetable(new_effectSize_ASICcoh,filename, 'Sheet', 'ASIC Coherence')

    case'_RND'
        effectSize_RNDpower = readtable(filename, 'Sheet', "RND Power");
        tmp_effectSize_RNDpower = table(cat(1,effectSize_cohensD_IL,effectSize_cohensD_BLA));
        new_effectSize_RNDpower = [effectSize_RNDpower, tmp_effectSize_RNDpower];
        new_effectSize_RNDpower.Properties.VariableNames = [new_effectSize_RNDpower.Properties.VariableNames{1:end-1}, {day_num}];
        writetable(new_effectSize_RNDpower,filename, 'Sheet', 'RND Power')
        
        effectSize_RNDcoh = readtable(filename, 'Sheet','RND Coherence');
        tmp_effectSize_RNDcoh = table(effectSize_cohensD_COH');
        new_effectSize_RNDcoh = [effectSize_RNDcoh, tmp_effectSize_RNDcoh];
        new_effectSize_RNDcoh.Properties.VariableNames = [new_effectSize_RNDcoh.Properties.VariableNames{1:end-1},  {day_num}];
        writetable(new_effectSize_RNDcoh,filename, 'Sheet', 'RND Coherence')
end

%% Saving raw values from tables to an excel file for potential future analyses

tmpdir = [dirr,rat,'\'];
d = dir(fullfile(tmpdir, '*_PwrCohVarN.xlsx'));
filename = strcat(tmpdir,rat,'PwrCohVarN.xlsx');
sheet = strcat('Power_', day);

%combine into one table
main_pwr_tab = [new_power_tab, new_var_tab,new_nsamples_tab];
main_coh_tab = [new_coh_tab, new_coh_var_tab,new_coh_nsamples_tab];

if length(d) == 0 % Check if file exists, if not - create it.
    writetable(main_pwr_tab, filename, 'Sheet', strcat('Power', day))
    writetable(main_coh_tab, filename,'Sheet',strcat('Coh', day));
else
    tmp_table_pwr = readtable(filename,'Sheet',strcat('Power', day));
    new_table_pwr = table(main_pwr_tab);
    new_table_pwr = [tmp_table_pwr, new_table_pwr];
    writetable(new_table_pwr, strcat(tmpdir,'\',rat,'PwrCohVarN.xlsx'),'Sheet',strcat('Power', day));

    tmp_table_coh = readtable(strcat(tmpdir,'\',rat,'PwrCohVarN.xlsx'),'Sheet',strcat('Coh', day));
    new_table_coh = table(main_coh_tab);
    new_table_coh = [tmp_table_coh, new_table_coh];
    writetable(new_table_coh, strcat(tmpdir,'\',rat,'PwrCohVarN.xlsx'),'Sheet',strcat('Coh', day));
end





