%TiffStackChanger
pn_tiff = uigetdir(pn_crop2,'Select folder of 3Chx3 tiff stack [*_3ChStack]');
FileList = dir(fullfile(pn_tiff,'*tif'));
V = tiffreadVolume([FileList(1).folder '\' FileList(1).name]);
fprintf('Dim of image is %s, Last is Ch number\n',num2str(size(V)));

selector = input('1: XYT 2: XY3Ch x 3 files  3: XY1Ch x 9 files 4: XY1Ch in 3x3 grid bigimage  []=3 \n');
if isempty(selector)
    selector = 3;
end

if selector==3
    pn_label = input('Type pn_label\n','s');
end

for id_file = 1:numel(FileList)
    pn = FileList(id_file).folder;
    fn = FileList(id_file).name;
    V = tiffreadVolume([pn '\' fn]);


    switch selector
        case 1 
            pn_save = [pn, '\' num2str(size(V_write,2)*size(V_write,3))  'Chx1'];
            if ~exist(pn_save)
                mkdir(pn_save);
            end
            V_write = reshape(V,size(V,1),size(V,2),[]);% YxXxnCh
            for id_slice = 1:size(V_write,3)
                if id_slice == 1
                    imwrite(V_write(:,:,id_slice),[pn_save '\' fn]);
                else
                    imwrite(V_write(:,:,id_slice),[pn_save '\' fn],'WriteMode','Append');
                end
            end
        case 2
            nSlice = size(V,3);
            for id_slice = 1:nSlice
                pn_save{id_slice} = [pn, '\SliceOf3ch' num2str(id_slice)];
                if ~exist(pn_save{id_slice})
                    mkdir(pn_save{id_slice});
                end
                V_write = reshape(V(:,:,id_slice,:),size(V,1),size(V,2),[]);% YxXx2
                imwrite(V_write,[pn_save{id_slice} '\' fn]);
            end
        case 3
            nSlice = size(V,3)*size(V,4);
            for id_slice = 1:nSlice
                [pn_parent, pn_current] = fileparts(pn);
                pn_save{id_slice} = [pn_parent '\' pn_current '\SliceOf1Ch' num2str(id_slice) '\' pn_label];
                if ~exist(pn_save{id_slice})
                    mkdir(pn_save{id_slice});
                end
                id_a = ceil(id_slice/size(V,3));
                id_b = rem(id_slice,size(V,3)) + 1;
                V_write = V(:,:,id_a,id_b);
                imwrite(V_write,[pn_save{id_slice} '\' fn]);
            end

        case 4
            pn_save = [pn, '\' num2str(size(V,3)) 'Chx' num2str(size(V,3)) 'Ch_BigImage'];
            if ~exist(pn_save)
                mkdir(pn_save);
            end
            gridsize = 5;
            V_write = zeros([size(V,1)*size(V,3), size(V,2)*size(V,4)]);

            [X,Y] = meshgrid(1:size(V,1)/gridsize, 1:size(V,2)/gridsize);
            StartX = (size(V,3)*gridsize*(X-1) + 1);
            StartY = (size(V,4)*gridsize*(Y-1) + 1);
            StopX = (size(V,3)*gridsize*(X));
            StopY = (size(V,4)*gridsize*(Y));

            for id_block1 = 1:size(V,1)/gridsize
                for id_block2 = 1:size(V,2)/gridsize
                    for id_ch = 1:size(V,3)
                        for id_stack = 1:size(V,4)
                            ReadDim1range = (gridsize*(id_block1-1)+1):gridsize*id_block1;
                            ReadDim2range = (gridsize*(id_block2-1)+1):gridsize*id_block2;
                            im_copy = reshape(V(ReadDim1range,ReadDim2range,id_ch,id_stack),gridsize, gridsize);
                            if id_stack == 1
                                im_copy_dim1cat = im_copy;
                            else
                                im_copy_dim1cat = cat(1, im_copy_dim1cat,im_copy);
                            end
                        end
                        if id_ch == 1
                            im_copy_dim12cat = im_copy_dim1cat;
                        else
                            im_copy_dim12cat = cat(2,im_copy_dim12cat,im_copy_dim1cat);
                        end
                    end
                    V_write(StartX(id_block1,id_block2):StopX(id_block1,id_block2), StartY(id_block1,id_block2):StopY(id_block1,id_block2)) = im_copy_dim12cat;
                end
            end
            imwrite(uint8(round(V_write)),[pn_save '\' fn]);
    end
    
end