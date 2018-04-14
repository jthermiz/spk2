function gen_dat_hfp(cfg)
%High pass filters experiment.raw.kwd file and saves as experiment.hfp.kwd
%Example:
    % gcfg.file_name = 'experiment.raw.kwd';
    % gcfg.path_name = '/net/expData/birdSong/raw_data/b1114/anesth_surface_depth2017-03-10_14-55-14_400/';
    % gcfg.rhd_convert = 0;
    % gen_hfp_kwd(gcfg);

hfp_file_name = convert_raw2hfp_name(cfg.file_name);

%kwd meta data
kwdfile = [cfg.path_name cfg.file_name];
hfpfile = [cfg.path_name hfp_file_name];

info = h5info(kwdfile,'/recordings/0');
chtot = info.Datasets(1).Dataspace.Size(1);
samptot = info.Datasets(1).Dataspace.Size(2);
fs = info.Attributes(2).Value(1); 
convfactor = 0.195; %hardcorded since it never changes

% if cfg.rhd_convert == 1
%     convfactor = info.Groups.Attributes(3).Value(1); 
%     fs = info.Groups.Attributes(2).Value(1); %assume sample rate the same for all channels
% else
%     convfactor = info.Groups.Attributes(1).Value(1); %assume conversion factor the same for all channels
%     fs = info.Groups.Attributes(3).Value(1); %assume sample rate the same for all channels
% end

fs = double(fs); %raw data sample rate
convfactor = double(convfactor);

hfp_bool = 1; %write hfp file
dat_bool = 1; %write dat file

%open .raw.hfp file
if exist(hfpfile,'file') %if .raw hfp doesn't already exist
    disp('Warning: file already exists! Please use different name. Skipping .hfp write"')    
    hfp_bool = 0;
else
    %copy file
    copyfile(kwdfile,hfpfile);
end

%open .dat file
if exist(cfg.dat_file_name,'file') %if .dat doesn't already exist
    disp('Warning: file already exists! Please use different name. Skipping .dat write"')
    dat_bool = 0;
else
    fid = fopen(cfg.dat_file_name,'a'); %
end

if and(~hfp_bool,~dat_bool)
    disp('.dat and .hfp both exist.. terminating function')
    return
end

%things
block_size_sec = 600; 
block_size = block_size_sec*fs; %for 1 channel
iter_num = ceil(samptot/block_size);
a = 1;
T = block_size;
[den,num] = butter(3,300/(fs/2),'high'); %hard-coded could pass as param in the future

%read data
if hfp_bool
    disp(['Starting to write to ' hfp_file_name])
end
if dat_bool
    disp(['Starting to write to ' cfg.dat_file_name])
end
for i=1:iter_num          
    
    if i == iter_num
        T = samptot-block_size*(i-1);
    end
    
    startindices = [1, a];
    countindices = [chtot, T];
    data = h5read(kwdfile,'/recordings/0/data',startindices,countindices); %can optimize by setting A.data directly
    
    %.dat write
    if dat_bool
        fwrite(fid,data,'int16');  
    end
    
    %filter
    if hfp_bool 
        data = filtfilt(den,num,double(data'))'; %this my cause artifacts at the block edges
        data = int16(round(data)); %convert back to int16

        %hfp write 
        h5write(hfpfile,'/recordings/0/data',data,startindices,countindices);    
    end

    %update pointer
    a = a + block_size;        
    
    disp([num2str((i/iter_num)*100,'%.4g') '%'])

end

end