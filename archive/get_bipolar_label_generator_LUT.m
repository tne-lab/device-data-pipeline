function newlabels = get_bipolar_label_generator_LUT(rat_struct, n, m)

if isfield(rat_struct, 'rmILchanidx')
    
    if ~isempty(rat_struct.rmILchanidx)
        
        ch = getfield(rat_struct, 'rmILchanidx');
        
        nCH = 1;
        
        for i = 1:4
            if ~ismember(ch, [2*i-1, 2*i])        
                newlabelsIL{nCH,1} = ['IL ', num2str(i)];
                nCH = nCH +1;
            end
        end
        
    elseif isempty(rat_struct.rmILchanidx)
        
        for i = 1:4
            newlabelsIL{i,1} = ['IL ', num2str(i)];
        end
       
    end
    
else
    
    %so if it doesn't have the field, either a full pair of single-ended
    %electrodes have been removed, or all electrodes are there. 
    
%     
%     %check if all IL channels are there:
% %     if sum(n) <8
        
        master_chans2plot_labels = getMaster_chans2plot_labels('bipolar'); 
        LUT_labels = reshape(repmat(master_chans2plot_labels, 1, 2)', 16,1);

        newlabelsIL = unique(LUT_labels(n));
    
    
    
% %         for i = 1:4
% %             newlabelsIL{i} = ['IL ', num2str(i)];
% %         end
end




if isfield(rat_struct, 'rmBLAchanidx')
    
    if ~isempty(rat_struct.rmBLAchanidx)
        
        ch = getfield(rat_struct, 'rmBLAchanidx');
        
        nCH = 1;
        
        for i = 1:4
            if ~ismember(ch, [2*i-1, 2*i])        
                newlabelsBLA{nCH,1} = ['BLA ', num2str(2*i-1) , ' - BLA ', num2str(2*i)];
                nCH = nCH +1;
            end
        end
        
    elseif isempty(rat_struct.rmBLAchanidx)
        
        
        for i = 1:4
            newlabelsBLA{i,1} = ['BLA ', num2str(2*i-1) , ' - BLA ', num2str(2*i)];
        end
        
    end
    
else
    
    master_chans2plot_labels = getMaster_chans2plot_labels('bipolar');
    LUT_labels = reshape(repmat(master_chans2plot_labels, 1, 2)', 16,1);
    
    newlabelsBLA = unique(LUT_labels(m));
    
    
    %     for i = 1:4
%         newlabelsBLA{i} = ['BLA ', num2str(i)];
%     end
    
end


newlabels = [newlabelsIL; newlabelsBLA];

    
    
    

