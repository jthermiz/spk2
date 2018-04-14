function make_chan_map(A,map,cfg)
% create a channel Map file for simulated data (eMouse)

% here I know a priori what order my channels are in.  So I just manually 
% make a list of channel indices (and give
% an index to dead channels too). chanMap(1) is the row in the raw binary
% file for the first channel. chanMap(1:2) = [33 34] in my case, which happen to
% be dead channels. 

chanMap = A.idx_dat;

% the first thing Kilosort does is reorder the data with data = data(chanMap, :).
% Now we declare which channels are "connected" in this normal ordering, 
% meaning not dead or used for non-ephys data

connected = ismember(A.idx,cfg.chs);

% now we define the horizontal (x) and vertical (y) coordinates of these
% 34 channels. For dead or nonephys channels the values won't matter. Again
% I will take this information from the specifications of the probe. These
% are in um here, but the absolute scaling doesn't really matter in the
% algorithm. 

idx = A.idx;
idx_dat = A.idx_dat;

if isempty(map) %assume electrode are arranged in a line
    n_chan = (numel(idx_dat));
    xcoords = zeros(n_chan,1);
    ycoords = 0:100:(n_chan - 1)*100;
    %kcoords = ones(n_chan,1);
else
    map_data = software2datamap(map, idx); %convert map to data row map
    loc = get_coord(map_data,idx_dat);
    xcoords = loc(:,1);
    ycoords = loc(:,2);    
end

% Often, multi-shank probes or tetrodes will be organized into groups of
% channels that cannot possibly share spikes with the rest of the probe. This helps
% the algorithm discard noisy templates shared across groups. In
% this case, we set kcoords to indicate which group the channel belongs to.
% In our case all channels are on the same shank in a single group so we
% assign them all to group 1. 

if ~exist('kcoords','var')
    extras = numel(A.idx) - cfg.chan_num;
    n_surface = sum(and(A.idx > 0, A.idx < 33)); %need a better solution in the future
    n_depth = sum(and(A.idx > 32, A.idx < 65));
    kcoords = [ones(1,n_surface) 2*ones(1,n_depth) nan(1,extras)]; %hardcorded for now!    
end

% at this point in Kilosort we do data = data(connected, :), ycoords =
% ycoords(connected), xcoords = xcoords(connected) and kcoords =
% kcoords(connected) and no more channel map information is needed (in particular
% no "adjacency graphs" like in KlustaKwik). 
% Now we can save our channel map for the eMouse. 

% would be good to also save the sampling frequency here

save(fullfile(cfg.path_name, 'chanMap.mat'), 'chanMap', 'connected', 'xcoords', 'ycoords', 'kcoords')