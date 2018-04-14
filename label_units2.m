function [Tn,T] = label_units2(Tn,T)

n = numel(T);
disp('Enter unit type: ')

for i=1:n
        
    k = i;
    ch = 1;
    subplot(1,2,1)
    m = min(20,numel(T(k).atime));
    snippets = T(k).data(1:m,:,ch)';
    plot(T(k).time,snippets)
    %ylim([-100 100])
    title(['Type: ' num2str(T(k).unit_type) ', Chan/Unit: ' num2str(T(k).idx(ch)) '/' num2str(T(k).cid)]);
    grid on
    subplot(1,2,2)
    isi = 1000*diff(Tn(k).atime)/Tn(k).fs;
    histogram(isi,0:1:51)
    xlim([0 50])
    title(['Spike Rate: ' num2str(1/mean(isi)*1000) ' Hz']) %need to find better way
        
    res = input('');
    T(i).unit_type = res;
    Tn(i).unit_type = res;
end