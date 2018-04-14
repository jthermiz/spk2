function Tr = add_audio_signal(Tr, path)
%adds audio signal to structure. truncates anything greater the maximum
%time of the neural data

audiofile = [path Tr.typename{1} '.wav'];
[~,audio_fs] = audioread(audiofile); %assume all audio files have the same sample rate

%audio_fs = 30e3; %hard-coded
audio_len = round((Tr.time(end)-Tr.time(1))*audio_fs); %number of audio samples
Tr.target = zeros(numel(Tr.typename),audio_len);
Tr.time_target = linspace(Tr.time(1),Tr.time(end),audio_len);
Tr.target_fs = audio_fs;

for i=1:numel(Tr.typename)
    audiofile = [path Tr.typename{i} '.wav'];
    [signal,audio_fs2] = audioread(audiofile);
    if (audio_fs ~= audio_fs2)
        disp(['error assumed wrong sample rate. Acutal is:  ' num2str(audio_fs2)])
    end
    signal = signal(:);    
    len_p = sum(Tr.time_target >= 0);
    len_n = sum(Tr.time_target < 0);
    signal2 = [zeros(len_n,1) ; signal ; zeros(len_p - numel(signal),1)]; %zero pad prior to audio starting        
    Tr.target(i,:) = signal2(1:audio_len); %truncate extra song
end