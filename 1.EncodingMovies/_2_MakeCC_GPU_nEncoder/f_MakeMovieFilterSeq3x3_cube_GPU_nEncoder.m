% Make MovieFilterMat
% modified from MakeMovieFilterBD2.m

function [pn_CC, tag] = f_MakeMovieFilterSeq3x3_cube_GPU_nEncoder(pn_movie,varargin)

    tag = '';
    SideEncoder = '';
    %nSection = [10, 10];% default
    for ii = 1:nargin-1
        if strcmp(varargin{ii},'tag')
            tag = ['_' varargin{ii+1}];
        end
        if strcmp(varargin{ii},'cc_mode')
            cc_mode = varargin{ii+1};
        end
        if strcmp(varargin{ii},'nSection')
            nSection = varargin{ii+1};
            tag = [tag '_' num2str(nSection(1)) 'x' num2str(nSection(2)) 'Gri'];
        end
        if strcmp(varargin{ii},'SideEncoder')
            SideEncoder = varargin{ii+1};
            tag = [tag '_' num2str(SideEncoder(1)) 'x' num2str(SideEncoder(2)) 'Pix'];
        end
    end
   
    %---------------------------------
    %default setting
    yn_flip_T = 'n';
    yn_invert_IM = 'n';
    Range_frame = 1:24;
    keyword = '600ms';
    SelRank = {'A','S'};
    %---------------------------------

    for ii = 1:nargin - 1
        if strcmp(varargin{ii},'yn_flip_T')
            yn_flip_T = varargin{ii+1};
        end
        if strcmp(varargin{ii},'yn_invertIM')
            yn_invert_IM = varargin{ii+1};
        end
        if strcmp(varargin{ii},'Range_frame')
            Range_frame = varargin{ii+1};
        end
        if strcmp(varargin{ii},'keyword')
            keyword = varargin{ii+1};
        end
        if strcmp(varargin{ii},'SelRank')
            SelRank = varargin{ii+1};
        end
        if strcmp(varargin{ii},'fn_full_RFMap')
            fn_full_RFMap = varargin{ii+1};
            if ~isempty(fn_full_RFMap)
                load(fn_full_RFMap);
                nFrame = size(DataBase{1}.input.RFMap,3);
                fprintf('nFrame is %d\n',nFrame);
                yn_autoset_Range_frame = input('Set this frame range y/n []=y','s');
                if isempty(yn_autoset_Range_frame)
                    yn_autoset_Range_frame = 'y';
                end
                if (yn_autoset_Range_frame == 'y')
                    Range_frame = 1:nFrame;
                end
                if isempty(strfind(DataBase{1}.datasetname, keyword))
                    yn_clear_keyword = input(['DataBase does not include keyword=' keyword ' change keyword to include it? y/n []=y' ],'s');
                    if isempty(yn_clear_keyword)
                        yn_clear_keyword = 'y';
                    end
                    if yn_clear_keyword == 'y'
                        keyword = DataBase{1}.datasetname;
                    end
                end
                if ~isfield(DataBase{1}.input,'RF_black')
                    fprintf('RF_black field is missing making from RFMap\n');
                    DataBase{1}.input.RF_black = (abs(DataBase{1}.input.RFMap) - DataBase{1}.input.RFMap)/2;
                end
                if ~isfield(DataBase{1}.input,'RF_white')
                    fprintf('RF_white field is missing making from RFMap\n');
                    DataBase{1}.input.RF_white = (abs(DataBase{1}.input.RFMap) + DataBase{1}.input.RFMap)/2;
                end
            end
        end
    end

    yn_skip_fig = input('skip making figs y/n []=y\n','s' );
    if isempty(yn_skip_fig)
        yn_skip_fig = 'y';
    end
    
    %n_step = 3;
    nCh=3;
    ListShift_norm = ...
        [0 0; 0 1/3; 0 2/3;...
        1/3 0; 1/3 1/3; 1/3 2/3;...
        2/3 0; 2/3 1/3; 2/3 2/3];
    
    y_margin = ceil(max(ListShift_norm(:,1)));
    x_margin = ceil(max(ListShift_norm(:,2)));
    
    fprintf('Step1: Load RFMap to make movie filters\n');
    
    %yn_flip_T = input('Flip T axis of Movie filter []=n\n','s');% Use RF Map start from black
    
    if yn_flip_T == 'y'
        tag = [tag, '_flip'];
        fprintf('flip_T\n');
    end
    if yn_invert_IM == 'y'
        tag = [tag, '_invert'];
        fprintf('_invert_IM\n');
    end
    
    %offset_mode = input('e:Time Offset adjusted each grids c:common for all grids []=e \n','s');
    offset_mode = 'e';
    if isempty(offset_mode)
        offset_mode = 'e';
    end
    tag = [tag '_' offset_mode];
    
    cut_duration = 0.6;
    sec_filter_frame = 0.025;
    fprintf('Scenes are cut into %d sec\n',cut_duration);
    
    %sel_movie = input('i: intact movie, d: derivative movie \n','s');% moved from L194;
    sel_movie = 'd';

    if ~exist('DataBase','var')
        try
            mfn = mfilename('fullpath');
            pn_DataBase_Dipole = fileparts(mfn);
            %pn_DataBase_Dipole = 'C:\Users\gengoro\OneDrive - Scripps Research\_MovieFilterPaper\Fig4\Peak latency histogram';
            %fn_DataBase_Rank = 'DataBase_Dipole_Rank.mat';
            [fn_DataBase_Rank,pn_DataBase_Dipole] = uigetfile(pn_DataBase_Dipole,'\DataBase_Dipole_Rank.mat');
            fn_full_RFMap = [pn_DataBase_Dipole,'\' fn_DataBase_Rank];
            load(fn_full_RFMap);
        catch
            pn_DataBase_Dipole = '\\172.29.164.18\home\Bahavior\RFFilterData';
            fn_DataBase_Rank = 'DataBase_Dipole_Rank.mat';
            fn_full_RFMap = [pn_DataBase_Dipole,'\' fn_DataBase_Rank];
            load(fn_full_RFMap);
        end
    end
    

    counter = 0;
    clear MF;
    nFrame_filter = numel(Range_frame);
    
    for id_data = 1:numel(DataBase)
        nCell = size(DataBase{id_data}.input.RFMap,4);
        ListSel{id_data} =[];
        for id_cell = 1:nCell
            if ~isempty(strfind(DataBase{id_data}.datasetname,keyword))&& isfield(DataBase{id_data},'Rank')
                if numel(DataBase{id_data}.Rank) >= id_cell
                    if~isempty(intersect(SelRank,DataBase{id_data}.Rank{id_cell}))
                        ListSel{id_data} = [ListSel{id_data}, id_cell];
                        counter = counter +1;
                        if yn_flip_T == 'y'
                            MF.RFMap(:,:,:,counter) = DataBase{id_data}.input.RFMap(:,:,Range_frame,id_cell);
                            MF.RF_black(:,:,:,counter) = DataBase{id_data}.input.RF_black(:,:,Range_frame,id_cell);
                            MF.RF_white(:,:,:,counter) = DataBase{id_data}.input.RF_white(:,:,Range_frame,id_cell);
                        else
                            MF.RFMap(:,:,:,counter) = flip(DataBase{id_data}.input.RFMap(:,:,Range_frame,id_cell),3);
                            MF.RF_black(:,:,:,counter) = flip(DataBase{id_data}.input.RF_black(:,:,Range_frame,id_cell),3);
                            MF.RF_white(:,:,:,counter) = flip(DataBase{id_data}.input.RF_white(:,:,Range_frame,id_cell),3);
                        end
                        if yn_invert_IM == 'y'% invert OFFRF=> ON RF, ONRF=>OFF RF
                            MF.RFMap(:,:,:,counter) = -MF.RFMap(:,:,:,counter);
                            MF.RF_black(:,:,:,counter) = MF.RF_white(:,:,:,counter);
                            MF.RF_white(:,:,:,counter) = MF.RF_black(:,:,:,counter);
                        end
                    end
                end
            end  
        end
    end
    
    [MF, addtag] = select_encoder(MF);% select number of encoders
    tag = [tag, addtag];
      
    nFilter = size(MF.RFMap,4);
    fprintf('N filteres are %d\n',nFilter);
    % fine OFF peak
    ListSumOFf = reshape(sum(sum(MF.RF_black,2),1),size(MF.RF_black,3),size(MF.RF_black,4));
    ListOFFPeak = max(ListSumOFf,[],1);
    % fine OFF peak
    ListSumON = reshape(sum(sum(MF.RF_white,2),1),size(MF.RF_white,3),size(MF.RF_white,4));
    ListONPeak = max(ListSumON,[],1);
    
    if MF.ListUsedEncoderID ~= 0
        for id_filter = 1:nFilter
            ListOFFPeakFrame(id_filter) = find(ListSumOFf(:,id_filter)==ListOFFPeak(id_filter));
            ListONPeakFrame(id_filter) = find(ListSumON(:,id_filter)==ListONPeak(id_filter));
        end
    else
        ListOFFPeakFrame(1) =size(MF.RFMap,3);%最後
        ListONPeakFrame(1) = 1;%最初
    end
    
    MF.OffFrame = max(mode(ListOFFPeakFrame));%??????????
    MF.OnFrame = max(mode(ListONPeakFrame));%??????????
    if yn_flip_T == 'y'
	    nFrame_after_ON = numel(Range_frame) - MF.OnFrame;
        nFrame_before_OFF = MF.OffFrame;
    else
        nFrame_after_OFF = numel(Range_frame) - MF.OffFrame;
        nFrame_before_ON = MF.OnFrame;
    end
    
    %---------------------------------------------------------------------------------------------------
    %---------------------------------------------------------------------------------------------------
    % Analyze Image Data
    % This section convert Movie into Movie_mat, and make index of frames in
    % each cut
    fprintf('Step2: Load movie files to make Movie.mat\n');
    %pn_movie = 'C:\Users\gengoro\Dropbox (Scripps Research)\_OriginalSoftwares\MATLAB program CF\_DeepLearning\MovieFilter';
    %pn_movie = '\\172.29.164.18\home\';
    
    %yn_load_MovieMat = input('Load MovieMat y/n [] = n','s');
    yn_load_MovieMat = 'n';
    if isempty(yn_load_MovieMat)
        yn_load_MovieMat = 'n';
    end
    if yn_load_MovieMat == 'n'
        MovieList = dir(fullfile(pn_movie,'*.avi'));
        for ii = 1:numel(MovieList)
            List_fn_movie{ii} = MovieList(ii).name;
        end
    end
    %---------------------------------------------------------------------------------------------------
    fprintf('Step3: Calculating Cross correlation from Movie.mat\n');
   
    InfoMovie.sec_filter_frame = sec_filter_frame;
    InfoMovie.cut_duration = cut_duration;
    InfoMovie.sel_movie = sel_movie;
    InfoMovie.offset_mode = offset_mode;
    InfoMovie.x_margin = x_margin;
    InfoMovie.y_margin = y_margin;
    InfoMovie.ListShift_norm = ListShift_norm;
    InfoEncoder.MF = MF;
    InfoEncoder.nSection = nSection;
    InfoEncoder.SideEncoder = SideEncoder;

    List_avi = dir(fullfile(pn_movie,'*.avi'));

    add_tag = input('any tag to add before timestamp? \n','s');
    if ~isempty(add_tag)
        tag = [tag, '_' add_tag];   
    end

    timestamp = string(datetime('now','Format','MMdd_HHmm'));
    pn_CC = strcat(pn_movie, '\CC', tag, '_', timestamp);
    mkdir(pn_CC);
    [~, fn_RF] = fileparts(fn_full_RFMap);
    fn_target = strcat(pn_CC, '\', fn_RF, '.mat');
    copyfile(fn_full_RFMap, fn_target);
    parfor id_movie = 1:numel(List_avi)
        makeCC_GPU_file(List_avi(id_movie).name, pn_movie, pn_CC, InfoEncoder, InfoMovie, 'tag',tag);
    end
    %---------------------------------------------------------------------------------------------------
    %---------------------------------------------------------------------------------------------------
end

