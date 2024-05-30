fn_full = mfilename('fullpath');
delimieter = strfind(fn_full,'\');
pn_code = fn_full(1:delimieter(end)-1);
clear ListFn_FigTool;

fprintf(['Run by the following order\n'...
    '1:MovCrop_1st, remove unused area and time\n'...
    '2:SelectMovieFileFrame, select scenes by intensity\n'...
    '3:MovCrop_2nd, cut out scenes to use\n'...
    '4:MakeMovieFilter, make MovieFilter and calc CC\n'...
    '5:DeepLearn_movie, perform deep learning\n\n'...
    'Followings are for single Neuron learning\n\n'...
    '6:SortNeuronCC, copy CC.tif into different Neuron folders\n'...
    '7:DeepLearn_movie, perform deep learning\n\n']);

Info = dir(pn_code);
kk=0;
for ii=1:numel(Info)
    if strfind(Info(ii).name,'.m')
        kk=kk+1;
        ListFn_FigTool(kk).name = Info(ii).name;
    end
end
for kk=1:numel(ListFn_FigTool)
    fprintf('%d : %s\n',kk,ListFn_FigTool(kk).name);
end
selector = input('Select code#\n\n');
expression = ListFn_FigTool(selector).name(1:end-2);
eval(expression);