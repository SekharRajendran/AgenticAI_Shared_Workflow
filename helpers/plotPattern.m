function plotPattern(Vout)
load("antennaData.mat");
%% Apply excitation to antenna array
patchArray.AmplitudeTaper = abs(Vout);
patchArray.PhaseShift = angle(Vout)/pi*180;
%% Array Analysis 
figure;
pattern(patchArray, 27e9); 
figure;
pattern(patchArray, 27e9, (0:5:360), 0);