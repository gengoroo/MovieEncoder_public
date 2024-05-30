%copyfiletag
fprintf('This code copies all files in a folder adding tag to files\n');
clear;
%------------------------------------------------------------
mfn = mfilename('fullpath');
[pn_main, fn_main] = fileparts(mfn);
pn_def = '';
fn_datalocation = [fn_main,'_datalocation.mat'];
if exist([pn_main '\' fn_datalocation],'file')
    load([pn_main '\' fn_datalocation]);
end
if pn_def == 0
    pn_def = '';
end
pn_def = uigetdir(pn_def,'select pn for copysorce');
save([pn_main '\' fn_datalocation],'pn_def');

pn = pn_def;
%------------------------------------------------------------
selector = input('1: merge to PTZxall 2split into PTZuM\n');
%------------------------------------------------------------
switch selector
    case 1
        [pn_parent, tag] = fileparts(pn);
        pn_save = [pn_parent '\merge'];
        mkdir(pn_save);
        ListAvi = dir(fullfile(pn,'*.avi'));
        
        for id_file = 1:numel(ListAvi)
            copyfile([ListAvi(id_file).folder ,'\' ListAvi(id_file).name], [pn_save '\' tag '_' ListAvi(id_file).name]);
        end
%------------------------------------------------------------
%------------------------------------------------------------

    case 2
        pn_top = uigetdir(pn_def,'select pn_top folder');
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


