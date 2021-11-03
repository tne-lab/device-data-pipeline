function create_daily_plots
close all

% grab data file
[file, logfile_folder] = uigetfile;

% get data from log file
log_data = load([logfile_folder, '/log_file.mat']);
%load(logfile_path);


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


%%
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
