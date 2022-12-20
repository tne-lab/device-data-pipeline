fileloc='Z:\projmon\virginia-dev\01_EPHYSDATA\dev2218\';
% dayvect={ 'day11_BLA_sham\','day12_RND\','day13_RND\','day14_RND\','day15_RND\','day16_RND\',};
%dayvect={ 'day12_RND\', 'day13_RND\'};
dayvect={'day5_180stim\'};
  
%You can manually enter all of the days to run, or select via GUI by leaving dayvect blank;
if isempty(dayvect)
    d=dir(fileloc);
    subfol={d.name};
    subfol=append(subfol,'/');
    subfol=subfol(contains(subfol,'day'));
    [idx,tf]=listdlg('ListString', subfol);
    dayvect=subfol(idx);

end

reRun=0; %Change to 0 if you don't need to rerun TFR calc
PowPlot=1;  % 0 if don't need the power plots output
CrsPlot=1; % 0 if don't need the cross spectra output
bpdo=0; % 1 if you want it to output the days summary

%%
ffname=cell(1,2);
run={'RAW_PRE', 'RAW_POST'};
for i=1:length(dayvect)
    runfile=char(strcat(fileloc,dayvect(i)));
    [cohfig, avthetaband{i}, avtot,crsfig,pow1fig,pow2fig]=mtmcoh(runfile,PowPlot, CrsPlot, reRun, [1 1 0], 2, 100, 2, '50%'); % You can change last number IF already run with given settings once
    if ~exist([runfile,'/Plots'], 'dir')
        mkdir([runfile,'/Plots'])
    end
    for j=1:2
        ffname{j}=fullfile([runfile,'/Plots/',char(run(j)),'cohspect.jpg']);
        saveas(cohfig{j},ffname{j})
        if PowPlot==1
           ffpow1name{j}=fullfile([runfile,'/Plots/',char(run(j)),'pow1spect.jpg']);
        saveas(pow1fig{j},ffpow1name{j}) 

           ffpow2name{j}=fullfile([runfile,'/Plots/',char(run(j)),'pow2spect.jpg']);
        saveas(pow2fig{j},ffpow2name{j}) 
        end
        if CrsPlot==1
             ffcrsname{j}=fullfile([runfile,'/Plots/',char(run(j)),'crosspect.jpg']);
        saveas(crsfig{j},ffcrsname{j}) 
        end
    end
end

%%

if bpdo==1
    chlabel=[{'BLA1-2/IL1-2';'BLA3-4/IL1-2';'BLA5-6/IL1-2';'BLA7-8/IL1-2';'BLA1-2/IL3-4';'BLA3-4/IL3-4';'BLA5-6/IL3-4';'BLA7-8/IL3-4';'BLA1-2/IL5-6';'BLA3-4/IL5-6';'BLA5-6/IL5-6';'BLA7-8/IL5-6';'BLA1-2/IL7-8';'BLA3-4/IL7-8';'BLA5-6/IL7-8';'BLA7-8/IL7-8'}]; %Manually labeling channel combs


    bp=figure;
    for chcmb=1:16

        col=colormap("parula");
        select=round(linspace(1, length(col)/2, size(dayvect,2)));
        colvect=col(select,:);
        subplot(4,4,chcmb);
        hold on
        y=[0 0 1 1];
        % patch([0.5 1.5 1.5 0.5], y, 'r', 'FaceAlpha', 0.2)
        for i=1:size((dayvect),2)
            x=[(i*2)-1.5 (i*2)+0.5 (i*2)+0.5 (i*2)-1.5];
            patch(x,y, colvect(i), 'FaceAlpha', 0.2)
        end

    end
    %%

    toplot=cell(1,16);
    toBox=cell(1,16);
    grouping=cell(1,16);
    labels={};
    for chanselect=1:16
        grouping{chanselect}=[];
        toBox{chanselect}=[];
        ppvect={'RAW_PRE','RAW_POST'};
        for i=1:length(dayvect)
            for j=1:2
                %             toplot{chanselect}=[toplot{chanselect};avthetaband{1,i}.(char(run(j))).chan{1,chanselect}]; % You might get 'index must not be greater', just change number
                boxval= (avthetaband{1,i}.(char(run(j))).chan{1,chanselect}(~isnan( avthetaband{1,i}.(char(run(j))).chan{1,chanselect}')))';
                toBox{chanselect}=[toBox{chanselect}; boxval];
                mult=((2*(i-1))+(j-1));
                grouping{chanselect}=[grouping{chanselect};ones(length(boxval),1).*mult];
                tolab=split([char((dayvect(i))),' ', char(ppvect(j))],'_');

                %             for k=1:size(toplot(chanselect),1)/2
                %             if median(toplot{chanselect}(k),'omitnan')<median(toplot{chanselect}(k+1),'omitnan')
                %                 incvect

                if j==1
                    labels{i*2+j-2}= char(tolab(1));
                else
                    labels{i*2+j-2}= char({});
                end
            end
        end

        subplot(4,4,chanselect)
        boxplot(toBox{chanselect},grouping{chanselect},'Labels', labels)
        % yline(0.125, 'Color', 'r', 'LineStyle', '--','label', 'Bias', 'FontSize', 8, 'LabelHorizontalAlignment','left','LabelVerticalAlignment','middle')
        yline(0.125, 'Color', 'r', 'LineStyle', '--')

        title(chlabel(chanselect),'FontSize',8)
    end
    bp.Position=[47,266,992,602];

    % sgtitle(['Theta Coherence over Multiple Days for ',ratname])
    %  ff=fullfile([fileloc,'boxplot.jpg']);
    % exportgraphics(bp,ff, 'Resolution', 300)


    %%
    zs=[];

    daynum=0;
    for i=0:2:(size(dayvect,2)*2)-1
        daynum=daynum+1;
        for j=1:16
            %     zs(daynum,j)=(mean(toBox{1, j}  (grouping{1, j}  ==i+1)) - mean( toBox{1, j}  (grouping{1, j}  ==i)))/std( toBox{1, j}  (grouping{1, j}  ==i));
            xpost{daynum,j}=(toBox{1, j}  (grouping{1, j}  ==i+1));
            xpre{daynum,j}=toBox{1, j}  (grouping{1, j}  ==i);
            spost=var(xpost{daynum,j});
            spre=var(xpre{daynum,j});
            meanpre=mean(xpre{daynum,j});
            meanpost=mean(xpost{daynum,j});
            npre=length(xpre{daynum,j});
            npost=length(xpost{daynum,j});


            sp=sqrt(((npost-1)*spost^2+(npre-1)*spre^2)/(npost+npre-2));
            zs(daynum,j)=(meanpost-meanpre)/(sp*sqrt((1/npost)+(1/npre)));
        end
    end
    x=1:size(zs,1);
    figure;
    for i=1:16
        scatter(x,zs(:,i),'filled');
        hold on
    end
    yline(0, 'Color', 'r','LineStyle','--');
    legend(cat(1,chlabel,{'Zero Line'}));
    xticks(x)
    xlabel('Day Number')
    ylabel('T-value POST-PRE')
    grid on

    title('T-value over days by channel comb')
end