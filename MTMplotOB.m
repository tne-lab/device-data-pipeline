reRun=1;
fileloc='F:\2022_OB_Rats_Closed_Loop\Rat_OB58_CL\';
ratname='OB58';


run={'RAW_PRE', 'RAW_POST'};
dayvect={};
if isempty(dayvect)
d=dir(fileloc);
subfol={d.name};
subfol=append(subfol,'/');
subfol=subfol(contains(subfol,ratname));
[idx,tf]=listdlg('ListString', subfol);
dayvect=subfol(idx);

end


for i=1:length(dayvect)
    runfile=char(strcat(fileloc,dayvect(i)));
    [fig, avthetaband{i}, avtot]=mtmcoh(runfile,[1 1 0], 2, 300, 2, '50%', reRun); % You can change last number IF already run with given settings once
    if ~exist([runfile,'/Plots'], 'dir')
        mkdir([runfile,'/Plots'])
    end
    for j=1:2
ffname{j}=fullfile([runfile,'/Plots/',char(run(j)),'spect2.jpg']);
saveas(fig{j},ffname{j})
    end  
end