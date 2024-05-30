%DeepLearnCC_search_Main

% Flow
%1. Make imds
%2. define Layers
%3. Make [imdsTrain,imdsValidation]
%4  Train and Find best options for layers
%5. Train with increasing data
%6. Integrate learning curve

clear;close all;
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
pn_def = uigetdir(pn_def,'select top folder of deep learning');% change this for each code
save([pn_main '\' fn_datalocation],'pn_def');
%------------------------------------------------------------

%--------------------------------------------------------------------------
%2. define Layers
stride = input('Type stride []=5\n');
if isempty(stride)
    stride = 5;
end
ListFilSize = input('type filtersize in a vector []=5\n');
if isempty(ListFilSize)
    ListFilSize = 5;
end
ListFilNum = [64,128,256,512];
List_train_points_findcondition = 0.99;
learn_rate = 0.0005;
%--------------------------------------------------------------------------
tag_date = datestr(now, 'yyyy-mmdd-HHMM');
yn_plot = 'n';
%--------------------------------------------------------------------------
%　入力と出力フォルダ指定
pn_grandparent = uigetdir(pn_def,'Select pn_parent of image classes');
%id_rand = input('random id for train vs val []=10\n');
%if isempty(id_rand)
    id_rand = 10;
%end
pn_grandgrandparent = fileparts(pn_grandparent);
pn_save_top = [pn_grandgrandparent '\Results_' tag_date '_randTrVal' num2str(id_rand)];
mkdir(pn_save_top);
%--------------------------------------------------------------------------
List_pn_parent = dir(fullfile(pn_grandparent,'SliceOf1Ch*'));
%--------------------------------------------------------------------------
% 学習ポイントの最小データ数決定
pn_ex = [List_pn_parent(1).folder '\' List_pn_parent(1).name];
ListExFiles = dir(fullfile(pn_ex,'*','*.tif'));
C = struct2cell(ListExFiles);
D = C(2,:);
E = categorical(D);
[F, G] = unique(E);
ListN = [G(2:end) - G(1:end-1); numel(E) - G(end-1) + 1];
prc_start = 2*1/min(ListN)/0.3;
List_train_points = [prc_start:0.02:0.9999, 0.9999];%Learning curve data numbers. Should not start from too small number.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% make IMDSs
for id_parent = 1:numel(List_pn_parent)
    %--------------------------------------------------------------------------
    pn_save{id_parent} = [pn_save_top '\', List_pn_parent(id_parent).name '_train_search'];
    if ~exist(pn_save{id_parent},'dir')
        mkdir(pn_save{id_parent});
    end
    %--------------------------------------------------------------------------
    %3　making of imdsTrain, imdsValidation. Subset of them will be used for training curve
    pn_parent = [List_pn_parent(id_parent).folder '\' List_pn_parent(id_parent).name];
    [imds{id_parent}, Labels, NameList, FolderList, LabelList] = make_imds_simple(pn_parent);
    rand ('state', id_rand);% needs to unify across pn_parent loop
    [imdsTrain{id_parent},imdsValidation{id_parent}] = splitEachLabel(imds{id_parent},0.7,'randomized');%
    %--------------------------------------------------------------------------
end
save([pn_save_top, '\IMDS.mat'],'imds','imdsTrain','imdsValidation');
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
yn_search_options = input('Run test learning with various filter size, number of filters y\n','s');
if yn_search_options == 'y'
    parfor id_parent = 1:numel(List_pn_parent)
        %--------------------------------------------------------------------------
        %4. Train All to find the best Layer options   
        [Val, Tr, NetStack] = search_train(imdsTrain{id_parent},imdsValidation{id_parent},ListFilSize,ListFilNum,List_train_points_findcondition,learn_rate,yn_plot,'stride',stride);% train with various optins
        % find best options
        ListBest = find(Val.Accuracy_total == max(max(Val.Accuracy_total)));
        [id_filsize, id_filnumber] = ind2sub([numel(ListFilSize),numel(ListFilNum)],ListBest(randperm(numel(ListBest),1)));% Select para for max accuracy. If multiple bests exist, select one at ramdom.
        List_FilSize_select(id_parent) = ListFilSize(id_filsize);
        List_FilNum_select(id_parent) = ListFilNum(id_filnumber);    
        % make fig and save
        h_search = figure('Name','Val results');
        imagesc(Val.Accuracy_total);colorbar;    xlabel(['Filter Number', num2str(ListFilNum)]);    ylabel(['Filter Size', num2str(ListFilSize)]);
        a=gca;   a.XTick = 1:numel(ListFilNum);    a.YTick = 1:numel(ListFilSize);    colorbar;
        saveas(h_search,[pn_save{id_parent} '\SearchPara.fig'],'fig');
        %--------------------------------------------------------------------------
    end
else
    pn_save_top_load = uigetdir(pn_def,'select Results____ folder to load');
    List_pn_save_load = dir(fullfile(pn_save_top_load,'SliceOf1Ch*_train_search'));
    for id_pn_save = 1:numel(List_pn_save_load)
        pn_save_load{id_pn_save} = [List_pn_save_load(id_pn_save).folder '\' List_pn_save_load(id_pn_save).name];
        copyfile(pn_save_load{id_pn_save},pn_save{id_pn_save});%フォルダの中身をコピー
    end
end
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Select option settings manually if needed
%---------
% open all figures and organize
close all;
for id_fig = 1:numel(pn_save)
    uiopen([pn_save{id_fig} '\SearchPara.fig'],true);
end
pause(1);
h=gcf;List_fig = 1:h.Number;
nColRow = ceil(sqrt(numel(List_fig)));
fig_organizer(List_fig,'nFig_yoko',nColRow,'nFig_tate',nColRow);
%---------
yn_manual_option_select = input('Select Layer option manually y/n \n','s');
if yn_manual_option_select == 'y'
    FilSize_manual = input('type Filesize for all []=5\n');
    if isempty(FilSize_manual)
        FilSize_manual = 5;
    end
    List_FilSize_select = repmat(FilSize_manual,1,numel(List_pn_parent));
    FilNum_manual = input('type FilNum for all []=512\n');
    if isempty(FilNum_manual)
        FilNum_manual = 512;
    end
    List_FilNum_select = repmat(FilNum_manual,1,numel(List_pn_parent));
end
%--------------------------------------------------------------------------


parfor id_parent = 1:numel(List_pn_parent)%5 Train with increasinng data number with selected Layper options
    train_curve(imdsTrain{id_parent},imdsValidation{id_parent},List_FilSize_select(id_parent),List_FilNum_select(id_parent),learn_rate,List_train_points,pn_save{id_parent},yn_plot,'stride',stride);
end

%---------
% open all figures and organize
close all;
for id_fig = 1:numel(pn_save)
    uiopen([pn_save{id_fig} '\TrainCurve.fig'],true);
end
pause(1);
h=gcf;List_fig = 1:h.Number;
nColRow = ceil(sqrt(numel(List_fig)));
fig_organizer(List_fig,'nFig_yoko',nColRow,'nFig_tate',nColRow);
%---------

%6. Integrate learning curve
h_vote = vote_simple(pn_save,List_train_points,tag_date);%remake best trainning curve taking the best P values.
saveas(h_vote, [pn_save_top ,'\Accuracy_vote_finalist' tag_date '.fig'],'fig');
%------------------------------------------------------------------------------
% save codes 
[void, pn_code_last] = fileparts(pn_main);
zip([pn_save_top, '\' pn_code_last '.zip'],pn_main);
%------------------------------------------------------------------------------

