function copyfilewithtag_CC(pn_top)

    fprintf('splitting folder to subdivide into Classes\n');
    ListTif = dir(fullfile(pn_top,'SliceOf1Ch*','*','*.tif'));
    ListTifCell = struct2cell(ListTif);
    
    ListPn = ListTifCell(2,:);
    ListFn = ListTifCell(1,:);
    delimeter = strfind(ListFn{1},'_');
    deli = delimeter(1);
    
    Labels = cellfun(@(x) x(1:deli-1),ListFn,'UniformOutput',false);
    for id_file = 1:numel(ListTif)
        pn_copy = [fileparts(ListPn{id_file}),'\' Labels{id_file}];
        if ~exist(pn_copy,'dir')
            mkdir(pn_copy);
        end
        copyfile([ListPn{id_file}, '\' ListFn{id_file}], [pn_copy, '\' ListFn{id_file}]);
    end
    
    for id_file = 1:numel(ListTif)
        if exist(ListPn{id_file},'dir')
            rmdir(ListPn{id_file},'s');
        end
    end
end



