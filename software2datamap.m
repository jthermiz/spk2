function map_data = software2datamap(map, idx)

map_data = map;
n = numel(idx);

for i=1:n
   [r,c] = find(map == idx(i));
   map_data(r,c) = i;
end

end