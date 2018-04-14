function [z,id_map] = label_units(x,y)

yset = sort(unique(y));
yn = numel(yset);
z = y;

id_map = zeros(numel(yset),2);
id_map(:,1) = yset;

for i=1:yn    
    tmp = y == yset(i);
    idx = find(tmp,1);
    z(tmp) = x(idx);    
    id_map(i,2) = x(idx);
end

end

