function [Accuracy_total, N_total, Accuracy_each, N_each] = calc_score(imds,Response)
    Labels = unique(imds.Labels);
    N_total = numel(imds.Labels);
    Accuracy_total = numel(find(imds.Labels==Response))/N_total;
    for id_label = 1:numel(Labels)
        ListPick = find(imds.Labels == Labels(id_label));
        N_each(id_label) = numel(ListPick);
        Accuracy_each(id_label) = numel(find(imds.Labels(ListPick)==Response(ListPick)))/N_each(id_label);
    end
end