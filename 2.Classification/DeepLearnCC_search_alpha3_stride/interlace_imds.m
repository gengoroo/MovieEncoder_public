function imds_interlace = interlace_imds(imds,n_interlace)
    nFiles = numel(imds.Files);
    counter = 0;
    for ii = 1:n_interlace
        List_seq{ii} = ii:n_interlace:nFiles;
        List(ii,1) = counter + 1;
        List(ii,2) = counter + numel(List_seq{ii});
        counter = List(ii,2);
        ListReorder(List_seq{ii}) = List(ii,1):List(ii,2);
    end
    Folders = imds.Folders;
    Labels = imds.Labels;
    imds_interlace = imds;
    imds_interlace.Files = imds.Files(ListReorder);
    imds_interlace.Labels = Labels(ListReorder);
    %imds_shuffle.Folders = Folders;
end