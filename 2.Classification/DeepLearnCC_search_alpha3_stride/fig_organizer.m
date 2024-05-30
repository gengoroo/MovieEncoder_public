function fig_organizer(List_fig, varargin)

    %fprintf('Switch "graph_ratio", "nFig_yoko","Menu none(def) on"\n');
    %figdata = get(figure(List_fig(1)));
    
	set(0,'Units','pixel');%ピクセルデータを取得
    scrsz = get(groot,'ScreenSize');
    
    figure(List_fig(1));%最初のfigをサンプルとしてデータ取得
    [nrows, ncols] = info_subplot();
    
    ratio = (scrsz(3)/ncols)/(scrsz(4)/nrows);
    
	takasa_winmenu=45;
    
    
    %set(0,'Units','normalized');%設定を正規化する
    nFig=length(List_fig);
    nFig_tate_temp=sqrt((nFig/ratio));
    nFig_yoko = ceil(nFig_tate_temp*ratio);
    nFig_tate = ceil(nFig/nFig_yoko);
    yn_define_graph_ratio=[];
    
    for ii=1:nargin-1
        if strcmp(varargin{ii},'graph_ratio')&&nargin>=ii+2
            yn_define_graph_ratio = 'y';
            graph_ratio=varargin{ii+1};%比率指定していたら。
            ratio = ratio/graph_ratio;%上書き。
            nFig_tate_temp=sqrt((nFig/ratio));%上書き
            nFig_yoko = ceil(nFig_tate_temp*ratio);%上書き
            nFig_tate = ceil(nFig/nFig_yoko);%上書き
        end
        if strcmp(varargin{ii},'nFig_yoko')&&nargin>=ii+2
            nFig_yoko=varargin{ii+1};%横パネルの数指定していたら。
            nFig_tate = ceil(nFig/nFig_yoko);
            %fprintf('nFig_yoko=%d\n',nFig_yoko);
        end
        if strcmp(varargin{ii},'nFig_tate')&&nargin>=ii+2
            nFig_tate=varargin{ii+1};%縦パネルの数指定していたら。
            %fprintf('nFig_tate=%d\n',nFig_tate);
        end
        if strcmp(varargin{ii},'menu')&&nargin>=ii+2
           yn_menu = varargin{ii+1};
           %fprintf('Menu=%s\n',yn_menu);
        end
    end
    
    if exist('yn_menu','var')
        for ii=1:length(List_fig)
            figure(List_fig(ii));
            if yn_menu == 'n'
                h=gcf; set(h,'MenuBar','NONE');
                takasa_menubar=35;
            else
                h=gcf; set(h,'MenuBar','figure');
                takasa_menubar=100;
            end
        end 
    end
    
    haba = floor(scrsz(3)/nFig_yoko);
    takasa = floor((scrsz(4)-takasa_winmenu)/nFig_tate);
    
    for ii=1:nargin-1
        if strcmp(varargin{ii},'graph_ratio')&&nargin>=ii+2
            graph_ratio=varargin{ii+1};
            takasa = haba*graph_ratio;
        end
    end
    
    x_end = scrsz(3)-haba;
    y_start = scrsz(4)-takasa;
    
    x_step = x_end/max(1,(nFig_yoko-1));
    y_step = (y_start - takasa_winmenu)/max(1,(nFig_tate-1));
    
    if x_end>0
        X_grid = 0:x_step:x_end;
    else
        X_grid = 0;
    end
    if y_start>0
        Y_grid = y_start:-y_step:0;
    else
        Y_grid = 0;
    end
    
    X_pos = repmat(X_grid, 1, nFig_tate);
    Y_pos = reshape(repmat(Y_grid, nFig_yoko, 1),1,[]);
    if numel(Y_pos) == 0
        Y_pos = repmat(X_grid,numel(List_fig),1);
    end
    
    if (nrows>1)||(nrows>1)%サブプロットされていたら
        for ii=1:length(List_fig)
            figure(List_fig(ii))
            if yn_define_graph_ratio == 'y'%比率指定していたら。
                sub_fig = get(gcf,'Children');%正方形に
                ListResize = isprop(sub_fig,'PlotBoxAspectRatio');
                set(sub_fig(ListResize),'PlotBoxAspectRatio',[1 1/(graph_ratio) 1]);
            end
            tightfig;
        end
    end    
    if ~exist('takasa_menubar','var')
        takasa_menubar = 50;
    end
    for ii=1:length(List_fig)
        set(figure(List_fig(ii)),'Position', [X_pos(ii), Y_pos(ii), haba-15, takasa-takasa_menubar]);
    end   
end