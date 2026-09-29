%% Antenna-to-Bits 2026 — IMS Booth Demo (linear, live walkthrough)
clear; clc; close all

scriptDir = fileparts(mfilename("fullpath"));
helpersDir = fullfile(scriptDir, "helpers");
originalFolder = pwd;
folderCleanup = onCleanup(@() cd(originalFolder));
addpath(scriptDir);
addpath(helpersDir);
cd(helpersDir);
%% Initial design 4 elements transmitters
% The first four elements: IF filter+LNA+Tuner+Splitter are representative
% of 1 tile beamformer. This is followed by a PA and the antenna array,
% initially built with 4 dipoles.
%% Global parameters
fIF = 4e9;
fLO = 8e9;
fRF = fIF+fLO;
lambda = physconst("LightSpeed")/fRF;
BW = 100e6;
N = 4;
loadOutWaveforms = true;
%% Stage 1 - IF filter
ifFilter = rffilter("Name","IFfilter", FilterType="InverseChebyshev",...
    ResponseType="Bandpass", FilterOrder=5, ...
    PassbandFrequency=[-BW/2 BW/2]+fIF, PassbandAttenuation=3);
rfplot(ifFilter, linspace(-BW*2+fIF, BW*2+fIF, 101));
ifFilterGP = groupdelay(ifFilter, linspace(-BW*2+fIF, BW*2+fIF, 101));
figure; plot(linspace(-BW*2+fIF, BW*2+fIF, 101),ifFilterGP); title("IF filter group delay");
elements(1) = ifFilter;
%% Stage 2 - LNA
lnaSparamFileName = fullfile(helpersDir, "CMD240withNF.s2p");
lna = amplifier("Name","LNA",...
    Model="sparam",FileName=lnaSparamFileName, ...
    OIP3=28, OP1dB=19, OPsat=22);
rfplot(lna)
figure; rfplot(sparameters(lnaSparamFileName)); title("LNA S-parameters")
elements(2) = lna;
%% Stage 3 - RF Tuner (RF upconverter)
rfTuner = modulator("Name","RFtuner", Model="mod", LO=fLO, ...
    Gain=6, NF=3, OIP3=32);
rfplot(rfTuner)
elements(3) = rfTuner;
%%  Stage 4 - Wilkinson corporate splitter
d = dielectric('Teflon');
w = wilkinsonSplitter('Substrate',d);
w.Height = 0.75e-3;
w.GroundPlaneWidth =0.05;
e = design(w, fRF);
show(e)
splitterCorporate = design(powerDividerCorporate(NumOutputPorts=N,SplitterElement=e), fRF);
splitterCorporate.PortSpacing = 0.018;
splitterCorporate.GroundPlaneWidth = 0.07;
figure; show(splitterCorporate)
figure; layout(splitterCorporate)
figure; mesh(splitterCorporate,'MaxEdgeLength',lambda/10);
load(fullfile(helpersDir, "WilkinsonSplitterData.mat"));
splitterSparam = sparameters(splitterCorporate,[-2*BW 2*BW]+fRF,...
    'SweepOption','interp');
save(fullfile(helpersDir, "WilkinsonSplitterData.mat"), ...
    'splitterCorporate', 'splitterSparam');
figure; rfplot(splitterSparam); title("Wilkinson corporate splitter S-parameters")
figure; hold on; rfplot(splitterSparam,2,1); title("Splitter insertion loss"); 
plot(splitterSparam.Frequencies/1e9,-10*log10(N),'ro-');
splitter = nport("Name","WilkinsonSplitter",...
    NetworkData=sparameters(splitterSparam));
elements(4) = splitter;
%% Stage 5 - Power Amplifier
% Notice the soft compression typical of GaN devices
pa = amplifier("Name","PA",Model="poly", ...
    Gain=25, NF=6, OIP3=45, OP1dB=33, OPsat=37.5);
rfplot(pa);
elements(5) = pa;
%% Stage 6 Antenna - dipole to start with ...
rfAntenna = design(dipole, fRF);
figure; pattern(rfAntenna, fRF);
patternAntenna=pattern(rfAntenna, fRF);
antennaSparam = sparameters(rfAntenna, [-2*BW, 2*BW]+fRF, ...
    'SweepOption', 'interp');
S = sparameters(rfAntenna,fRF);
figure; rfplot(antennaSparam);
budgetAntenna = rfantenna("Gain",pattern(rfAntenna, fRF,0,0),"Z",...
    s2z(S.Parameters));
