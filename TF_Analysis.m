function TFData=TF_Analysis(chunked_voltdata,params)

arguments
    chunked_voltdata=[];
    params.TFRwin=2;
    params.tapsmofrq=2;
    params.toi='50%';
    params.cuttime=10;
end

%% Searching for previous TFR analysis, otherwise performing TFR

try
    TFR_chunked=load( 'where the data path will be');
catch
    cfg=[];  % Set TFR config settings
    cfg.foi=0.5:0.5:30;
    cfg.taper='dpss';
    cfg.tapsmofrq=tapsmofrq;
    cfg.output=('powandcsd');
    cfg.channelcmb = {'BLA*'  'IL*'};
    cfg.method='mtmconvol';
    cfg.t_ftimwin=ones(length(cfg.foi),1)*TFRwin; % half a second sliding window
    cfg.pad = 'nextpow2';
    cfg.keeptrials='yes';

    cfg.toi=params.toi;
    TFR_chunked=ft_freqanalysis(cfg, chunked_voltdata);
    save( 'filename', TFR_chunked)
end

%% Generating coherence/power/cross structures
for i=1:size(TFR_chunked.crsspctrm,1)
    for chcmb=1:16
        pow1.trial{i}.chcmb{chcmb}=squeeze(TFR_chunked.powspctrm (i, chpow1(chcmb), :,:));
        curpow1=pow1.trial{i}.chcmb{chcmb};
        pow2.trial{i}.chcmb{chcmb}=squeeze(TFR_chunked.powspctrm (i, chpow2(chcmb), :,:));
        curpow2=pow2.trial{i}.chcmb{chcmb};
        cross.trial{i}.chcmb{chcmb}=squeeze(TFR_chunked.crsspctrm (i, (chcmb), :,:));
        curcross=cross.trial{i}.chcmb{chcmb};
        coh.trial{i}.chcmb{chcmb}=((abs(curcross)).^2)./(curpow1.*curpow2);  % Magnitude squared coherence
    end
end

%% Creating TFData stucture

TFData.TFR=TFR_chunked;
TFData.coh=coh;
TFData.pow1=pow1;
TFData.pow2=pow2;
TFData.cross=cross;