function [nrows, ncols] = info_subplot()
    ax = findobj(gcf,'type','axes');
    if numel(ax)>2
        get(ax,'position');
        pos = cell2mat(get(ax,'position'));
        ncols = numel(unique(pos(:,1))); % same Y positions
        nrows = numel(unique(pos(:,2))); % same X positions
    else
        nrows = 1;
        ncols = 1;
    end
end