elements(6) = budgetAntenna;
%% RF Budget analysis in quasi-linear region (only 1 channel)
PinLin = -20;   % design input power [dBm]
Pin = PinLin; 
b = rfbudget(Elements=elements, InputFrequency=fIF, ...
    AvailableInputPower=Pin, SignalBandwidth=BW)
show(b)
%% Compute expected max EIRP for the TX (N elements)
% First we analyze what is the predicted array output (N elements)
% Power and gain *at the PA output port* (index 5), excluding antenna directivity.
% We estimate the antenna array gain, and coherently add the power
PA_idx = 5;
G2PAout = b.TransducerGain(PA_idx);
PAout = b.OutputPower(PA_idx);

antennaArray  = design(linearArray(Element=rfAntenna), fRF, rfAntenna);
antennaArray.NumElements = N;
figure; show(antennaArray)
figure; pattern(antennaArray, fRF);
arrayDirectivity = peakRadiation(antennaArray, fRF);
arraySparam = sparameters(antennaArray, [-2*BW, 2*BW]+fRF, ...
    'SweepOption', 'interp');
figure; rfplot(arraySparam);
maxEIRP = PAout+arrayDirectivity+10*log10(N);
disp(['Pin (linear)= ' num2str(Pin) 'dBm']);
disp(['Expected PA Pout (budget) = ' num2str(PAout), 'dBm'])
disp(['Expected TX EIRP (linear) = ' num2str(maxEIRP), 'dBm'])
%% Let's increase the power
% Compute Linear Range of Operation
Pin_at_P1dB = elements(PA_idx).OP1dB-G2PAout;
b.AvailableInputPower = Pin_at_P1dB;
b.Solver = 'Friis';
PAoutFriis = b.OutputPower(PA_idx);
show(b)
b.AutoUpdate = true;
b.Solver = 'HarmonicBalance';
PAoutHB = b.OutputPower(PA_idx);
disp(['Pin at 1dB compression= ' num2str(Pin_at_P1dB) 'dBm']);
disp(['HB shows that PA is in compression by ' num2str(PAoutFriis-PAoutHB) 'dB']);

% PAPR input signal estimated ~10dB
PinSat = Pin_at_P1dB-10+3; %margin to drive the PA into nonlinear region.
Pin = PinSat;
b.AvailableInputPower = Pin;
disp(['Pin (saturation) = ' num2str(Pin) 'dBm']);

PAoutHB = b.OutputPower(PA_idx);
disp(['Expected PA Pout at saturation (budget) = ' num2str(PAoutHB), 'dBm'])
maxEIRP = PAoutHB+arrayDirectivity+10*log10(N);
disp(['Expected TX EIRP (saturation) = ' num2str(maxEIRP), 'dBm'])
%% Let's increase the array directivity
rfAntenna = design(patchMicrostripCircular, fRF);
rfAntenna.Radius = 7e-3;
figure; pattern(rfAntenna, fRF);
antennaSparam = sparameters(rfAntenna, [-2*BW, 2*BW]+fRF, ...
    'SweepOption', 'interp');
figure; rfplot(antennaSparam);

antennaArray  = linearArray(Element=rfAntenna,...
    ElementSpacing=max(rfAntenna.Radius*2.1,lambda/2),...
    NumElements=N,Tilt=-90);
figure; pattern(antennaArray, fRF);

arrayDirectivity = peakRadiation(antennaArray, fRF);
maxEIRPpatch = PAoutHB+arrayDirectivity+10*log10(N);
arraySparam = sparameters(antennaArray, [-2*BW, 2*BW]+fRF, ...
    'SweepOption', 'interp');
figure; rfplot(arraySparam);

disp(['Pin = ' num2str(Pin) 'dBm']);
disp(['Expected PA Pout (budget) = ' num2str(PAoutHB), 'dBm'])
disp(['Expected TX EIRP with patch array= ' num2str(maxEIRPpatch), 'dBm'])
%% Let's double the array 
N= 8;
antennaArray  = linearArray(Element=rfAntenna,...
    ElementSpacing=max(rfAntenna.Radius*2.1,lambda/2),...
    NumElements=N,Tilt=-90);
figure; pattern(antennaArray, fRF);
arrayDirectivity = peakRadiation(antennaArray, fRF);
maxEIRPpatch8 = PAoutHB+arrayDirectivity+10*log10(N);
disp(['Expected TX EIRP with 8 patch array= ' num2str(maxEIRPpatch8), 'dBm'])
%% Run 5G signal simulation
rc = "NR-FR1-TM3.1"; % Reference channel
bw = "100MHz"; % Channel bandwidth
scs = "30kHz"; % Subcarrier spacing
dm = "FDD"; % Duplexing mode

