function Tr = epoch_spike2(T, stim, cfg)
%Example:
    %kwefile = [filepath 'experiment.sng.kwe'];
    %ecfg = [];
    %ecfg.range = [-2 2];
    %ecfg.bin = 5; %ms
    %stim = get_stim_info(kwefile);
    %Tr = epoch_spike(Tn,stim,ecfg); %ensure spike data is from the whole experiment


d = numel(T); %number of channels
n = numel(stim.atime); %number of trials
len = (cfg.range(2) - cfg.range(1))*T(1).fs; %number of samples in trials
fs = T(1).fs;
bin = cfg.bin; %ms
binsamp = (bin/1000)*fs; %convert to samples
len2 = ceil(len/binsamp);

Tr.data = zeros(n,len2,d);
Tr.time = linspace(cfg.range(1),cfg.range(2),len2);
Tr.atime = stim.atime;
Tr.idx = zeros(d,1);
Tr.type = stim.type;
Tr.unit_type = zeros(d,1);
Tr.fs = 1/(bin/1000);
Tr.typename = stim.typename; 

sig = zeros(ceil(len/binsamp)*binsamp,1);
for i=1:d
    spktimes = T(i).atime;
    Tr.idx(i) = T(i).idx;
    Tr.unit_type(i) = T(i).unit_type; %newly added
    for j=1:n
        tmp = zeros(1,len);
        to = stim.atime(j)+cfg.range(1)*fs; %start of trial (in samples)
        te = stim.atime(j)+cfg.range(2)*fs -1; %end of trial (in samples)
        valtimes = spktimes(and(to < spktimes, te > spktimes));
        reltimes = valtimes - to;
        tmp(reltimes) = 1; %orginal sample rate data      
        sig(1:len) = tmp(:);
        tmp2 = reshape(sig,binsamp,numel(sig)/binsamp);
        Tr.data(j,:,i) = sum(tmp2); %binned signal        
    end
end

end