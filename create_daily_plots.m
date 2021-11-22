function create_daily_plots
close all

% grab data file
[file, logfile_folder] = uigetfile;

% get data from log file
log_data = load([logfile_folder, '/log_file.mat']);
%load(logfile_path);()


data_struct = {};

%% loop through all paths in log file to clean (load in data once)
for i = 1:size(log_data.paths)
    % get cur path
    cur_path = strtrim(log_data.paths(i,:)); % paths save with whitespace, strtrim makes words looks nice
    
    % find corresponding data mat files
    if ispc
        folder_split = split(logfile_folder, '\');
    else
        folder_split = split(logfile_folder, '/');
    end
    
    cur_pow = load([logfile_folder, cur_path, '_', char(folder_split(end-2)), '_', char(folder_split(end-1)), '_TFR.mat']);
    pow_struct{i} = cur_pow;
    
    cur_coh = load([logfile_folder, cur_path, '_', char(folder_split(end-2)), '_', char(folder_split(end-1)), '_coh.mat']);
    coh_struct{i} = cur_coh;
    
    if contains(cur_path, 'RAW_PRE')
        idx_pre = i;
        rat_name = char(folder_split(end-2));
        day_num = char(folder_split(end-1));
        
    elseif contains(cur_path, 'RAW_POST')
        idx_post = i;
    end
    
end

% create_daily_heatmaps(rat_name, day_num, coh_struct, pow_struct, idx_pre, idx_post)
create_daily_spectra(rat_name, day_num, coh_struct, pow_struct, idx_pre, idx_post)



end

function create_daily_spectra(rat_name, day_num, coh_struct, pow_struct, idx_pre, idx_post)
%% Plot channel-wise spectra pre & post stim

fig = figure;
set(fig, 'WindowState', 'maximized');
sgtitle([rat_name ', ', day_num]);
x = coh_struct{1, idx_pre}.coh.freq;
cc = parula(size(coh_struct{1,idx_pre}.cmb_labels,1));



subplot(2,3, 1)
for ch =1:size(coh_struct{1,idx_pre}.cmb_labels,1)
    kt = squeeze(coh_struct{1, idx_pre}.coh.cohspctrm(ch, :,:));
    plot(x,nanmean(kt,2), 'color', cc(ch,:))
    hold on;
end
title('Coherence vs Freq [Pre stim]');
xlabel('Frequency');
ylabel('Coherence');
ylim([0 1])
grid on


subplot(2,3, 2)
for ch =1:size(coh_struct{1,idx_post}.cmb_labels,1)
    kt = squeeze(coh_struct{1, idx_post}.coh.cohspctrm(ch, :,:));
    plot(x,nanmean(kt,2), 'color', cc(ch,:))
    hold on;
end
title('Coherence vs Freq [Post stim]');
xlabel('Frequency');
ylabel('Coherence');
ylim([0 1])
xlim([0 30])
grid on


subplot(2,3, 3)
for ch =1:size(coh_struct{1,idx_post}.cmb_labels,1)
    kt = squeeze(coh_struct{1, idx_post}.coh.cohspctrm(ch, :,:));
    coh_post = nanmean(kt,2);
    
    jt = squeeze(coh_struct{1, idx_pre}.coh.cohspctrm(ch, :,:));
    coh_pre = nanmean(jt,2);
    
    plot(x,coh_post - coh_pre, 'color', cc(ch,:))
    hold on;
end
title('Change in Coherence [Post - Pre] vs Freq');
xlabel('Frequency');
ylabel('Coherence');
ylim([-1 1])
xlim([0 30])
grid on


subplot(2,3,4)
[idx_lower, idx_upper] = find(and(x >= 4, x <= 8)); %theta band

for ch = 1:size(coh_struct{1,idx_post}.cmb_labels,1) 
    %for each channel, pull the Pre(theta values) & Post(theta values) 
    pre_meanCoh_theta(ch) = mean(nanmean(squeeze(coh_struct{1, idx_pre}.coh.cohspctrm(ch, idx_lower:idx_upper,:)), 2));
    post_meanCoh_theta(ch) = mean(nanmean(squeeze(coh_struct{1, idx_post}.coh.cohspctrm(ch, idx_lower:idx_upper,:)), 2));
end

h1 = histfit(pre_meanCoh_theta, 10, 'kernel'); hold on
h2 = histfit(post_meanCoh_theta, 10, 'kernel');

set(h1(1), 'FaceAlpha', 0.2)
set(h1(2), 'color', [0 0 128]./255)
set(h2(1), 'FaceAlpha', 0.2)
set(h2(2), 'color', [255 165 0]./255)

grid on
xlabel('Theta coherence')
ylabel('Channel count')
legend([h1(2), h2(2)], 'pre', 'post')
title({'Mean theta distributions [pre & post stim]', '\rm (pooled across all channels)'})






subplot(2,3, 6)
std_preCoh = std(pre_meanCoh_theta,0,2);
mean_preCoh = mean(pre_meanCoh_theta);

%for each channel, plot the Z-scored theta coherence
for ch = 1:size(coh_struct{1,idx_post}.cmb_labels,1)
    obj(ch) = plot(ch, (post_meanCoh_theta(ch) - mean_preCoh)/std_preCoh, 'color', cc(ch,:), 'marker', 'o',...
        'markerfacecolor', cc(ch,:), 'markersize', 8);
    hold on
end
%calculate mean values across all channels
mean_Zscore = mean((post_meanCoh_theta - mean_preCoh)./std_preCoh);
std_Zscore = std((post_meanCoh_theta - mean_preCoh)./std_preCoh, 0,2);
grid on
xlabel('Channel combination')
xtickangle(45)
set(gca, 'xtick',  1:size(coh_struct{1,idx_post}.cmb_labels,1))
set(gca, 'xticklabel', coh_struct{1,idx_post}.cmb_labels)

num_ILchan = sum(contains(coh_struct{1,idx_post}.coh.cfg.channel, 'IL'));
num_BLAchan = sum(contains(coh_struct{1,idx_post}.coh.cfg.channel, 'BLA'));
yaxisLimits = get(gca, 'YLim');




for i = 1:num_ILchan
    if mod(i,2)==0
        rectangle('Position',[(i-1)*num_BLAchan+0.5 yaxisLimits(1) num_BLAchan yaxisLimits(2)+abs(yaxisLimits(1))], 'FaceColor',[220 220 220]./256, 'EdgeColor', [220 220 220]./256)
    end
end
uistack(obj,'top')
title({['Z-scored theta coherence = ', num2str(mean_Zscore, 1), ' \pm ', num2str(std_Zscore,2)], '\rm (pooled across all channels)'})


 %% Z score vs Frequency

for ch =1:size(coh_struct{1,idx_post}.cmb_labels,1)
    kt = squeeze(coh_struct{1, idx_post}.coh.cohspctrm(ch, :,:));
    coh_post = nanmean(kt,2);
    
    jt = squeeze(coh_struct{1, idx_pre}.coh.cohspctrm(ch, :,:));
    coh_pre = nanmean(jt,2);
    
    zscore = (coh_post-coh_pre)/std(coh_pre);
    zscore_av1(:,ch) = zscore;
    subplot(2,3,5)
    plot(x,zscore, 'color', cc(ch,:))
    xlim([0 30])
    
    grid on;
    hold on;
    title('Z-Scored Theta Coherance vs Freq');
    xlabel('Frequency');
    ylabel('Z-Score');
    
end       
% plotting average across channels
hold on
for i = 1:60
zscore_av(i,:) = sum(zscore_av1(i,:))/8;
end
z = plot(x,zscore_av, 'k*-');
lgd = legend([z],{'Channel Average'});
legend('Location','southeast')
end
%%
function create_daily_heatmaps(rat_name, day_num, coh_struct, pow_struct, idx_pre, idx_post)
fig = figure;
set(fig, 'WindowState', 'maximized');
sgtitle([rat_name ', ', day_num]);

subplot(2,3, 1)
%pre coherence spectra
cmb = length(coh_struct{1,idx_pre}.cmb_labels);
imagesc(coh_struct{1,idx_pre}.freq, 1:cmb, coh_struct{1,idx_pre}.coh_spect)
% c = parula;
colormap(parula);
set(gca, 'xticklabels', coh_struct{1,idx_pre}.freq)
xtickformat('%,.0f')
xlabel('Frequency (Hz)')
set(gca, 'ytick', 1:numel(coh_struct{1, idx_pre}.cmb_labels))
set(gca, 'yticklabel', coh_struct{1, idx_pre}.cmb_labels)
% ylabel('Channel cmb #')
c = colorbar;
% c.Label.String = '\bf{dB}';
% c.Rotation = 180;

  caxis([0 1])
hold on
% lcolorbar('dB')
plot([4 4], [0 cmb], '--k')
plot([8 8], [0 cmb], '--k')
title('Pre coh')


subplot(2,3, 2)
%post coherence spectra

cmb = length(coh_struct{1,idx_post}.cmb_labels);
imagesc(coh_struct{1,idx_post}.freq, 1:cmb, coh_struct{1,idx_post}.coh_spect)
% c = parula;
colormap(parula);
set(gca, 'xticklabels', coh_struct{1,idx_post}.freq)
xtickformat('%,.0f')
xlabel('Frequency (Hz)')
set(gca, 'yticklabel', coh_struct{1, idx_post}.cmb_labels)
% ylabel('Channel cmb #')
colorbar
  caxis([0 1])
hold on
% lcolorbar('dB')
plot([4 4], [0 cmb], '--k')
plot([8 8], [0 cmb], '--k')
title('Post coh')



subplot(2,3, 3)
%post coherence spectra
cmb = length(coh_struct{1,idx_post}.cmb_labels);
imagesc(coh_struct{1,idx_post}.freq, 1:cmb, coh_struct{1,idx_post}.coh_spect - coh_struct{1,idx_pre}.coh_spect)
% c = parula;
colormap(parula);
set(gca, 'xticklabels', coh_struct{1,idx_post}.freq)
xtickformat('%,.0f')
xlabel('Frequency (Hz)')
set(gca, 'yticklabel', coh_struct{1, idx_post}.cmb_labels)
% ylabel('Channel cmb #')
colorbar
  caxis([0 1])
hold on
% lcolorbar('dB')
plot([4 4], [0 cmb], '--k')
plot([8 8], [0 cmb], '--k')
title('Change in coh')

% power plots
subplot(2,3, 4)
%pre power spectra
cmb = length(pow_struct{1,idx_pre}.chan_labels);
imagesc(pow_struct{1,idx_pre}.freq, 1:cmb, 10*log10(pow_struct{1,idx_pre}.powspctrm))
% c = parula;
colormap(parula);
set(gca, 'xticklabels', pow_struct{1,idx_pre}.freq)
xtickformat('%,.0f')
xlabel('Frequency (Hz)')
set(gca, 'yticklabel', pow_struct{1, idx_pre}.chan_labels)
% ylabel('Channel cmb #')
c = colorbar; 
caxis([-10 40])
c.Label.String = '\bf{dB}';
c.Label.Rotation = 90;
hold on
% lcolorbar('dB')
plot([4 4], [0 cmb], '--k')
plot([8 8], [0 cmb], '--k')
title('Pre Power')


subplot(2,3, 5)
%post power spectra
cmb = length(pow_struct{1,idx_post}.chan_labels);
imagesc(pow_struct{1,idx_post}.freq, 1:cmb, 10*log10(pow_struct{1,idx_post}.powspctrm))
% c = parula;
colormap(parula);
set(gca, 'xticklabels', pow_struct{1,idx_post}.freq)
xtickformat('%,.0f')
xlabel('Frequency (Hz)')
set(gca, 'yticklabel', pow_struct{1, idx_post}.chan_labels)
% ylabel('Channel cmb #')

hold on
c = colorbar; 
c.Label.String = '\bf{dB}';
c.Label.Rotation = 90;
plot([4 4], [0 cmb], '--k')
plot([8 8], [0 cmb], '--k')
title('Post Power')
caxis([-10 40])

subplot(2,3, 6)
%change in power spectra

imagesc(pow_struct{1,idx_post}.freq, 1:cmb, 10*log10(pow_struct{1,idx_post}.powspctrm) - 10*log10(pow_struct{1,idx_pre}.powspctrm))
% c = parula;
colormap(parula);
set(gca, 'xticklabels', pow_struct{1,idx_post}.freq)
xtickformat('%,.0f')
xlabel('Frequency (Hz)')
set(gca, 'yticklabel', pow_struct{1, idx_post}.chan_labels)
% ylabel('Channel cmb #')
c = colorbar; 
c.Label.String = '\bf{dB}';
c.Label.Rotation = 90;
hold on
caxis([-10 40])
% lcolorbar('dB')
plot([4 4], [0 cmb], '--k')
plot([8 8], [0 cmb], '--k')
title('Change in Power')


end

