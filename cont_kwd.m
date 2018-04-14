function A = cont_kwd(kwdfile, cfg)
%load continous data into structure
%Example:
%kwdfile = experiment.raw.kwd;
%cfg = [];
%cfg.range = [0 30e3];
%cfg.sformat = 1;
%cfg.rhd_convert = 1;
%A= cont_kwd(kwdfile, cfg);

if isfield(cfg,'range')
    part_data = 1;
else
    part_data = 0;
end

if isfield(cfg,'sformat')
    if cfg.sformat == 1
        sformat = 1;
    else
        sformat = 0;
    end
else
    sformat = 0;
end


%raw recording metadata
info = h5info(kwdfile,'/recordings/0');
chtot = info.Datasets(1).Dataspace.Size(1);
samptot = info.Datasets(1).Dataspace.Size(2);
fs = info.Attributes(2).Value(1); 
convfactor = 0.195; %hardcorded since it never changes

% if cfg.rhd_convert -- DELETE SOON
%     convfactor = info.Groups.Attributes(3).Value(1); 
%     fs = info.Groups.Attributes(2).Value(1); %assume sample rate the same for all channels
% else    
%     convfactor = info.Groups.Attributes(1).Value(1); %assume conversion factor the same for all channels
%     %convfactor = h5read(kwdfile,'/recordings/0/application_data/channel_bit_volts');
%     convfactor = convfactor(1);
%     fs = info.Attributes(2).Value(1); %assume sample rate the same for all channels
%     %fs = info.Attributes(4).Value(1); %assume sample rate the same for all channels
% end

fs = double(fs); %raw data sample rate
convfactor = double(convfactor);

%read data
if part_data
    if sformat == 1 %cfg range units provided as samples
        a = cfg.range(1);
        T = cfg.range(2) - cfg.range(1);
    else
        a = round(cfg.range(1)*fs)+1;
        T = round((cfg.range(2) - cfg.range(1))*fs);
    end
else
    a = 1;
    T = samptot;
end
startindices = [1, a];
countindices = [chtot, T];
dat = h5read(kwdfile,'/recordings/0/data',startindices,countindices); %can optimize by setting A.data directly

%structure
A.data = single(dat)*convfactor;
A.idx = 1:size(A.data,1); %figure out actual channel names later!
A.idx_dat = 1:size(A.data,1); %index for .dat file (start counting from 1)
A.fs = fs;
A.file = kwdfile;

if part_data
    if sformat == 1
        A.time = linspace(cfg.range(1)/fs, cfg.range(2)/fs, T);
    else
        A.time = linspace(cfg.range(1), cfg.range(2), T);
    end
else
    A.time = linspace(0,samptot/A.fs,samptot);
end

A.interval = [0 double(samptot)/double(fs)];
end