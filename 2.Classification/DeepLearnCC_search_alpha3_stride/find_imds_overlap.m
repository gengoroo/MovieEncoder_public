function ListIdx = find_imds_overlap(imds_master,imds_sub)
    for idx = 1:numel(imds_sub.Files)
        ListIdx(idx,1) = find(~cellfun(@isempty,strfind(imds_master.Files, imds_sub.Files{idx})));
    end
end