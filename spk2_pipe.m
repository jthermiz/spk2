%function spk2_pipe(file)

% main script for running spike pipeline 

%User Input
file = 'anesth_surface_depth_500';
subject = 'b1060';

svbool = 0; %save spike and epoch data
man_bool = 1; %manually inspect spikes
chan_num = 64; 

rootpath = '/net/expData/birdSong/ss_data/';
subjectpath = [rootpath subject];
filepath = [subjectpath '/' file '/'];

cfg = [];
cfg.kwd_file = [filepath 'experiment2.raw.kwd'];
cfg.path_name = ['res/' subject '/' file '/' ]; %path to save results
%cfg.path_name = [filepath '/kilo_00'];
cfg.exp_name = [subject '_' file];
cfg.ays_name = [cfg.exp_name];
cfg.filepath = filepath;
map = csvread([filepath 'electrode_map.csv']);

%% Load MetaData

kcfg.range = [0 1];
kcfg.rhd_convert = 1;
A = cont_kwd(cfg.kwd_file,kcfg);
ccfg = []; ccfg.chs = A.idx(1:chan_num); 
B = cs_simple(A,ccfg);

%% Generate Supporting Files

gcfg.file_name = cfg.kwd_file;
gcfg.path_name = '';
gcfg.rhd_convert = 1;
gcfg.dat_file_name = [filepath 'experiment.dat'];
gen_dat_hfp(gcfg);

%% Run Kilosort
if ~exist(cfg.path_name, 'dir'); mkdir(cfg.path_name); end

pathToYourConfigFile = '.'; 

% Make mapping info
%map = [];
map = csvread([filepath 'electrode_map.csv']);
cfg.chan_num = chan_num; cfg.chs = ccfg.chs; %channels to keep 
make_chan_map(A,map,cfg); %save output chanMat

% Make options struct
ops = config(A,cfg);

% This part runs the normal Kilosort processing on the simulated data
[rez, DATA, uproj] = preprocessData(ops); % preprocess data and extract spikes for initialization
rez                = fitTemplates(rez, DATA, uproj);  % fit templates iteratively
rez                = fullMPMU(rez, DATA);% extract final spike times (overlapping extraction)

% save python results file for Phy
rezToPhy(rez, cfg.path_name);

fprintf('Kilosort took %2.2f seconds. Ideal config is GTX 1080 + M2 SSD \n', toc)

% now fire up Phy and check these results. There should still be manual
% work to be done (mostly merges, some refinements of contaminated clusters). 
%% AUTO MERGES 
% after spending quite some time with Phy checking on the results and understanding the merge and split functions, 
% come back here and run Kilosort's automated merging strategy. This block
% will overwrite the previous results and python files. Load the results in
% Phy again: there should be no merges left to do (with the default simulation), but perhaps a few splits
% / cleanup. On realistic data (i.e. not this simulation) there will be drift also, which will usually
% mean there are merges left to do even after this step. 

rez = merge_posthoc2(rez);

% save python results file for Phy
rezToPhy(rez, cfg.path_name);

%% save and clean up
% save matlab results file for future use (although you should really only be using the manually validated spike_clusters.npy file)
if ~exist(cfg.path_name, 'dir'); mkdir(cfg.path_name); end
save(fullfile(cfg.path_name,  'rez.mat'), 'rez', 'ops', '-v7.3');

% remove temporary file
delete(ops.fproc);
clearvars DATA

%% load rez 

if ~exist('rez','var')
    load(fullfile(cfg.path_name,'rez.mat'));
end

spk_times = rez.st3(:,1);
units = rez.st3(:,2);

%% load stage two cluster ids and update units' id

%spk_times = readNPY(fullfile(cfg.path_name, 'spike_times.npy'));
units2 = readNPY(fullfile(cfg.path_name, 'spike_clusters.npy'));
[~,id_map] = label_units(units,units2); %change cluster id from new back to old numbering

%% load templates

templates = readNPY(fullfile(cfg.path_name, 'templates.npy'));
chancount = map_template2chan(templates);

%% structure into spike 2.0 structure

ccfg = [];
ccfg.range = [-1 2];
ccfg.data_bool = 0;
ccfg.ays_name = cfg.ays_name;
ccfg.interval = B.interval;
ccfg.id_map = id_map;

Tn = spike_init2(B, spk_times, units2, chancount, ccfg); %add spike label from cluster_group.tsv

%% spike struct with data

dcfg = [];
dcfg.range = [-1 2];
dcfg.snip_num = 20;
dcfg.ch_num = 1;
dcfg.rhd_convert = kcfg.rhd_convert;
T = spike_data(Tn,dcfg);

%% load units

if man_bool %manually label based on waveform and isi
    [Tn,T] = label_units2(Tn,T);
end

%% count surface and depth sua

n = numel(Tn);
surface_sua = 0;
depth_sua =0;
for i=1:n
    if Tn(i).unit_type == 1
        if Tn(i).idx > 33
            depth_sua = depth_sua + 1;
        else
            surface_sua = surface_sua + 1;
        end
    end
end

surface_sua
depth_sua    

%% save spike data

if svbool
    savefile = [cfg.path_name cfg.ays_name '_spike-ns'];    
    save(savefile,'Tn','map');    
    savefile = [cfg.path_name cfg.ays_name '_spike'];
    save(savefile,'T','map','-v7.3');    
    disp('Saved')
end

%% epoch spike data

kwefile = [filepath 'experiment.sng.kwe'];
stim = get_stim_info(kwefile);
tmp = zeros(numel(stim.typename),1);

for i=1:numel(stim.typename)
    audiofile = [rootpath(1:end-8) 'stim_data/' subject '/001/' stim.typename{i} '.wav'];
    [signal,audio_fs] = audioread(audiofile);

    tmp(i) = ceil(numel(signal)/audio_fs);
end

song_len = max(tmp); %find maximum song length of all audio files played

ecfg = [];
ecfg.range = [-1 song_len];
ecfg.bin = 5;
Tr = epoch_spike(Tn,stim,ecfg); %ensure spike data is from the whole experiment

%% add audio signal to epoch struct 

audiopath = [rootpath(1:end-8) 'stim_data/' subject '/001/'];
Tr = add_audio_signal(Tr, audiopath);

%delete in the near future!!!
% audio_len = round((Tr.time(end)-Tr.time(1))*audio_fs); %number of audio samples
% Tr.target = zeros(numel(Tr.typename),audio_len);
% Tr.time_target = linspace(Tr.time(1),Tr.time(end),audio_len);
% Tr.target_fs = audio_fs;
% 
% for i=1:numel(Tr.typename)
%     audiofile = [rootpath(1:end-8) 'stim_data/' subject '/001/' Tr.typename{i} '.wav'];
%     signal = audioread(audiofile);
%     signal = signal(:);
%     len_p = sum(Tr.time_target >= 0);
%     len_n = sum(Tr.time_target < 0);
%     signal2 = [zeros(len_n,1) ; signal ; zeros(len_p - numel(signal),1)]; %zero pad prior to audio starting    
%     Tr.target(i,:) = signal2;
% end

%% save epooch data

if svbool
    savefile = [cfg.path_name cfg.ays_name '_epoch'];
    save(savefile,'Tr','-v7.3');
    disp('Saved')
end

