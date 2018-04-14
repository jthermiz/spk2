function T = spike_data(Tn,cfg) 
%takes spikes 2.0 struct without data, grabs snippets uniformly and creates
%struct with data

% Example:
    % cfg.ch_num = 4; %top 4 channels for each unit
    % cfg.snip_num = 50; %number of snippets (samples snippets uniformly across time)
    % cfg.range = [-1 2];
    % spike_data(Tn,cfg);

d = cfg.ch_num;
s = cfg.snip_num;
len = (cfg.range(2) - cfg.range(1))*Tn(1).fs/1000;
file = convert_raw2hfp_name(Tn(1).file);
iter_num = numel(Tn);

T(iter_num).data = [];

for i=1:iter_num
    i
    tic
    
    %get rid of out of bounds spikes
    new_atime = validate_times(Tn(i).atime);
    Tn(i).atime = new_atime;
    
    %uniformly sample
    step = floor(numel(Tn(i).atime)/s);
    if step > 0
        trs = 1:step:numel(Tn(i).atime);
        trs = trs(1:end-1); %it goes over by 1 bug
    else %if there's not enough spikes do all of them
        trs = 1:numel(Tn(i).atime);        
    end    
    
    %init
    T(i).data = zeros(numel(trs),len,d);
    T(i).time = linspace(cfg.range(1),cfg.range(2),len);
    T(i).atime = Tn(i).atime(trs);
    T(i).idx = Tn(i).chs(1:d);
    T(i).unit_type = Tn(i).unit_type; %need to update spk_pipe to provide these inputs
    T(i).cid = Tn(i).cid; %update
    T(i).fs = Tn(i).fs;    
    
    %get data loop
    j_max = min(s,numel(trs));
    for j=1:j_max             
        t = Tn(i).atime(trs(j));
        kcfg.range = double([t + cfg.range(1)*Tn(1).fs/1000 t + cfg.range(2)*Tn(1).fs/1000]);            
        kcfg.sformat = 1;
        kcfg.stride = 1;    
        kcfg.rhd_convert = cfg.rhd_convert;
        A = cont_kwd(file,kcfg);       
        data = A.data(Tn(i).chs_dat(1:d), :); %channel select (note chs_dat indexes both .dat and .kwd files)
        T(i).data(j,:,:) = data';
    end
    toc
end
    %%%% local functions %%%%
    function y = validate_times(x)
       st = -1*cfg.range(1)*Tn(1).fs/1000+1;
       idx = x>st;
       y = x(idx);       
    end

end