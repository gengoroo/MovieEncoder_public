function [imds, Labels, NameList, FolderList, LabelList] = make_imds_simple(pn_parent)
    % 2024.1.1 Corrected to include child folder that include image
    % immediatly below its foldoer

    %----------------------------------------------------
    FileList = dir(fullfile(pn_parent, '*', '*.tif'));
    data = struct2cell(FileList);
    NameList = data(1,:)';
    FolderList = data(2,:)';
    
    for id_file = 1:numel(FileList)
        [void, LabelList{id_file,1}] = fileparts(FolderList{id_file});
    end
    Labels = categorical(unique(LabelList));

    % corrected 2024.1.1
    LabelsString = string(Labels);
    for id_label = 1:numel(Labels)
        ListPnLabels{id_label} = [pn_parent '/' LabelsString{id_label}];
    end
    %----------------------------------------------------
    %imds = imageDatastore(pn_parent,"FileExtensions",[".jpg",".tif"],"IncludeSubfolders", true,"LabelSource","foldernames");
    imds = imageDatastore(ListPnLabels,"FileExtensions",[".jpg",".tif"],"IncludeSubfolders", true,"LabelSource","foldernames");
    %----------------------------------------------------

end