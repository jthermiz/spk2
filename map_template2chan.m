function chancount = map_template2chan(templates)

[nunits,dur,nchan] = size(templates);
chancount = zeros(nunits,nchan);

for k=1:nunits
    X = squeeze(templates(k,:,:));
    chancount(k,:) = sum(abs(X));    
end