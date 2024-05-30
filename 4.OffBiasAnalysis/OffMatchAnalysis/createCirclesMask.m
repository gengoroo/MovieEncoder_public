function mask = createCirclesMask(varargin)
    narginchk(3,3)
    if numel(varargin{1}) == 2
	    % SIZE specified
	    xDim = varargin{1}(1);
	    yDim = varargin{1}(2);
    else
	    % IMAGE specified
	    [xDim,yDim] = size(varargin{1});
    end
    centers = varargin{2};
    radii = varargin{3};
    xc = centers(:,1);
    yc = centers(:,2);
    [xx,yy] = meshgrid(1:yDim,1:xDim);
    mask = false(xDim,yDim);
    for ii = 1:numel(radii)
	    mask = mask | hypot(xx - xc(ii), yy - yc(ii)) <= radii(ii);
    end
end
