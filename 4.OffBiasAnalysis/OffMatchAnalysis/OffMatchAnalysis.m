% 識別解析
clear;
%------------------------------------------------------------
mfn = mfilename('fullpath');
[pn_main, fn_main] = fileparts(mfn);
fn_datalocation = [fn_main,'_datalocation.mat'];
if exist([pn_main '\' fn_datalocation],'file')
    load([pn_main '\' fn_datalocation]);
end
try
    pn_3Ch = uigetdir(pn_def,'Select CC_var_hyper_3ChStack');
catch
    pn_3Ch = uigetdir('','Select CC_var_hyper_3ChStack');
end
pn_def = pn_3Ch;
save([pn_main '\' fn_datalocation],'pn_def');
%------------------------------------------------------------
fprintf('This code remakes imds.Files, so it works even when data file is moved\n');

%'C:\Users\gengoro\SynologyDrive\Behavior\選別動画\crop2_sel\Rot0.48\Crop2_sel_final_LAPTOP-25N14DPB_2-08-151109-2024_CaseConflict\_Latest_UnifyCC\PTZ[5x7_0x1]_off_v2\DeepLearn__sum_10x10Gri_80x80Pix_e_AllEn25_OffAna\CC_var_hyper_3ChStack';
fn_vote = 'Accuracy_vote_rand10.mat';% made by vote_simple_plot.m
load([pn_3Ch ,'\' fn_vote])
id_pool = numel(ValStack);%最後のセッション

List_right = find(ValMax(id_pool).Classify == Val.imds{id_pool}.Labels);%正しいセッション
List_wrong = find(ValMax(id_pool).Classify ~= Val.imds{id_pool}.Labels);%誤ったセッション
% Val.imds{end}が最後のセッションのサンプルリスト。そのうちList_rightが正解。

Val.imds{id_pool}.Labels;%で正解カテゴリ
ID_correct = grp2idx(Val.imds{id_pool}.Labels);
ListP_val_local = ValStack(id_pool).P;%で　問題数xカテゴリxSliceOfのPがでる。
for ii = 1:numel(ID_correct)
    ListP_correct_val_local(ii,:) = ListP_val_local(ii,ID_correct(ii),:);
end
ListP_correct_right_val_local = ListP_correct_val_local(List_right,:);%  これがY
ListP_correct_wrong_val_local = ListP_correct_val_local(List_wrong,:);%  これがY
%-----------------------------------------------------------------------------------------------------------------
[imds, Labels, NameList, FolderList, LabelList] = make_imds_simple([pn_3Ch '\SliceOf1Ch9']);

for id_val = 1:numel(Val.imds{id_pool}.Files)
    A = strfind(imds.Files,Val.imds{id_pool}.Files{id_val});
    List_ValID_global(id_val) = find(cellfun(@(x) ~isempty(x), A));
end
List_ValID_correct_global = List_ValID_global(List_right);
List_ValID_wrong_global = List_ValID_global(List_wrong);
%-----------------------------------------------------------------------------------------------------------------
%GC解析
pn_CC = uigetdir(fileparts(pn_3Ch),'select pn_CC');
fn_hyper = 'CC_hyper_stack.mat';
load([pn_CC, '\' fn_hyper]);

%GCデータはCC_allcut.matに入っている。
id_cut  =2;
for id_data = 1:numel(ListSliceSel_stack)
    Order_dOFF(:,:,id_data) = ListSliceSel_stack{id_data}(:,:,id_cut);
end
imsize = [size(Order_dOFF,1),size(Order_dOFF,2)];
mask = createCirclesMask(imsize, ceil(imsize/2), floor(imsize(1)/2));

Order_dOFF_trim = Order_dOFF.*repmat(mask,1,1,size(Order_dOFF,3));
for id_data = 1:size(Order_dOFF_trim,3)
    histtemp = hist(reshape(Order_dOFF_trim(:,:,id_data),[],1),0:9);
    SelectRatio_global(id_data,:) = histtemp(2:end)/sum(histtemp(histtemp>=2));
    BestSliceOfdGC{id_data,1} = find(max(SelectRatio_global(id_data,:)) == SelectRatio_global(id_data,:));
    LeastSliceOfGC{id_data,1} = find(min(SelectRatio_global(id_data,:)) == SelectRatio_global(id_data,:));
end
SelectRatio_val_local_right = SelectRatio_global(List_ValID_correct_global,:);%　これがX
SelectRatio_val_local_wrong = SelectRatio_global(List_ValID_wrong_global,:);%　これがX
%-----------------------------------------------------------------------------------------------------------------
% Speaman rank correlation coefficnent
clear pearson_corr{id_subplot};
h_speaman = figure('Name','Speaman_rank_corr_dGC vs P rank','Color','w');
for id_subplot = 1:2
    subplot(1,2,id_subplot);hold on
    switch id_subplot
        case 1
            title('correct samples')
            SelectRatio_val_local = SelectRatio_val_local_right;
        case 2
            title('wrong samples')
            SelectRatio_val_local = SelectRatio_val_local_wrong;
    end
    for id_test = 1:size(SelectRatio_val_local,1)
        x1 = SelectRatio_val_local(id_test,:);
        x2 = ListP_correct_right_val_local(id_test,:);
        temp = corr([x1',x2'],'Type','spearman');
        pearson_corr{id_subplot}(id_test) = temp(1,2);
        %plot(id_test,pearson_corr{id_subplot}(1,2,id_test),'k.');
        %plot(1+normrnd(0,1/8),pearson_corr{id_subplot}(id_test),'k.');
    end
    swarmchart(repmat(1,1,numel(pearson_corr{id_subplot})),pearson_corr{id_subplot},'MarkerEdgeColor','k');

    a=gca;a.YLim = [-1 1];a.XLim = [0 2];
    data_corr = reshape(pearson_corr{id_subplot},[],1);
    median_corr = median(data_corr);
    mean_corr = mean(data_corr);
    prc25 = prctile(data_corr,25);
    prc75 = prctile(data_corr,75);
    plot(1, median_corr, '+', 'LineWidth',2, 'Color','k','MarkerSize',10)
    errorbar(1,median_corr, prc25 - median_corr, median_corr - prc75, 'LineWidth',2, 'Color','k');
    std_corr = std(data_corr);
    d = mean_corr/std_corr;
    text(a.XLim(2)*0.8,median_corr*2, ['d=' num2str(d)]);
    [p, h] = signrank(reshape(pearson_corr{id_subplot},[],1));
    %plot(a.XLim,[median_corr median_corr],'g--');
    plot(a.XLim,[0 0],'k--');
    text(a.XLim(2)*0.8,median_corr*1.2, ['p sigrank=' num2str(p)]);
    a.LineWidth = 2;a.TickLength(1) = 0.02;a.FontSize=14;
    a.YLabel.String = 'Spearman rank corr';
end
pn_save = [pn_3Ch '\OffMatchAna'];
mkdir(pn_save);
saveas(h_speaman,[pn_save '\' h_speaman.Name '.fig'],'fig');
mfn = mfilename('fullpath');
[pn_main, fn_main] = fileparts(mfn);
[void, pn_code_last] = fileparts(pn_main);
zip([pn_save, '\' pn_code_last '.zip'],pn_main);
%-----------------------------------------------------------------------------------------------------------------
yn_make_GC_SliceOf = input('make SliceOf1Ch_GCBest y/n','s');
if yn_make_GC_SliceOf == 'y'
    ListPnSliceOf = dir(fullfile(pn_3Ch,'SliceOf1C*'));
    pn_GC_top = [pn_3Ch, '\SliceOf1Ch_GCBest'];
    if ~exist('ListPnSliceOf','dir')
        mkdir(pn_GC_top);
    end
    for id_file = 1:numel(imds.Files)
        [pn, fn, ext] = fileparts(imds.Files{id_file});
        [~, pn_label] = fileparts(pn);
    
        id_select = min(BestSliceOfdGC{id_file,1});
        pn_source = [pn_3Ch '\' ListPnSliceOf(id_select).name '\' pn_label];
    
        pn_target = [pn_GC_top '\' pn_label];
        if ~exist(pn_target,'dir')
            mkdir(pn_target);
        end
        
        copyfile([pn_source '\' fn, ext], [pn_target '\' fn '_of' num2str(id_select) , ext]);
    end
end
