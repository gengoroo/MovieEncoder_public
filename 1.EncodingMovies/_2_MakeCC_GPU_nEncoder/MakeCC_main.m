%MakeCC_main
% 2023.12.21 f_Make_hyper_CC_var3X3_rev2_f1
clear;
fprintf('variants cleared\n');
fprintf('Select a folder contaaining 600ms movies, type enter for all selections\n');
%------------------------------------------------------------
mfn = mfilename('fullpath');
[pn_main, fn_main] = fileparts(mfn);
fn_datalocation = [fn_main,'_datalocation.mat'];
if exist([pn_main '\' fn_datalocation],'file')
    load([pn_main '\' fn_datalocation]);
end
try
    pn_crop2 = uigetdir(pn_def,'select crop2 folder');
catch
    pn_crop2 = uigetdir('','select crop2 folder');
end
pn_def = pn_crop2;
save([pn_main '\' fn_datalocation],'pn_def');
%------------------------------------------------------------

sel_start = input('start= 1 or []:f_MakeMovieFilterSeq3x3_cube_GPU_nEncoder 2:f_Make_hyper_CC_var3X3_rev2_f1 3:f_Write_hyper_CC_var3x3x3Ch 4:TiffStackChanger 5:Single_neuron_CC 6:Single_neuron_shift \n');
if isempty(sel_start)
    sel_start = 1;
end
if sel_start <=4
    [void, pn_label] = fileparts(pn_crop2);
    fprintf('pn_label for 3Ch folder is %s\n',pn_label);


    List = dir(fullfile(pn_crop2,'*avi'));
    vidObj = VideoReader([pn_crop2 '\' List(1).name]);
    Size_movie = [vidObj.Height, vidObj.Width, vidObj.BitsPerPixel];
    %fprintf('Movie size is %s\n',num2str(Size_movie));
end

if sel_start <=1

        tag_RFMap = [];
        yn_flip_T = input('flip ON-OFF sequence in filter? y/n []=n','s');
        if isempty('yn_flip_T')
            yn_flip_T = 'n';
        end
        yn_invert_IM = input('invert image pixel intensity in filter? y/n []=n','s');
        if isempty('yn_invert_IM')
            yn_invert_IM = 'n';
        end
        yn_RFMap = input('Select RFMap y/n  []=n \n','s');
        if yn_RFMap == 'y'
            if ~exist('pn_RFmap_def','var')
                pn_RFmap_def = pn_def;
            end
            [fn_RFMap_SOM, pn_RFmap_SOM] = uigetfile(pn_RFmap_def,'select DataBase of RFMap');
            fn_full_RFMap = [pn_RFmap_SOM, fn_RFMap_SOM];
            pn_RFmap_def = pn_RFmap_SOM;
            save([pn_main '\' fn_datalocation],'pn_def','pn_RFmap_def');

            select_tag = input('tag 1:SIFT 2:RFadj (natural RF rescaled by SIFT) 3: type manual\n');
            switch select_tag
                case 1
                    tag_RFMap = 'SIFT';
                case 2
                    tag_RFMap = 'RFadj';
                case 3
                    tag_RFMap = input('Any tag words\n','s');
            end
            load(fn_full_RFMap);
            
            %fprintf('RFMap size is %s\n',num2str(Size_RFMap));
        else
            fn_full_RFMap = '';
        end

        SideEncoder_input = [];
        if yn_RFMap == 'y'
            % 2024.02.02
            fprintf('Movie size is %s\n',num2str(Size_movie));
            if isfield(DataBase{1}.input,'SideEncoder')
                SideEncoder = DataBase{1}.input.SideEncoder;
            else
                SideEncoder10 = Size_movie(1:2)/10;
                fprintf('To make 10x10 grids SideEncoder is %s\n',num2str(SideEncoder10));
                SideEncoder = input('Type SideEncoder [  ,  ] [] for take above\n');
                if isempty(SideEncoder)
                    SideEncoder = SideEncoder10;
                end
            end
            fprintf('RFMap size is %s\n',num2str(SideEncoder)); 
            nSection_best = floor(Size_movie(1:2)./SideEncoder);
            fprintf('Recommended nSection for artRF is size movie/RF = [%d, %d]\n', nSection_best(1), nSection_best(2));
            SideEncoder_input = input(['Type RFMap size pix [ ,  ]  []= ' num2str(SideEncoder(1:2)) '\n']);
            if isempty(SideEncoder_input)
                SideEncoder_input = SideEncoder;
            end
            nSection = floor(Size_movie(1:2)./SideEncoder_input);

        else
            nSection = input('Type nSection [ ,  ] as nGrid of encoder []= [10, 10] \n');
            if isempty(nSection)    
                nSection = [10, 10];%2023.12.18 added
                SideEncoder_input = Size_movie(1:2)./nSection;
            end
        end

        id_cc_mode = input('1: sum of CC 2: max of CC 3:3Dcc[]=1\n');%2023.12.21
        if isempty(id_cc_mode)
            id_cc_mode = 1;
        end
        switch id_cc_mode
            case 1
                cc_mode = 'sum';
            case 2
                cc_mode = 'max';
            case 3
                cc_mode = '3Dcc';
        end
        tag = [tag_RFMap, '_' cc_mode];
        [pn_CC, tag] = f_MakeMovieFilterSeq3x3_cube_GPU_nEncoder(pn_crop2,'yn_flip_T',yn_flip_T,'yn_invert_IM',yn_invert_IM,'fn_full_RFMap',fn_full_RFMap,'tag',tag,'cc_mode',cc_mode,'nSection',nSection,'SideEncoder',SideEncoder_input);

end
if sel_start <=2
        fn_full_CC_hyper_stack = f_Make_hyper_CC_var3X3_rev2_f1(pn_CC,'yn_skip_fig','y');
end
if sel_start <=3
    if ~exist('fn_full_CC_hyper_stack','var')
        [fn_temp, pn_temp] = uigetfile(pn_CC,'Select CC_hyper_stack.mat');
        fn_full_CC_hyper_stack = [pn_temp,'\',fn_temp];
    end
    f_Write_hyper_CC_var3x3x3Ch(fn_full_CC_hyper_stack);
end
if sel_start <=4
    pn_export_3Ch = [fileparts(pn_crop2) ,'\DeepLearn', tag];
    mkdir(pn_export_3Ch);

    List3Ch = dir(fullfile(pn_CC,'*_3ChStack'));
    for id_3Ch = 1:numel(List3Ch)
        pn_3ch = [List3Ch(id_3Ch).folder '\' List3Ch(id_3Ch).name];
        fprintf('Reorganizing %s\n',List3Ch(id_3Ch).name);
        pn_output = f_TiffStackChanger(pn_3ch,'pn_label',pn_label,'pn_export_3Ch',pn_export_3Ch);

        list_pn_all = dir(fullfile(pn_output,'SliceOf1Ch1','*'));
        if numel(list_pn_all) == 3 % if only 1 subfolder
            copyfilewithtag_CC(pn_output);
        end
    end
end

if sel_start ==5
    addpath([pn_main,'\Make_Single_imds_from_mat']);
    Make_single_imds_from_CC_hyper_stack;
end

if sel_start ==6
    addpath([pn_main,'\Make_Single_imds_from_mat']);
    Make_single_var_imds_from_CC_hyper_stack;
end