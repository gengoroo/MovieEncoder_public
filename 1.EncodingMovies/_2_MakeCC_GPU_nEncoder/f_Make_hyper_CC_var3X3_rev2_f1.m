% Make_hyper_CC_var3x3
% シフトを３ｘ３種類行い、それぞれでclassifyをしてvoteする

function fn_full_CC_hyper_stack = f_Make_hyper_CC_var3X3_rev2_f1(pn_CC,varargin)

    yn_skip_fig = 'n';
    for ii = 1:nargin-1
        if strcmp(varargin{ii},'yn_skip_fig')
            yn_skip_fig = varargin{ii+1};
        end
    end

    nCh = 3;
    y_margin = 1;% for cube
    x_margin = 1;% for cube
    
    if ~exist('pn_im_stack','var')
        pn_def = 'Z:\';
        %pn_select = uigetdir(pn_def,'Select top folder containing many CC data');
        FileList = dir(fullfile(pn_CC,'*crop*crop*'));
        if isempty(FileList)%クロップしていない場合全て選択
            FileList = dir(fullfile(pn_CC,'*'));
            FileList(2) = [];
            FileList(1) = [];
        end
        clear ListDir;
        for ii = 1:numel(FileList)
            ListDirYN(ii) = FileList(ii).isdir;
        end
        ListDirID = find(ListDirYN==1);
        clear ListDir
        for ii = 1:numel(ListDirID)
            ListDir{ii} = strcat(pn_CC, '\', FileList(ListDirID(ii)).name);
            fprintf('%d: %s\n',ii,FileList(ListDirID(ii)).name);
        end
        %ListDirSelect = input('Select Dir List to calc CC\n');
        ListDirSelect = 1:numel(ListDir);% select all folder automatic
        pn_im_stack = ListDir(ListDirSelect);
        %tag = input('type tag\n','s');
        tag = '';
    end
    
    note = '';
    List_pn_wo_CC_allCut={};
    for id_dataset = 1:numel(pn_im_stack)
        fprintf('%d out of %d \n',id_dataset,numel(pn_im_stack));
        fn_CC_allcut_full = strcat(pn_im_stack{id_dataset},'\CC_allcut.mat');

        if ~exist(fn_CC_allcut_full,'file')
            List_pn_wo_CC_allCut = [List_pn_wo_CC_allCut; pn_im_stack{id_dataset}];
        else
            load(fn_CC_allcut_full);
            if exist('dOFFvsON','var')%2024.02.03
                ListSliceSel = select_SliceOf(dOFFvsON);
            end

            nDim1 = size(CC_allcut,1);
            nDim2 = size(CC_allcut,2);
            nCell = size(CC_allcut,3);

            nCut = size(CC_allcut,4);
            nSideCell = sqrt(nCell);% It has to be squre of something
    
            CC_stack{id_dataset} = CC_allcut(:,:,:,1:end);% cell,id_cut
            CC_var_stack{id_dataset} = CC_allcut_var(:,:,:,:,1:end);% cell,shift,id_cut
            
            % For revhyper  ---------------------------------------------------
            for id_cut = 1:nCut
                for id_tate_unit = 1:nSideCell
                    for id_yoko_unit = 1:nSideCell
                        id_cell = nSideCell*(id_tate_unit-1) + id_yoko_unit;
                        ListTate = nDim1*(id_tate_unit-1)+1:nDim1*id_tate_unit;
                        ListYoko = nDim2*(id_yoko_unit-1)+1:nDim2*id_yoko_unit;
                        CC_rev_hyper(ListTate,ListYoko,id_cut) = CC_allcut(:,:,id_cell,id_cut);

                        for id_shift = 1:size(CC_allcut_var,4)
                            ListTate = (nDim1-y_margin)*(id_tate_unit-1)+1:(nDim1-y_margin)*id_tate_unit;
                            ListYoko = (nDim2-x_margin)*(id_yoko_unit-1)+1:(nDim2-x_margin)*id_yoko_unit;
                            CC_var_rev_hyper(ListTate,ListYoko,id_shift,id_cut) = CC_allcut_var(:,:,id_cell,id_shift,id_cut);% var version
                            CCoff_var_rev_hyper(ListTate,ListYoko,id_shift,id_cut) = CCoff_allcut_var(:,:,id_cell,id_shift,id_cut);%2024.02.04
                        end

                        if exist('ListSliceSel','var')%2024.02.04
                            id_shift_offmatch = ListSliceSel(id_tate_unit,id_yoko_unit,id_cut);
                            CC_var_rev_hyper_offmatch(ListTate,ListYoko,id_cut) = CC_allcut_var(:,:,id_cell,id_shift_offmatch,id_cut);
                        end
                        % new --------------------------------------------------
                        for id_shift_set = 1:size(CC_var_rev_hyper,3)/nCh % find 2 shifts that give maxsumCC New
                            sum_cc_search(id_shift_set) = sum(sum(sum(sum(CC_var_rev_hyper(:,:,(nCh*id_shift_set-1):nCh*id_shift_set,id_cut),1),2),3),4);
                        end
                        id_min_set = find(sum_cc_search == min(sum_cc_search));
                        id_max_set = find(sum_cc_search == max(sum_cc_search));
                        %id_min_set = 1;
                        if isempty(id_min_set)
                            id_min_set = 1;
                        end
                        if isempty(id_max_set)
                            id_max_set = 1;
                        end
                        CC_var_rev_hyper_min(ListTate,ListYoko,:,id_cut) = CC_var_rev_hyper(ListTate,ListYoko,id_min_set*nCh-1:(id_min_set)*nCh,id_cut);
                        CC_var_rev_hyper_max(ListTate,ListYoko,:,id_cut) = CC_var_rev_hyper(ListTate,ListYoko,id_max_set*nCh-1:(id_max_set)*nCh,id_cut);
                        % new --------------------------------------------------
                    end
                end
                data = CCoff_var_rev_hyper(:,:,:,id_cut);
                data(isnan(data)) = 0;
                ListCCoff = reshape(sum(sum(data,2),1),[],1);%2024.02.07 CC_offの最大値を与えるもの
                id_shift_maxoffcc = min(find(ListCCoff == max(ListCCoff)));%2024.02.07
                CC_var_rev_hyper_maxoffcc(:,:,id_cut) = CC_var_rev_hyper(:,:,id_shift_maxoffcc,id_cut);%2024.02.07

                if yn_skip_fig ~= 'y'
                    h_hr(id_cut) = figure('Name',strcat('movie spectrum var_rev_hyper_min', note, ' cut', num2str(id_cut)),'Color','w');hold on;
                    im_disp = CC_var_rev_hyper_min(:,:,:,id_cut);
                    im_disp(:,:,3) = zeros([size(im_disp,1),size(im_disp,2)]);
                    imagesc(im_disp(:,:,1));
                    a=gca; a.XLim=[0.5 size(CC_rev_hyper,2)+0.5];a.YLim=[0.5 size(CC_rev_hyper,1)+0.5];
                    saveas(h_hr(id_cut),strcat(pn_im_stack{id_dataset},'\', h_hr(id_cut).Name ,'.fig'),'fig');
                    close(h_hr(id_cut));
        
                    h_hr(id_cut) = figure('Name',strcat('movie spectrum var_rev_hyper_max', note, ' cut', num2str(id_cut)),'Color','w');hold on;
                    im_disp = CC_var_rev_hyper_max(:,:,:,id_cut);
                    im_disp(:,:,3) = zeros([size(im_disp,1),size(im_disp,2)]);
                    imagesc(im_disp(:,:,1));
                    a=gca; a.XLim=[0.5 size(CC_rev_hyper,2)+0.5];a.YLim=[0.5 size(CC_rev_hyper,1)+0.5];
                    saveas(h_hr(id_cut),strcat(pn_im_stack{id_dataset},'\', h_hr(id_cut).Name, '.fig'),'fig');
                    close(h_hr(id_cut));
                end

            end
            % For revhyper  ---------------------------------------------------
    
            % for hyper -------------------------------------------------------
            for id_cut = 1:nCut
                for id_cell = 1:nCell
                        start_dim1 = rem(id_cell, nSideCell)+1;
                        start_dim2 = ceil(id_cell/nSideCell);
                        ListTate = start_dim1:nSideCell:nDim1*nSideCell;
                        ListYoko = start_dim2:nSideCell:nDim2*nSideCell;
                        CC_hyper(ListTate,ListYoko,id_cut) = CC_allcut(:,:,id_cell,id_cut);
                        for id_shift = 1:size(CC_allcut_var,4)
                            ListTate = start_dim1:nSideCell:(nDim1-y_margin)*nSideCell;
                            ListYoko = start_dim2:nSideCell:(nDim2-x_margin)*nSideCell;
                            CC_var_hyper(ListTate,ListYoko,id_shift,id_cut) = CC_allcut_var(:,:,id_cell,id_shift,id_cut);% var version
                            CCoff_var_hyper(ListTate,ListYoko,id_shift,id_cut) = CCoff_allcut_var(:,:,id_cell,id_shift,id_cut);%2024.02.04
                        end
                        if exist('ListSliceSel','var')%2024.02.04
                            id_shift_offmatch = ListSliceSel(id_tate_unit,id_yoko_unit,id_cut);
                            CC_var_hyper_offmatch(ListTate,ListYoko,id_cut) = CC_allcut_var(:,:,id_cell,id_shift_offmatch,id_cut);
                        end
                        % new --------------------------------------------------
                        for id_shift_set = 1:size(CC_var_hyper,3)/nCh % find 3 shifts that give maxsumCC New
                            sum_cc_search(id_shift_set) = sum(sum(sum(sum(CC_var_hyper(:,:,(nCh*id_shift_set-1):nCh*id_shift_set,id_cut),1),2),3),4);
                        end

                        id_min_set = find(sum_cc_search == min(sum_cc_search));
                        id_max_set = find(sum_cc_search == max(sum_cc_search));
                        %id_min_set = 1;
                        if isempty(id_min_set)
                            id_min_set = 1;
                        end
                        if isempty(id_max_set)
                            id_max_set = 1;
                        end

                        CC_var_hyper_min(ListTate,ListYoko,:,id_cut) = CC_var_hyper(ListTate,ListYoko,id_min_set*nCh-1:(id_min_set)*nCh,id_cut);
                        CC_var_hyper_max(ListTate,ListYoko,:,id_cut) = CC_var_hyper(ListTate,ListYoko,id_max_set*nCh-1:(id_max_set)*nCh,id_cut);

                        % new -------------------------------------------------
                end
                data = CCoff_var_hyper(:,:,:,id_cut);
                data(isnan(data)) = 0;
                ListCCoff = reshape(sum(sum(data,2),1),[],1);%2024.02.07 CC_offの最大値を与えるもの
                id_shift_maxoffcc = min(find(ListCCoff == max(ListCCoff)));%2024.02.07
                CC_var_hyper_maxoffcc(:,:,id_cut) = CC_var_hyper(:,:,id_shift_maxoffcc,id_cut);%2024.02.07

                if yn_skip_fig ~= 'y'
                    h_h(id_cut) = figure('Name',strcat('movie spectrum var_hyper_min', note, ' cut', num2str(id_cut)),'Color','w');hold on;
                    im_disp = CC_var_hyper_min(:,:,:,id_cut);
                    im_disp(:,:,3) = zeros([size(im_disp,1),size(im_disp,2)]);
                    imagesc(im_disp(:,:,1));
                    a=gca; a.XLim=[0.5 size(CC_rev_hyper,2)+0.5];a.YLim=[0.5 size(CC_rev_hyper,1)+0.5];
                    saveas(h_h(id_cut),strcat(pn_im_stack{id_dataset},'\', h_h(id_cut).Name, '.fig'),'fig');
                    close(h_h(id_cut));
        
                    h_h(id_cut) = figure('Name',strcat('movie spectrum var_hyper_max', note, ' cut', num2str(id_cut)),'Color','w');hold on;
                    im_disp = CC_var_hyper_max(:,:,:,id_cut);
                    im_disp(:,:,3) = zeros([size(im_disp,1),size(im_disp,2)]);
                    imagesc(im_disp(:,:,1));
                    a=gca; a.XLim=[0.5 size(CC_rev_hyper,2)+0.5];a.YLim=[0.5 size(CC_rev_hyper,1)+0.5];
                    saveas(h_h(id_cut),strcat(pn_im_stack{id_dataset},'\', h_h(id_cut).Name, '.fig'),'fig');
                    close(h_h(id_cut));
                end

            end
            % for hyper -------------------------------------------------------
    
            zerocheck = reshape(sum(sum(CC_hyper(:,:,:),1),2),[],1);
            startslice = min(find(zerocheck));
            if id_dataset == 1
                CC_rev_hyper_stack = CC_rev_hyper(:,:,startslice:end);%1?????
                CC_hyper_stack = CC_hyper(:,:,startslice:end);%1?????
                CC_var_rev_hyper_stack = CC_var_rev_hyper(:,:,:,startslice:end);%1?????
                CCoff_var_rev_hyper_stack = CCoff_var_rev_hyper(:,:,:,startslice:end);%2024.02.07
                CC_var_rev_hyper_offmatch_stack = CC_var_rev_hyper_offmatch(:,:,startslice:end);%2024.02.04
                CC_var_rev_hyper_maxoffcc_stack = CC_var_rev_hyper_maxoffcc(:,:,startslice:end);%2024.02.07
                CCoff_var_hyper_stack = CCoff_var_hyper(:,:,:,startslice:end);%2024.02.07
                CC_var_hyper_stack = CC_var_hyper(:,:,:,startslice:end);%1?????
                CC_var_hyper_offmatch_stack = CC_var_hyper_offmatch(:,:,startslice:end);%2024.02.04
                CC_var_hyper_maxoffcc_stack = CC_var_hyper_maxoffcc(:,:,startslice:end);%2024.02.04
                CC_var_rev_hyper_min_stack = CC_var_rev_hyper_min(:,:,:,startslice:end);%1?????
                CC_var_rev_hyper_max_stack = CC_var_rev_hyper_max(:,:,:,startslice:end);%1?????
                CC_var_hyper_min_stack = CC_var_hyper_min(:,:,:,startslice:end);%1?????
                CC_var_hyper_max_stack = CC_var_hyper_max(:,:,:,startslice:end);%1?????
            else
                CC_rev_hyper_stack = cat(3, CC_rev_hyper_stack, CC_rev_hyper(:,:,startslice:end));%1?????
                CC_hyper_stack = cat(3, CC_hyper_stack, CC_hyper(:,:,startslice:end));%1?????
                CC_var_rev_hyper_stack = cat(4, CC_var_rev_hyper_stack, CC_var_rev_hyper(:,:,:,startslice:end));%1?????
                CCoff_var_rev_hyper_stack = cat(4, CCoff_var_rev_hyper_stack, CCoff_var_rev_hyper(:,:,:,startslice:end));%2024.02.07
                CC_var_rev_hyper_offmatch_stack = cat(3, CC_var_rev_hyper_offmatch_stack, CC_var_rev_hyper_offmatch(:,:,startslice:end));%1?????
                CC_var_rev_hyper_maxoffcc_stack = cat(3, CC_var_rev_hyper_maxoffcc_stack, CC_var_rev_hyper_maxoffcc(:,:,startslice:end));%1?????
                CC_var_hyper_stack = cat(4, CC_var_hyper_stack, CC_var_hyper(:,:,:,startslice:end));%1?????
                CCoff_var_hyper_stack = cat(4, CCoff_var_hyper_stack, CCoff_var_hyper(:,:,:,startslice:end));%2024.02.07
                CC_var_hyper_offmatch_stack = cat(3, CC_var_hyper_offmatch_stack, CC_var_hyper_offmatch(:,:,startslice:end));%1?????
                CC_var_hyper_maxoffcc_stack = cat(3, CC_var_hyper_maxoffcc_stack, CC_var_hyper_maxoffcc(:,:,startslice:end));%2024.02.07
                CC_var_rev_hyper_min_stack = cat(4, CC_var_rev_hyper_min_stack, CC_var_rev_hyper_min(:,:,:,startslice:end));%1?????
                CC_var_rev_hyper_max_stack = cat(4, CC_var_rev_hyper_max_stack, CC_var_rev_hyper_max(:,:,:,startslice:end));%1?????
                CC_var_hyper_min_stack = cat(4, CC_var_hyper_min_stack, CC_var_hyper_min(:,:,:,startslice:end));%1?????
                CC_var_hyper_max_stack = cat(4, CC_var_hyper_max_stack, CC_var_hyper_max(:,:,:,startslice:end));%1?????
            end
            id_slice = size(CC_hyper_stack,3);
    
            slice_added_last = size(CC_hyper_stack,3);
            n_addes_slice = size(CC_rev_hyper,3) - (startslice-1);
            slice_previously_present = (slice_added_last - n_addes_slice);
            for id_slice = slice_previously_present + 1: slice_added_last;
                [a, b] = fileparts(pn_im_stack{id_dataset});%???????
                ListFnMovie{id_slice} = b;
                ListCutNumber{id_slice} = id_slice - slice_previously_present;
            end
    
            save(strcat(pn_im_stack{id_dataset},'\CC_hyper.mat'),'CC_rev_hyper','CC_hyper','CC_var_rev_hyper','CCoff_var_rev_hyper','CC_var_hyper','CCoff_var_hyper','CC_var_rev_hyper_min','CC_var_hyper_min','CC_var_rev_hyper_max','CC_var_hyper_max');
        end
    end
    pn_parent_cc = fileparts(pn_im_stack{1});
    save(strcat(pn_parent_cc,'\CC_hyper_stack.mat'),'CC_rev_hyper_stack','CC_hyper_stack','pn_im_stack','CC_var_rev_hyper_stack','CCoff_var_rev_hyper_stack','CC_var_rev_hyper_offmatch_stack','CC_var_rev_hyper_maxoffcc_stack','CC_var_hyper_stack','CCoff_var_hyper_stack','CC_var_hyper_offmatch_stack','CC_var_hyper_maxoffcc_stack','CC_var_rev_hyper_min_stack','CC_var_hyper_min_stack','CC_var_rev_hyper_max_stack','CC_var_hyper_max_stack','CC_stack','CC_var_stack');
    fn_full_CC_hyper_stack = strcat(pn_parent_cc,'\CC_hyper_stack.mat');
    %--------------------------------------------------------------------------------------------------------
    %--------------------------------------------------------------------------------------------------------
    pn_rev_hyper = strcat(pn_parent_cc,'\CC_rev_hyper', tag);
    mkdir(pn_rev_hyper);
    factor1 = 1;%1/(max(max(max(CC_rev_hyper_stack))));
    for ii = 1:size(CC_rev_hyper_stack,3)
        %fn_cut = [ListMovieCut(ii).fn_movie(1:end-4),'cut',num2str(ListMovieCut(ii).id_cut),'frame' num2str(ListMovieCut(ii).frames)];
        fn_cut = strcat(ListFnMovie{ii},'cut',num2str(ListCutNumber{ii}));
	    imwrite(factor1*CC_rev_hyper_stack(:,:,ii),strcat(pn_rev_hyper, '\', fn_cut, '.tif'));   
    end
    pn_hyper = strcat(pn_parent_cc,'\CC_hyper', tag);
    mkdir(pn_hyper);
    factor1 = 1;%1/(max(max(max(CC_hyper_stack))));
    for ii = 1:size(CC_hyper_stack,3)
        %fn_cut = [ListMovieCut(ii).fn_movie(1:end-4),'cut',num2str(ListMovieCut(ii).id_cut),'frame' num2str(ListMovieCut(ii).frames)];
        fn_cut = strcat(ListFnMovie{ii},'cut',num2str(ListCutNumber{ii}));
	    imwrite(factor1*CC_hyper_stack(:,:,ii),strcat(pn_hyper, '\', fn_cut, '.tif'));   
    end
    % save data and images
    %--------------------------------------------------------------------------------------------------------

    %--------------------------------------------------------------------------------------------------------
    pn_var_rev_hyper = strcat(pn_parent_cc,'\CC_var_rev_hyper', tag);
    mkdir(pn_var_rev_hyper);
    factor1 = 1;%1/max((max(max(max(CC_var_rev_hyper_stack)))));
    for ii = 1:size(CC_var_rev_hyper_stack,4)
        %fn_cut = [ListMovieCut(ii).fn_movie(1:end-4),'cut',num2str(ListMovieCut(ii).id_cut),'frame' num2str(ListMovieCut(ii).frames)];
        fn_cut = strcat(ListFnMovie{ii},'cut',num2str(ListCutNumber{ii}));
    
        im_write_temp = factor1*CC_var_rev_hyper_stack(:,:,:,ii);
        im_write = zeros([size(im_write_temp,1),size(im_write_temp,2),3]);%3 dim Zero Matris
        for id_ch = 1:size(im_write_temp,3)
            im_write(:,:,id_ch) = im_write_temp(:,:,id_ch);
        end
    
        if size(im_write_temp,3) <= 3%3Chを超えると一気に書き込めない
	        imwrite(im_write,strcat(pn_var_rev_hyper, '\', fn_cut, '.tif'));  
        else
            for id_ch = 1:size(im_write,3)
                if id_ch == 1
                    imwrite(im_write(:,:,id_ch),strcat(pn_var_rev_hyper, '\', fn_cut, '.tif'));  
                else
                    imwrite(im_write(:,:,id_ch),strcat(pn_var_rev_hyper, '\', fn_cut, '.tif'),'writemode','append');  
                end
            end
        end
    end
    pn_var_hyper = strcat(pn_parent_cc,'\CC_var_hyper', tag);
    mkdir(pn_var_hyper);
    factor1 = 1;%1/max(max(max(max(CC_var_hyper_stack))));
    for ii = 1:size(CC_var_hyper_stack,4)
        %fn_cut = [ListMovieCut(ii).fn_movie(1:end-4),'cut',num2str(ListMovieCut(ii).id_cut),'frame' num2str(ListMovieCut(ii).frames)];
        fn_cut = strcat(ListFnMovie{ii},'cut',num2str(ListCutNumber{ii}));
    
        im_write_temp = factor1*CC_var_hyper_stack(:,:,:,ii);
        im_write = zeros([size(im_write_temp,1),size(im_write_temp,2),3]);%3 dim Zero Matris
        for id_ch = 1:size(im_write_temp,3)
            im_write(:,:,id_ch) = im_write_temp(:,:,id_ch);
        end
        if size(im_write_temp,3) <= 3%3Chを超えると一気に書き込めない
	        imwrite(im_write,strcat(pn_var_hyper, '\', fn_cut, '.tif')); 
        else
            for id_ch = 1:size(im_write,3)
                if id_ch == 1
                    imwrite(im_write(:,:,id_ch),strcat(pn_var_hyper, '\', fn_cut, '.tif'));  
                else
                    imwrite(im_write(:,:,id_ch),strcat(pn_var_hyper, '\', fn_cut, '.tif'),'writemode','append');  
                end
            end
        end
    end

    pn = strcat(pn_parent_cc,'\CC_var_rev_hyper_offmatch', tag);%2024.02.04
    var_hyper_OFF_writer(CC_var_rev_hyper_offmatch_stack,pn,ListFnMovie,ListCutNumber);

    pn = strcat(pn_parent_cc,'\CC_var_hyper_offmatch', tag);%2024.02.04
    var_hyper_OFF_writer(CC_var_hyper_offmatch_stack,pn,ListFnMovie,ListCutNumber);

    pn = strcat(pn_parent_cc,'\CC_var_rev_hyper_maxoffcc', tag);%2024.02.07
    var_hyper_OFF_writer(CC_var_rev_hyper_maxoffcc_stack,pn,ListFnMovie,ListCutNumber);

    pn = strcat(pn_parent_cc,'\CC_var_hyper_maxoffcc', tag);%2024.02.07
    var_hyper_OFF_writer(CC_var_hyper_maxoffcc_stack,pn,ListFnMovie,ListCutNumber);

    % save data and images
    %--------------------------------------------------------------------------------------------------------
    % new, Single Cell
    pn_single_CC = strcat(pn_parent_cc,'\CC_single', tag);
    mkdir(pn_single_CC);
    pn_single_CC_var = strcat(pn_parent_cc,'\CC_var_single', tag);
    mkdir(pn_single_CC_var);
    n_dataset = numel(CC_stack);
    [Y, X, nCell, nCut] = size(CC_stack{1});
    factor1 = 1;%1/max(max(max(CC_hyper_stack)));
    factor2 = 1;%1/max(max(max(max(CC_var_hyper_stack))));
    
    for id_cell = 1:nCell
        pn_save_CC{id_cell} = strcat(pn_single_CC, '\Neuron_', num2str(id_cell));
        mkdir(pn_save_CC{id_cell});
        pn_save_CC_var{id_cell} = strcat(pn_single_CC_var, '\Neuron_', num2str(id_cell));
        mkdir(pn_save_CC_var{id_cell});
    end
    for id__dataset = 1:n_dataset
        pathname_temp = pn_im_stack{id__dataset};
        pathname = pathname_temp{1};%%エラー回避
        [a, filename] = fileparts(pathname(1:end-1));
        for id_cell = 1:nCell
            
            for id_cut = 2:nCut
                fn_cut_CC = strcat(filename,'cut',num2str(id_cut));
                im_write_CC = reshape(factor1*CC_stack{id_dataset}(:,:,id_cell,id_cut),[Y,X]);% cell,id_cut
                imwrite(im_write_CC,strcat(pn_save_CC{id_cell}, '\', fn_cut_CC, '.tif'));  
                im_write_CC_var = reshape(factor2*CC_var_stack{id_dataset}(:,:,id_cell,:,id_cut),Y-y_margin,X-x_margin,nCh,[]);% cell,shift,id_cut
                for id_shiftmember = 1:size(im_write_CC_var,4)
                    fn_cut_CC_var = strcat(filename,'shift', num2str(id_shiftmember), '_cut',num2str(id_cut));
                    imwrite(reshape(im_write_CC_var(:,:,:,id_shiftmember),Y-y_margin,X-x_margin,nCh),strcat(pn_save_CC_var{id_cell}, '\', fn_cut_CC_var, '.tif')); 
                end
            end
        end
    end
    %--------------------------------------------------------------------------------------------------------
    for ii = 1:size(CC_var_rev_hyper_min_stack,4)  
        fn_cut = strcat(ListFnMovie{ii},'cut',num2str(ListCutNumber{ii}));
        im_write = factor1*CC_var_rev_hyper_min_stack(:,:,:,ii);
        im_write(:,:,3) = zeros(size(im_write,1),size(im_write,2));
	    imwrite(im_write,strcat(pn_rev_hyper, '\', fn_cut, '.tif'));   
    end
    pn_hyper = strcat(pn_parent_cc,'\CC_var_hyper_min', tag);
    mkdir(pn_hyper);
    factor1 = 1;%1/max(max(max(max(CC_var_hyper_min_stack))));
    for ii = 1:size(CC_var_hyper_min_stack,4)
        fn_cut = strcat(ListFnMovie{ii},'cut',num2str(ListCutNumber{ii}));
        im_write = factor1*CC_var_hyper_min_stack(:,:,:,ii);
        im_write(:,:,3) = zeros(size(im_write,1),size(im_write,2));
	    imwrite(im_write,strcat(pn_hyper, '\', fn_cut, '.tif'));   
    end
    % save data and images
    
    %--------------------------------------------------------------------------------------------------------
    % new
    pn_rev_hyper = strcat(pn_parent_cc,'\CC_var_rev_hyper_min', tag);
    mkdir(pn_rev_hyper);
    factor1 = 1;%1/max(max(max(max(CC_var_rev_hyper_min_stack))));
    for ii = 1:size(CC_var_rev_hyper_min_stack,4)
        fn_cut = strcat(ListFnMovie{ii},'cut',num2str(ListCutNumber{ii}));
        im_write = factor1*CC_var_rev_hyper_min_stack(:,:,:,ii);
        im_write(:,:,3) = zeros(size(im_write,1),size(im_write,2));
	    imwrite(im_write,strcat(pn_rev_hyper, '\', fn_cut, '.tif'));   
    end
    pn_hyper = strcat(pn_parent_cc,'\CC_var_hyper_min', tag);
    mkdir(pn_hyper);
    factor1 = 1;%1/max(max(max(max(CC_var_hyper_min_stack))));
    for ii = 1:size(CC_var_hyper_min_stack,4)
        fn_cut = strcat(ListFnMovie{ii},'cut',num2str(ListCutNumber{ii}));
        im_write = factor1*CC_var_hyper_min_stack(:,:,:,ii);
        im_write(:,:,3) = zeros(size(im_write,1),size(im_write,2));
	    imwrite(im_write,strcat(pn_hyper, '\', fn_cut, '.tif'));   
    end
    % save data and images
    
    % new
    pn_rev_hyper = strcat(pn_parent_cc,'\CC_var_rev_hyper_max', tag);
    mkdir(pn_rev_hyper);
    factor1 = 1;%1/max(max(max(max(CC_var_rev_hyper_max_stack))));
    for ii = 1:size(CC_var_rev_hyper_max_stack,4)
        fn_cut = strcat(ListFnMovie{ii},'cut',num2str(ListCutNumber{ii}));
        im_write = factor1*CC_var_rev_hyper_max_stack(:,:,:,ii);
        im_write(:,:,3) = zeros(size(im_write,1),size(im_write,2));
	    imwrite(im_write,strcat(pn_rev_hyper, '\', fn_cut, '.tif'));   
    end
    pn_hyper = strcat(pn_parent_cc,'\CC_var_hyper_max', tag);
    mkdir(pn_hyper);
    factor1 = 1;%1/max(max(max(max(CC_var_hyper_max_stack))));
    for ii = 1:size(CC_var_hyper_max_stack,4)
        fn_cut = strcat(ListFnMovie{ii},'cut',num2str(ListCutNumber{ii}));
        im_write = factor1*CC_var_hyper_max_stack(:,:,:,ii);
        im_write(:,:,3) = zeros(size(im_write,1),size(im_write,2));
	    imwrite(im_write,strcat(pn_hyper, '\', fn_cut, '.tif'));   
    end
    % save data and images
    %--------------------------------------------------------------------------------------------------------
    % new voting
    nVote = size(CC_var_rev_hyper_stack,3)/nCh;
    for id_vote = 1:nVote
        ListCh = (nCh*id_vote-1):nCh*id_vote;% for cube, error correct
        pn_rev_hyper = strcat(pn_parent_cc,'\CC_var_rev_hyper_vote', num2str(id_vote), tag);
        mkdir(pn_rev_hyper);
        factor1 = 1;%1/max(max(max(max(CC_var_rev_hyper_min_stack))));
        for ii = 1:size(CC_var_rev_hyper_stack,4)
            fn_cut = strcat(ListFnMovie{ii},'cut',num2str(ListCutNumber{ii}));
            im_write = factor1*CC_var_rev_hyper_stack(:,:,ListCh,ii);
            im_write(:,:,3) = zeros(size(im_write,1),size(im_write,2));
	        imwrite(im_write,strcat(pn_rev_hyper, '\', fn_cut, '.tif'));   
        end
        pn_hyper = strcat(pn_parent_cc,'\CC_var_hyper_vote', num2str(id_vote), tag);
        mkdir(pn_hyper);
        factor1 = 1;%1/max(max(max(max(CC_var_hyper_stack))));
        for ii = 1:size(CC_var_hyper_min_stack,4)
            fn_cut = strcat(ListFnMovie{ii},'cut',num2str(ListCutNumber{ii}));
            im_write = factor1*CC_var_hyper_stack(:,:,ListCh,ii);
            im_write(:,:,3) = zeros(size(im_write,1),size(im_write,2));
	        imwrite(im_write,strcat(pn_hyper, '\', fn_cut, '.tif'));   
        end
    end
    % save data and images
    %--------------------------------------------------------------------------------------------------------
    
    %--------------------------------------------------------------------------------------------------------
    save(strcat(pn_hyper,'\CC_hyper_stack.mat'),'CC_hyper_stack','AveSumCC','OrderCC','ListFnMovie','ListCutNumber');
    pn_rev_hyper = strcat(pn_parent_cc,'\CC_rev_hyper', tag);
    mkdir(pn_rev_hyper);
    save(strcat(pn_rev_hyper,'\CC_rev_hyper_stack.mat'),'CC_rev_hyper_stack','AveSumCC','OrderCC','ListFnMovie','ListCutNumber');
    %---------------------------------------------------------------------------------------------------
    
    %---------------------------------------------------------------------------------------------------
    % save mfile
    fnfull_m = mfilename('fullpath');
    fn_m = mfilename();
    %copyfile([fnfull_m, '.mat'],[pn_im_stack '\fn_m','.mat']);
    %---------------------------------------------------------------------------------------------------
    %---------------------------------------------------------------------------------------------------
    
    %-----------------------------------------------------------------------------------
    %-----------------------------------------------------------------------------------
    if yn_skip_fig ~= 'y'
        % show and save
        % show CC_hyper
        pn_hyper_figures = strcat(pn_hyper,'\figures');
        pn_rev_hyper_figures = strcat(pn_rev_hyper,'\figures');
        mkdir(pn_hyper_figures);
        mkdir(pn_rev_hyper_figures);
        % Display every 10 slices
        for id_slice = 1:10:size(CC_rev_hyper_stack,3)% to prevent stick out
            CC = CC_rev_hyper_stack(:,:,id_slice);
            h_revhyper(id_slice) = figure('Name',strcat('movie spectrum ',  'revhyper cut#', num2str(id_slice)),'Color','w');hold on;
            maxvalue = abs(prctile(reshape(CC,1,[]),100));
	        imagesc(floor(255*(CC(:,:)/maxvalue)),[0 255]);
            tightfig;
            a=gca;a.XLim = [0, size(CC,2)];a.YLim = [0, size(CC,1)];
            saveas(h_revhyper(id_slice), strcat(pn_rev_hyper_figures, '\', h_revhyper(id_slice).Name, '.fig'),'fig');
            close(h_revhyper(id_slice));
        end
        for id_slice = 1:10:size(CC_hyper_stack,3)% to prevent stick out
            CC = CC_hyper_stack(:,:,id_slice);
            h_hyper(id_slice) = figure('Name',strcat('movie spectrum ',  'hyper cut#', num2str(id_slice)),'Color','w');hold on;
            maxvalue = abs(prctile(reshape(CC,1,[]),100));
	        imagesc(floor(255*(CC(:,:)/maxvalue)),[0 255]);
            tightfig;
            a=gca;a.XLim = [0, size(CC,2)];a.YLim = [0, size(CC,1)];
            saveas(h_hyper(id_slice), strcat(pn_hyper_figures, '\', h_hyper(id_slice).Name, '.fig'),'fig');
            close(h_hyper(id_slice));
        end
    end

end

function var_hyper_OFF_writer(CC_var_hyper_stack,pn_var_rev_hyper,ListFnMovie,ListCutNumber)
    %pn_var_rev_hyper = strcat(pn_parent_cc,'\CC_var_rev_hyper', tag);
    pn_save = strcat(pn_var_rev_hyper, '\SliceOf1Ch1\all');
    mkdir(pn_save);
    factor1 = 1;%1/max((max(max(max(CC_var_rev_hyper_stack)))));
    for ii = 1:size(CC_var_hyper_stack,3)% offmatch writerでは３次元目
        fn_cut = strcat(ListFnMovie{ii},'cut',num2str(ListCutNumber{ii}));
        im_write_temp = factor1*CC_var_hyper_stack(:,:,ii);
        im_write = zeros([size(im_write_temp,1),size(im_write_temp,2)]);%3 dim Zero Matris
        im_write(:,:) = im_write_temp(:,:);
        imwrite(im_write,strcat(pn_save, '\', fn_cut, '.tif'));  
    end
end

