%plot_smoother
%void = input('Open fig and select line to smooth, enter to continue\n');
hold on;
h=gcf;
List_smooth = findall(h,'Type','Line');
n_ave = 5;%input('Type n of movememean');

for ii = 1:numel(List_smooth)
    XData = List_smooth(ii).XData;
    YData = List_smooth(ii).YData;
    YData_new = movmean(YData, n_ave);
    h = plot(XData,YData_new,'.');
    h.Color = List_smooth(ii).Color*0.75;
    h.LineStyle = '--';
    h.LineWidth = List_smooth(ii).LineWidth;
    h.Marker = List_smooth(ii).Marker;
    h.MarkerSize = List_smooth(ii).MarkerSize;
    h.Marker = List_smooth(ii).Marker;
end
