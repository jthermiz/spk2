function hfp_name = convert_raw2hfp_name(raw_name)

tmp = strsplit(raw_name,'.');
tmp{end-1} = 'hfp';
hfp_name = strjoin(tmp,'.');

end