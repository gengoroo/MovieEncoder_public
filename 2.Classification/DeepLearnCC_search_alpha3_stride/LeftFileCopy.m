%LeftFileCopy
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
pn_def = uigetdir(pn_def,'select grandparent folder of source files');% change this for each code
save([pn_main '\' fn_datalocation],'pn_def');
%------------------------------------------------------------

[fn_exc, pn_exc] = uigetfile(pn_def,'select exc file');
load([pn_exc '\' fn_exc]);

yn_continue = 'y';
while (yn_continue == 'y')
    pn_top_soruce = uigetdir(pn_def,'select top pn for source');
    [imds, Labels, NameList, FolderList, LabelList] = make_imds_simple(pn_top_soruce);

    if exist('ListLeft','var')
        ListCopy = ListLeft{end};
    else
        fprintf('making ListCopy from exc\n');
        ListCopy = 1:numel(imds.Labels);
        for ii = 1:numel(exc)
            ListCopy(exc{ii}) = [];
        end
    end

    pn_save_top = uigetdir('C:\Users\gengoro\Desktop\sel2SandBox\movie_all\DeepLearn\CC_var_hyper_3ChStack\DataSetEq','select place to make pn_save');
    [~ ,pn_top_target] =  fileparts(pn_top_soruce);
    pn_save = [pn_save_top '\' pn_top_target];
    mkdir(pn_save);
    
    ListAllFiles = imds.Files;
    
    for id_file = 1:numel(ListCopy)
        fn_source_full = ListAllFiles{ListCopy(id_file)};
        [~, fn_temp, ext] = fileparts(fn_source_full);
        fn = [fn_temp, ext];
        [~, pn_label] = fileparts(fileparts(fn_source_full));
        pn_save_label = [pn_save '\' pn_label];
        if ~exist(pn_save_label,'dir')
            mkdir(pn_save_label);
        end
        copyfile(fn_source_full, [pn_save_label, '\' fn]);
    end
    yn_continue = input('continue y/n','s')';
end