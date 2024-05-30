% Make MovieFilterMat
% modified from MakeMovieFilterBD2.m

clear;close all;
sel_movie = input('i: intact movie, d: derivative movie \n','s');% moved from L194;
fig_category = input('Type fig category as memo\n','s');% moved from L195;

%n_step = 3;
nCh=3;
ListShift_norm = ...
    [0 0; 0 1/3; 0 2/3;...
    1/3 0; 1/3 1/3; 1/3 2/3;...
    2/3 0; 2/3 1/3; 2/3 2/3];

y_margin = ceil(max(ListShift_norm(:,1)));
x_margin = ceil(max(ListShift_norm(:,2)));

fprintf('Step1: Load RFMap to make movie filters\n');

tag = '';
yn_flip_T = input('Flip T axis of Movie filter []=n\n','s');% Use RF Map start from black
if isempty(yn_flip_T)
    yn_flip_T = 'n';
end
if yn_flip_T == 'y'
    tag = [tag, '_flip'];
end

offset_mode = input('e:Time Offset adjusted each grids c:common for all grids []=e \n','s');
if isempty(offset_mode)
    offset_mode = 'e';
end
tag = [tag '_' offset_mode];

cut_duration = 0.6;
sec_filter_frame = 0.025;
fprintf('Scenes are cut into %d sec\n',cut_duration);