Tstep = 1/491.52e6;
Tstop = 0.51e-3;

tmwavegen = hNRReferenceWaveformGenerator(rc,bw,scs,dm);
tmwavegen = makeConfigWritable(tmwavegen);
tmwavegen.Config.SampleRate = 1/Tstep;
tmwavegen.Config.NumSubframes = 1;
[inWaveform,tmwaveinfo,resourcesinfo] = generateWaveform(tmwavegen,...
    tmwavegen.Config.NumSubframes);
inWaveform = inWaveform(1:round(Tstop/Tstep));

% Spectrum of 5G signal  
SpectAnalyzer = spectrumAnalyzer;
SpectAnalyzer.SampleRate = 1/Tstep;
SpectAnalyzer.ReferenceLoad = 1;
SpectAnalyzer.RBWSource= "Property";
SpectAnalyzer.RBW = 1e6;
SpectAnalyzer(inWaveform);

PowMet = powermeter("ReferenceLoad",1,"Measurement","All",...
    "WindowLength",length(inWaveform));
[AvgPow, ~,~] = PowMet(inWaveform);
inWaveform = inWaveform.*10^(-AvgPow(end)/20); %scale to 0dBm
release(PowMet);
[~,~,PAPRIn] = PowMet(inWaveform);
disp(['Input signal PAPR = ' num2str(PAPRIn(end)), 'dBm']);

% EVM Measurement
cfg = struct();
cfg.Evm3GPP = false;
cfg.TargetRNTIs = [];
cfg.PlotEVM = true;
cfg.DisplayEVM = false;
cfg.Label = tmwavegen.ConfiguredModel{1};
cfg.UseWholeGrid = true;
cfg.PdcchEnable = false;
% Compute and display EVM measurements
[evmInfo,eqSym,refSym] = hNRDownlinkEVM(...
    tmwavegen.Config,inWaveform,cfg);
disp(['EVM RMS reference input waveform = ' num2str(evmInfo.PDSCH.OverallEVM.RMS*100) '%']);
%% Run Simulation 
%N = 4;
N = 8;
Pin = PinLin;
%Pin = PinSat;
%rfAntenna = dipole;
rfAntenna = patchMicrostripCircular;
if N==4
    load('modelTX.mat');
    if strcmp(class(rfAntenna),'dipole')
        load DipoleArray_N4.mat;
    else
        load PatchArray_N4.mat;
    end
else
    load('modelTX8.mat');
    if strcmp(class(rfAntenna),'dipole')
        load DipoleArray_N8.mat;
    else
        load PatchArray_N8.mat;
    end
end
open_system(RF_TX);
clear outWaveform;
wvName =wvFileName(Pin, rfAntenna, N);
if loadOutWaveforms
    waveformData = load(fullfile(helpersDir, wvName), "outWaveform");
    outWaveform = waveformData.outWaveform;
else
    outWaveform = RF_TX(inWaveform);
    save(fullfile(helpersDir, wvName), "outWaveform");
end

% Spectral measurement, power, and EVM
release(SpectAnalyzer);
SpectAnalyzer(outWaveform);
SpectAnalyzer.ChannelMeasurements.Type="acpr";
SpectAnalyzer.ChannelMeasurements.Span=BW;
SpectAnalyzer.ChannelMeasurements.AdjacentBW=BW;
SpectAnalyzer.ChannelMeasurements.NumOffsets=1;
SpectAnalyzer.ChannelMeasurements.ACPROffsets=BW*1.05;
SpectAnalyzer.ChannelMeasurements.Enabled=true;
tmp = getMeasurementsData(SpectAnalyzer);
ACLR=max(tmp.ChannelMeasurements.ACPRLower,tmp.ChannelMeasurements.ACPRUpper);
disp(['ACLR = ' num2str(ACLR) 'dBc'])
release(PowMet);
[evmInfo,~,~] = hNRDownlinkEVM(...
    tmwavegen.Config,outWaveform,cfg);
disp(['EVM RMS (at Pin=' num2str(Pin) 'dBm) = ' ...
    num2str(evmInfo.PDSCH.OverallEVM.RMS*100) '%']);
% Simulation shows excellent EVM (0.5%), and high linearity (ACPR~-50dBc)
