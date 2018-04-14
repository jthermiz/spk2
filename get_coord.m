function loc = get_coord(map_data, idx_dat)
%Construct probe file based on re-indexed map
%Example:
%   idx_dat = A.idx_dat %(e.g [1 2 4]
%   map_data =reshape(1:9,3,3);
%   construct_probe_file(map_data);

n_chan = numel(idx_dat);
loc = zeros(numel(n_chan),2);
[nr,nc] = size(map_data);

pitch = 100; %for visualizations

for i=1:n_chan
    
    [r,c] = find(map_data == idx_dat(i));
    if isempty(r)
        continue;
    end  
    
    loc(i,:) = [c (nr- r)]*pitch; %phy plots x,y reversed for some reason    
end

