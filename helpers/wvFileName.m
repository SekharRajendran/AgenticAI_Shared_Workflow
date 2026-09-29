function wvName =wvFileName(Pin, rfAntenna, N)
if Pin < -18
    str1 = 'PinLow';
else
    str1 = 'PinHigh';
end
if strcmp(class(rfAntenna),'dipole')
    str2 = 'Dipole';
else
    str2 = 'Patch';
end
str3 = ['N' num2str(N)];
wvName = strcat(str1, '_', str2, '_', str3, '_TXoutWaveform.mat');
