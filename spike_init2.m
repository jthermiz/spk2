function T = spike_init2(A, spk, units, chancount, cfg)
%Creates spike 2.0 structure 
%Example:

n = (cfg.range(2) - cfg.range(1))*A.fs/1e3; %duration in samples
time = linspace(cfg.range(1),cfg.range(2),n);

uds = unique(units); %unit identities
k = numel(uds); %number of unique units
T(k).data = []; 

if isfield(cfg,'label_struct')
    group = cfg.label_struct.group;
    cid = cfg.label_struct.cluster_id;
else
    group = zeros(numel(uds),5); %dummy variable
    cid = uds;
end

id_map = cfg.id_map; %map of cluster ids (col1 new, col2 old)

for i=1:k
    u = cid(i); 
    T(i).time = time;
    T(i).atime = [];
    T(i).idx = [];   
    T(i).unit_type = 4;
    T(i).cid = u;
    T(i).fs = A.fs;
    T(i).chs = [];
    T(i).chs_dat = [];
    T(i).mask = [];
    T(i).file = A.file;
    T(i).ays = cfg.ays_name;
    T(i).interval = cfg.interval; 
    
    
    validx = units == uds(i); %indices of spikes that belong to a particular neuron
    T(i).atime = spk(validx);    
    spknum = numel(T(i).atime); %number of spikes per unit    
    [mask,chs] = sort(chancount(id_map(i,2),:),'descend');
    %[mask,chs] = sort(chancount(i,:),'descend');
    T(i).idx = A.idx(chs(1)); %get rid of since it redundent in the future
    T(i).chs = A.idx(chs);
    T(i).chs_dat = A.idx_dat(chs);
    T(i).mask = mask;
    
    if strcmp(group(i,:),'good ')
        T(i).unit_type = 1;
    elseif strcmp(group(i,:),'mua  ')
        T(i).unit_type = 2;
    elseif strcmp(group(i,:),'noise')
        T(i).unit_type = 3;
    else
        T(i).unit_type = 4; %unsorted
    end
    
end