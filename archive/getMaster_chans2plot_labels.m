function master_chans2plot_labels = getMaster_chans2plot_labels(reref_select)


if strcmpi(reref_select, 'car')
    
    cmb=1;
    for i = 1:8 %BLA channels
        for j = 1:8 %IL channels
            master_chans2plot_labels{cmb,1} = ['IL ', num2str(j), ' - BLA ', num2str(i)];
            cmb = cmb+1;
        end
    end
    % master_chans2plot_data = cell( cmb-1 , nConditions);
    clear cmb
    
elseif strcmpi(reref_select, 'bipolar')
    
    cmb = 1;
    for i = 1:2:8
        master_chans2plot_labels{cmb,1} = ['IL ', num2str(i), ' - IL ', num2str(i+1)];
        cmb = cmb+1;
    end
    
    
    for j= 1:2:8
         master_chans2plot_labels{cmb,1} = ['BLA ', num2str(j), ' - BLA ', num2str(j+1)];
         cmb = cmb+1;
    end
    
      clear cmb
      
      
elseif strcmpi(reref_select, 'not_applicable')
    
    cmb = 1;
    for i = 1:8
        master_chans2plot_labels{cmb,1} = ['IL ', num2str(i)];
        cmb = cmb+1;
    end
    
    
    for j= 1:8
        master_chans2plot_labels{cmb,1} = ['BLA ', num2str(j)];
        cmb = cmb+1;
    end
    
    clear cmb
    
end