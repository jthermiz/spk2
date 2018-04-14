function A = cs_simple(A, cfg)
%Channel select from continous data structure
%Exmaple:
%cfg.chs = A.idx(1:5);
%cfg.invert = 1; %if 1 remove channels, else keep
%B = cs_simple(A,cfg);

iflag = isfield(cfg,'invert');
if iflag
    if cfg.invert == 1
        kp = ~ismember(A.idx,cfg.chs);
    else
        kp = ismember(A.idx,cfg.chs);
    end
else
    kp = ismember(A.idx,cfg.chs);
end

for i=1:numel(A)
    A(i).data = A(i).data(kp,:);
    A(i).idx = A(i).idx(kp);
    if isfield(A, 'imp')
        A(i).imp = A(i).imp(kp);
    end
    if isfield(A,'idx_name')
        A(i).idx_name = A(i).idx_name(kp,:);
    end
    if isfield(A,'idx_dat')
        A(i).idx_dat = A(i).idx_dat(kp);
    end
end

end