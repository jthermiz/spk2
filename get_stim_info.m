function stim = get_stim_info(kwefile)
%Get stimulus information
%Example:
    %kwefle = 'experiment.sng.kwe';
    %stim = get_stim_info(kwefile);

%event information
evinfo = h5info(kwefile);
grp_num = numel(evinfo.Groups.Groups.Groups);
tevents = cell(grp_num,1);
trnum = 0;
stim.typename = cell(grp_num,1); %stimulus id

for i=1:grp_num
    grp = evinfo.Groups.Groups.Groups(i).Name;
    tevents{i} = double(h5read(kwefile, [grp '/time_samples']));      
    stimid = strsplit(grp,'/');
    stim.typename{i} = stimid{end};
end

stim.atime = cell2mat(tevents);
stim.type = zeros(size(stim.atime));

a = 1;
for i=1:numel(stim.typename)
    b = a + numel(tevents{i}) - 1;
    stim.type(a:b) = i;
    a = b + 1;
end