try
    mfilename = mfilename('fullpath');
    pn_DataBase_Dipole = fileparts(mfilename);
    %pn_DataBase_Dipole = 'C:\Users\gengoro\OneDrive - Scripps Research\_MovieFilterPaper\Fig4\Peak latency histogram';
    fn_DataBase_Rank = 'DataBase_Dipole_Rank.mat';
    load([pn_DataBase_Dipole,'\' fn_DataBase_Rank]);
catch
	pn_DataBase_Dipole = '\\172.29.164.18\home\Bahavior\RFFilterData';
    fn_DataBase_Rank = 'DataBase_Dipole_Rank.mat';
    load([pn_DataBase_Dipole,'\' fn_DataBase_Rank]);
end

keyword = '600ms';
SelRank = {'A','S'};
counter = 0;
clear MF;
Range_frame = 1:24;
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
                end
            end
        end  
    end
end

nFilter = size(MF.RFMap,4);
fprintf('N filteres are %d\n',nFilter);
% fine OFF peak
ListSumOFf = reshape(sum(sum(MF.RF_black,2),1),size(MF.RF_black,3),size(MF.RF_black,4));
ListOFFPeak = max(ListSumOFf,[],1);
% fine OFF peak
ListSumON = reshape(sum(sum(MF.RF_white,2),1),size(MF.RF_white,3),size(MF.RF_white,4));
ListONPeak = max(ListSumON,[],1);

for id_filter = 1:nFilter
    ListOFFPeakFrame(id_filter) = find(ListSumOFf(:,id_filter)==ListOFFPeak(id_filter));
    ListONPeakFrame(id_filter) = find(ListSumON(:,id_filter)==ListONPeak(id_filter));
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
%---------------------------------------------------------------------------------------------------
% Analyze Image Data
% This section convert Movie into Movie_mat, and make index of frames in
% each cut
fprintf('Step2: Load movie files to make Movie.mat\n');
%pn_movie = 'C:\Users\gengoro\Dropbox (Scripps Research)\_OriginalSoftwares\MATLAB program CF\_DeepLearning\MovieFilter';
pn_movie = '\\172.29.164.18\home\';

yn_load_MovieMat = input('Load MovieMat y/n [] = n','s');
if isempty(yn_load_MovieMat)
    yn_load_MovieMat = 'n';
end
if yn_load_MovieMat == 'n'
    [List_fn_movie, pn_movie] = uigetfile([pn_movie '\*'] ,'Load single/multiple movie ','MultiSelect','on');
    pn_movie = pn_movie(1:end-1);
    if ~iscell(List_fn_movie)
        temp = List_fn_movie;
        clear List_fn_movie;
        List_fn_movie{1} = temp;
    end
end

for id_movie = 1:numel(List_fn_movie)
    fn_movie = List_fn_movie{id_movie};
    
    clear Movie_Mat;
    if yn_load_MovieMat == 'n'
        vidObj = VideoReader([pn_movie '\' fn_movie]);
        duration = vidObj.Duration;
        nCut(id_movie) = floor((duration - sec_filter_frame)/cut_duration);%2???????
        nFramePerCut = round(cut_duration/sec_filter_frame);
        for id_cut = 1:nCut(id_movie)
            ListFrame_startstop{id_movie}(:,id_cut) = [nFramePerCut*(id_cut-1) + 1, nFramePerCut*id_cut];
        end
        fprintf('%d frames in one cut x %d\n',nFramePerCut,nCut(id_movie));
        Movie_Mat = [];
        for id_cut = 1:nCut(id_movie)
            for id_frame = 1:nFramePerCut
                vidObj.CurrentTime = cut_duration*(id_cut-1) + sec_filter_frame * id_frame;
                frame = readFrame(vidObj);
                Movie_Mat(:,:,round(nFramePerCut*(id_cut-1) + id_frame)) = mean(frame,3);
                fprintf('.');
            end
            fprintf('\n');
        end
        fprintf('\n');
        sec_per_frame = sec_filter_frame;
        List_fn_movie_mat{id_movie} = [fn_movie(1:end-4) 'MovieMat.mat'];
        save([pn_movie '\' List_fn_movie_mat{id_movie}],'Movie_Mat','duration','nCut','sec_per_frame','fn_movie','-v7.3');
    else
        [fn_movie_mat, pn_movie_mat] = uigetfile(pn_movie,'MovieMat.mat');
        load([pn_movie_mat, '\', fn_movie_mat]);
        nCut(id_movie) = floor((duration - sec_filter_frame)/cut_duration);%2???????
        nFramePerCut = round(cut_duration/sec_filter_frame);
        for id_cut = 1:nCut(id_movie)
            ListFrame_startstop{id_movie}(:,id_cut) = [nFramePerCut*(id_cut-1) + 1, nFramePerCut*id_cut];
        end
    end
    if max(max(max(Movie_Mat)))==0
        fprintf('Error! max of Movie_Mat =0\n');
    else
        fprintf('Movie_mat completed %d out of %d\n',id_movie,numel(List_fn_movie));
    end
end
%---------------------------------------------------------------------------------------------------
%---------------------------------------------------------------------------------------------------
%for id_cut = 1:nCut
%    for id_frame = 1:nFrame
%        vidObj.CurrentTime = 0.6*(id_cut-1) + 0.025 * id_frame;
%        frame = readFrame(vidObj);
%        MovieStack(:,:,id_frame,id_cut) = frame(:,:,1);
%        fprintf('.');
%    end
%    fprintf('\n');
%end
%fn_save = [fn_movie(1:end-4) '_25-' num2str(cut_duration) 'sec_x' num2str(nCut)];
%save([pn_movie '\' fn_save '_MovieStack.mat'],'MovieStack');
%---------------------------------------------------------------------------------------------------
%---------------------------------------------------------------------------------------------------
%---------------------------------------------------------------------------------------------------
fprintf('Step3: Calculating Cross correlation from Movie.mat\n');
% This section define temporal offset and align temporal axis and calculate
% CC
fprintf('Calculating Cross correlation\n');

%sel_movie = input('i: intact movie, d: derivative movie \n','s');% movedup
%fig_category = input('Type fig category as memo\n','s');% movedup
%tic
counter_cc = 0;
for id_movie = 1:numel(List_fn_movie_mat)
    %toc
    percentage = round(100*id_movie/numel(List_fn_movie_mat));
    fprintf('%d percent completed\n',percentage);
    
    fn_movie = List_fn_movie_mat{id_movie};
    fprintf('fn_movie is %s\n',fn_movie);

    %%%%%%%%%
    %%%%%%%%%
    %%%%%%%%%
    % Load Movie Mat
    load([pn_movie '\' List_fn_movie_mat{id_movie}]);
    
    if ~isempty(Movie_Mat)
        
        fn_save = [fn_movie(1:end-4) '_25-' num2str(cut_duration) 'sec_x' num2str(nCut(id_movie))];
        %%%%%%%%%
        %%%%%%%%%
        %%%%%%%%%
        Movie_deriv_Mat = Movie_Mat(:,:,2:end) -  Movie_Mat(:,:,1:end-1);
        XYsize= [200 200];
        side_rf = 20;
        nSection = XYsize/side_rf;
        fprintf('Resizing to %s\n',num2str(XYsize));

        clear Movie_intact_resize;
        clear Movie_deriv_resize;
        for id_frame = 1:size(Movie_Mat,3)-1
            Movie_intact_resize(:,:,id_frame) = imresize(Movie_Mat(:,:,id_frame),XYsize);
            Movie_deriv_resize(:,:,id_frame) = imresize(Movie_deriv_Mat(:,:,id_frame),XYsize);
        end

        switch sel_movie
            case 'i'
                tag = '_i';
                Movie_all_resize = Movie_intact_resize;
                note = 'intact';
            case 'd'
                tag = '_d';
                Movie_all_resize = Movie_deriv_resize;
                note = 'deriv';
        end
        fn_save = [fn_save, tag];
        pn_save_final =[pn_movie '\' fn_save];
        mkdir(pn_save_final);

        CC_allcut = zeros(nSection(2),nSection(1),nFilter,nCut(id_movie)-1);

        nCut_current = nCut(id_movie)-1;
        for id_cut = 2:nCut_current% to prevent stick out
            fprintf('Current cut is %d out of %d\n',id_cut,nCut(id_movie));
            ListFrame = round(ListFrame_startstop{id_movie}(1,id_cut):ListFrame_startstop{id_movie}(2,id_cut)); 

            %-------------------------------------------------
            counter_cc = counter_cc + 1;
            ListMovieCut(counter_cc).fn_movie = fn_movie; %CC image’s file information
            ListMovieCut(counter_cc).id_cut= id_cut;
            ListMovieCut(counter_cc).frames = ListFrame;
            %-------------------------------------------------

            Movie_resize = Movie_all_resize(:,:,ListFrame);

            %clear CC;
            nFrame_filter = size(MF.RFMap,3);
            fprintf('View is divided into %d x %d\n',nSection(1),nSection(2));
            %-------------------------------------------------
            switch offset_mode
                case 'e'% default
                    for id_xsec = 1:nSection(1) - x_margin% var version
                        for id_ysec = 1:nSection(2) - y_margin% var version
                            
                            x_range = side_rf*(id_xsec-1) + 1:side_rf*id_xsec;
                            y_range = side_rf*(id_ysec-1) + 1:side_rf*id_ysec;
                            Movie_sec = Movie_resize(y_range,x_range,:);

                            % OFF??????OFF??????????????
                            ListIntensity = reshape(sum(sum(Movie_sec,2),1),[],1);
                            ListIntensity_cut = ListIntensity;% ????????
                            if yn_flip_T == 'y'
                                OnFrameIn = min(find(ListIntensity_cut == min(ListIntensity_cut)));
                                offset_t = OnFrameIn - MF.OnFrame;
                            else
                                OffFrameIn = min(find(ListIntensity_cut == min(ListIntensity_cut)));
                                offset_t = OffFrameIn - MF.OffFrame;
                            end

                            start_total = ListFrame_startstop{id_movie}(1,id_cut) + offset_t;% frames can be next cut
                            stop_total = start_total + nFrame_filter - 1;% frames can be next cut

                            InputMovie = Movie_all_resize(x_range,y_range,start_total:stop_total);
                            Range = {'','',0};
                            B = double(InputMovie)/256;

                            ListShift = round(ListShift_norm*side_rf);%Seq
                            for id_shift = 1:size(ListShift,1)
                                y_shift = ListShift(id_shift, 1);
                                x_shift = ListShift(id_shift, 2);
                                InputMovie_shift = Movie_all_resize(x_range(1) + x_shift:x_range(end) + x_shift, y_range(1) + y_shift:y_range(end) + y_shift,start_total:stop_total);% 
                                B_shift(:,:,:,id_shift) = double(InputMovie_shift)/256;
                            end
                            %step_shift = round(side_rf/n_step);
                            %for id_shift = 1:n_step
                            %    y_shift = step_shift*(id_shift - 1);
                            %    x_shift = step_shift*(id_shift - 1);
                            %    InputMovie_shift = Movie_all_resize(x_range(1) + x_shift:x_range(end) + x_shift, y_range(1) + y_shift:y_range(end) + y_shift,start_total:stop_total);% var_version corrected 2023Jun28
                            %    B_shift(:,:,:,id_shift) = double(InputMovie_shift)/256;
                            %end

                            for id_filter = 1:nFilter
                                A = MF.RFMap(:,:,:,id_filter);
                                %[ CCM, norm_CCM, T] = cc_3D_range( A,B, Range);
                                norm_CCM = A.*B./sqrt(sum(sum(sum(A.^2)))*sum(sum(sum(B.^2))));% simplified
                                CC_allcut(id_ysec,id_xsec,id_filter,id_cut) = max(max(max(norm_CCM)));

                                %for id_shift = 1:n_step
                                for id_shift = 1:size(B_shift,4)
                                    SizeB = size(B_shift(:,:,:,id_shift));
                                    %A_resize = imresize(A,SizeB(1),SizeB(2),SizeB(3));
                                    A_resize = A;
                                    norm_CCM_shift = A_resize.*B_shift(:,:,:,id_shift)./sqrt(sum(sum(sum(A_resize.^2)))*sum(sum(sum(B_shift(:,:,:,id_shift).^2))));% var_version
                                    CC_allcut_var(id_ysec,id_xsec,id_filter,id_shift,id_cut) = max(max(max(norm_CCM_shift)));% var_version
                                end
                                
                            end
                            %if max(max(max(norm_CCM))) == 0
                            %    fprintf('0');
                            %else
                            %    fprintf('.');
                            %end
                        end
                        fprintf('.');
                    end

                case 'c'
                    %-------------------------------------------------
                    % OFFset value is common for all 10x10
                    % calculating offset, this mode is also slow
                    ListIntensity = reshape(sum(sum(Movie_resize,2),1),[],1);
                    ListIntensity_cut = ListIntensity;% ????????
                    if yn_flip_T == 'y'
                        OnFrameIn = min(find(ListIntensity_cut == min(ListIntensity_cut)));
                        offset_t = OnFrameIn - MF.OnFrame;
                    else
                        OffFrameIn = min(find(ListIntensity_cut == min(ListIntensity_cut)));
                        offset_t = OffFrameIn - MF.OffFrame;
                    end
                    start_total = ListFrame_startstop{id_movie}(1,id_cut) + offset_t;% frames can be next cut
                    stop_total = start_total + nFrame_filter - 1;% frames can be next cut
                    %-calculating offset
                    InputMovie = Movie_all_resize(:,:,start_total:stop_total);
                    B = double(InputMovie)/256;

                    Range = {'','',0};
                    for id_filter = 1:nFilter
                        A = repmat(MF.RFMap(:,:,:,id_filter),nSection(1),nSection(2),1);
                        %[ CCM, norm_CCM, T] = cc_3D_range( A,B, Range);
                        norm_CCM = A.*B./sqrt(sum(sum(sum(A.^2)))*sum(sum(sum(B.^2))));% simplified
                        for id_xsec = 1:nSection(1)
                            for id_ysec = 1:nSection(2)
                                x_range = side_rf*(id_xsec-1) + 1:side_rf*id_xsec;
                                y_range = side_rf*(id_ysec-1) + 1:side_rf*id_ysec;  
                                CC_allcut(id_ysec,id_xsec,id_filter,id_cut) = max(max(max(norm_CCM(y_range,x_range,:))));
                                %if  max(max(max(norm_CCM(y_range,x_range,:)))) == 0
                                %    fprintf('0');
                                %else
                                %    fprintf('.');
                                %end              
                            end
                            fprintf('.');
                        end
                        fprintf('\n');
                    end

            end
            %-------------------------------------------------
            %-------------------------------------------------
            %CC_allcut(:,:,:,id_cut) = CC;
            fprintf('\n');
        end
        SumCC = reshape(sum(sum(CC_allcut,2),1),size(CC_allcut,3),size(CC_allcut,4));
        AveSumCC = mean(SumCC,2);
        [B,I] = sort(AveSumCC);
        OrderCC = I;


        % show CC 
        for id_cut = 2:nCut(id_movie)-1% to prevent stick out
            CC = CC_allcut(:,:,:,id_cut);
            h(id_cut) = figure('Name',['movie spectrum ' note ' cut#' num2str(id_cut)],'Color','w');hold on;
            maxvalue = abs(prctile(reshape(CC,1,[]),100));
            for id_filter =1:nFilter
                subplot(5,5,id_filter);
                imagesc(floor(255*(CC(:,:,id_filter)/maxvalue)),[0 255]);
            end
            tightfig;
            saveas(h(id_cut), [pn_save_final '\' h(id_cut).Name '.fig'],'fig');
            close(h(id_cut));
        end

        % show 1st frames
        h_1stimage = figure('Name','First frame of each cut','color','w');
        nColumn = 5;nRow = ceil(nCut(id_movie)/5);
        maxscale = max(max(max(Movie_Mat)));
        for id_cut = 1:nCut(id_movie)
            subplot(nRow,nColumn,id_cut);hold on;    
            imagesc(Movie_Mat(:,:,ListFrame_startstop{id_movie}(1,id_cut)),[min(min(min(Movie_Mat))),max(max(max(Movie_Mat)))]);
            %imshow(ceil(3000/maxscale*Movie_Mat(:,:,ListFrame_startstop(1,id_cut))));
            title(['Cut#' num2str(id_cut)]);
             a=gca;a.XLim(2) = size(Movie_Mat,2);a.YLim(2) = size(Movie_Mat,1);
        end
        tightfig;
        saveas(h_1stimage, [pn_save_final '\' h_1stimage.Name '.fig'],'fig');
        close(h_1stimage);

        % save images
        save([pn_save_final '\CC_allcut.mat'],'CC_allcut','AveSumCC','OrderCC','CC_allcut_var');

        pn_im_stack{counter_cc} = [pn_save_final '\CC_' fig_category ];
        mkdir(pn_im_stack{counter_cc});
        for id_cut = 2:size(CC_allcut,4)+1% to prevent stick out
            CC = CC_allcut(:,:,:,id_cut-1);
            for id_neuron = 1:size(CC,3)
                imwrite(CC(:,:,id_neuron),[pn_im_stack{counter_cc} '\' fn_movie(1:end-4) '_Neuron_' num2str(id_neuron) 'Cut_' num2str(id_cut) '.tif']); 

                CC_single = CC(:,:,id_neuron);%2023_08_07
                save([pn_im_stack{counter_cc} '\' fn_movie(1:end-4) '_Neuron_' num2str(id_neuron) 'Cut_' num2str(id_cut) '.mat'],'CC_single');%2023_08_07

                % Tiff Stack below piles up for all neurons, not channnel
                if id_neuron == 1
                    imwrite(CC(:,:,id_neuron),[pn_im_stack{counter_cc} '\Cut_' num2str(id_cut) '.tif']);   
                else
                    imwrite(CC(:,:,id_neuron),[pn_im_stack{counter_cc} '\Cut_' num2str(id_cut) '.tif'],'WriteMode','append');  
                end

            end
        end
        %------------------------------------------------------------------------------------------------
        
    end% if not Movie_mat empty
end
%---------------------------------------------------------------------------------------------------
%---------------------------------------------------------------------------------------------------
%---------------------------------------------------------------------------------------------------
%---------------------------------------------------------------------------------------------------
%---------------------------------------------------------------------------------------------------

