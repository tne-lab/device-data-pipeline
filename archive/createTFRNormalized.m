function createTFRNormalized(path, connect_pre_folder, TFR_connect_pre, TFR_coherence)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Mark Schaza @ TNEL 2020
% Function that is given two TFRs containing coherence data. The data is
% normalized by the TFR_connect_pre coherence. Currently only supports z
% score.
%
% Inputs
%   - path: folder that file is located in
%   - connect_pre_folder: folder that the TFR_connect_pre is from
%   - TFR_connect_pre: TFR struct of baseline coherence
%   - TFR_coherence: TFR struct of coherence of data

% Returns
%   - Void: TFR files are created in the folder with the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Connect_z_TFR={};
clear Basemean BasemeanA BasemeanBase Basestd BasestdA BasestdBase S0 S1
% Prestim normalization
S0=size(TFR_connect_pre.powspctrm);
%S0=size(TFR_connect_pre.cohspctrm);
%trialsize_Pre=S0(1);
%channelsize_Pre=S0(2);
%freqsiz_Pre=S0(3);
timesize_Pre=S0(4);

% Actual trial
S1=size(TFR_coherence.powspctrm);
%S1=size(TFR_coherence.cohspctrm);
%trialsize=S1(1);
%channelsize=S1(2);
%freqsize=S1(3);
timesize=S1(4);


% Take our baseline TFR and average it across all trials. Get one value for
% each timepoint
Basemean=nanmean(TFR_connect_pre.powspctrm,4); 
Basestd=nanstd(TFR_connect_pre.powspctrm,0,4);
%Basemean=nanmean(TFR_connect_pre.cohspctrm,4);
%Basestd=nanstd(TFR_connect_pre.cohspctrm,0,4);

% Expand the average TFR to match the dimension for calculation
BasemeanA = repmat(Basemean,[1 1 1 timesize]);
BasestdA = repmat(Basestd,[1 1 1 timesize]);
%BasemeanA = Basemean;
%BasestdA = Basestd;

% Prestim
%BasemeanBase = repmat(Basemean,[1 1 1 timesize_Pre]);
%BasestdBase = repmat(Basestd,[1 1 1 timesize_Pre]);

% % DB
powspctrmA=10*log10((TFR_coherence.powspctrm./BasemeanA));
% powspctrmA=10*log10((TFR_coherence.cohspctrm./BasemeanA));
% powspctrmBase=10*log10(TFR_pre.powspctrm./BasemeanBase);

Connect_dB_TFR = TFR_coherence;
Connect_dB_TFR.powspctrm=powspctrmA;
save ([path, 'TFR_dB_',connect_pre_folder,'.mat'],'Connect_dB_TFR','-v7.3');

% Calculate the Z score 
powspctrmA=(TFR_coherence.powspctrm-BasemeanA)./BasestdA;
%powspctrmA=(TFR_coherence.cohspctrm-BasemeanA)./BasestdA;

Connect_z_TFR = TFR_coherence;
Connect_z_TFR.powspctrm=powspctrmA;
save ([path, 'TFR_z_',connect_pre_folder,'.mat'],'Connect_z_TFR','-v7.3');

end