function finalist = find_finalist(ListA, ListB, ListC, ListD)

            List_maxA = find(ListA == max(ListA));
            if numel(List_maxA) == 1
                finalist = List_maxA;
            else
                List_maxB = find(ListB(List_maxA) == max(ListB(List_maxA)));
                List_2ndMax = List_maxA(List_maxB);
                if numel(List_2ndMax) == 1
                    finalist = List_2ndMax;
                else
                    List_maxC = find(ListC(List_2ndMax) == max(ListC(List_2ndMax)));
                    List_3rdMax = List_2ndMax(List_maxC);
                    if numel(List_3rdMax) == 1
                        finalist = List_3rdMax;
                    else
                        List_maxD = find(ListD(List_3rdMax) == max(ListD(List_3rdMax)));
                        List_4htMax = List_3rdMax(List_maxD);
                        if numel(List_4htMax) == 1
                            finalist = List_4htMax;
                        else
                            finalist = List_4htMax(randperm(numel(List_4htMax)));
                            fprintf('randomly picked from %d samples',finalist);
                        end
                    end
                end
            end

end