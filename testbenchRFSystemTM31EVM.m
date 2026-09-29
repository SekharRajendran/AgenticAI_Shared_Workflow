%% 5G NR TM3.1 EVM Testbench for RF_TX_Model rfsystem
% Generates a 100 MHz NR-FR1-TM3.1 waveform, drives the saved RF_TX
% rfsystem object, and measures PDSCH EVM with the 3GPP EVM option enabled.

clc; close all;

projectRoot = fileparts(mfilename("fullpath"));
helpersDir = fullfile(projectRoot, "helpers");
resultsDir = fullfile(projectRoot, "rf_system_results");

addpath(helpersDir);
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

%% Load the RF system object and RF Blockset model dependencies
load(fullfile(helpersDir, "modelTX.mat"), "RF_TX", "Tstep", "fIF", "fRF");
load(fullfile(helpersDir, "WilkinsonSplitterData.mat"), "splitterCorporate");
load(fullfile(helpersDir, "DipoleArray_N4.mat"), "antennaArray", "rfAntenna");

fLO = fRF - fIF;
BW = 100e6;
referencePin = -20; % dBm

if evalin("base", "exist('budget','var') && isa(budget,'rfbudget')")
    Pin = evalin("base", "budget.AvailableInputPower");
else
    Pin = referencePin;
end

assignin("base", "RF_TX", RF_TX);
assignin("base", "Tstep", Tstep);
assignin("base", "fIF", fIF);
assignin("base", "fLO", fLO);
assignin("base", "fRF", fRF);
assignin("base", "BW", BW);
assignin("base", "Pin", Pin);
assignin("base", "splitterCorporate", splitterCorporate);
assignin("base", "antennaArray", antennaArray);
assignin("base", "rfAntenna", rfAntenna);

release(RF_TX);
reset(RF_TX);

%% Generate 5G NR reference waveform
rc = "NR-FR1-TM3.1";
bw = "100MHz";
scs = "30kHz";
dm = "FDD";
numSubframes = 1;

tmwavegen = hNRReferenceWaveformGenerator(rc, bw, scs, dm);
tmwavegen = makeConfigWritable(tmwavegen);
tmwavegen.Config.SampleRate = 1/Tstep;
tmwavegen.Config.NumSubframes = numSubframes;

[inWaveform, ~, ~] = generateWaveform(tmwavegen, ...
    tmwavegen.Config.NumSubframes);

%% Normalize the source waveform to 0 dBm before the model applies Pin
inPowerMeter = powermeter( ...
    "ReferenceLoad", 1, ...
    "Measurement", "All", ...
    "WindowLength", length(inWaveform));
[inputPowerBeforeScale, ~, ~] = inPowerMeter(inWaveform);
inWaveform = inWaveform .* 10^(-inputPowerBeforeScale(end)/20);
release(inPowerMeter);
[inputPower0dBm, ~, inputPAPR] = inPowerMeter(inWaveform);

%% Run the rfsystem workflow
fprintf("Running RF_TX rfsystem for %s, %s, %s, %s...\n", rc, bw, scs, dm);
outWaveform = RF_TX(inWaveform);

%% Power and PAPR measurements
release(inPowerMeter);
[outputPower, ~, outputPAPR] = inPowerMeter(outWaveform);

%% 3GPP EVM measurement
evmCfg = struct();
evmCfg.Evm3GPP = true;
evmCfg.TargetRNTIs = [];
evmCfg.PlotEVM = true;
evmCfg.DisplayEVM = false;
evmCfg.Label = tmwavegen.ConfiguredModel{1};
evmCfg.UseWholeGrid = true;
evmCfg.PdcchEnable = false;

[evmInfo, eqSym, refSym] = hNRDownlinkEVM( ...
    tmwavegen.Config, outWaveform, evmCfg);

pdschEVMRMS = evmInfo.PDSCH.OverallEVM.RMS * 100;
pdschEVMPeak = evmInfo.PDSCH.OverallEVM.Peak * 100;

%% Save a compact spectrum plot and workspace result
fig = figure("Name", "TM3.1 RF System Output");
nfft = 2^nextpow2(length(outWaveform));
sampleRate = 1/Tstep;
freqAxis = sampleRate*(-nfft/2:nfft/2-1).'/nfft;
outSpectrum = fftshift(fft(outWaveform, nfft));
plot(freqAxis/1e6, 20*log10(abs(outSpectrum)/max(abs(outSpectrum))));
grid on;
xlabel("Envelope frequency (MHz)");
ylabel("Normalized magnitude (dB)");
title("RF System Output Spectrum, NR-FR1-TM3.1");
xlim([-100 100]);
ylim([-100 5]);

plotFile = fullfile(resultsDir, "rf_system_tm31_output_spectrum.png");
exportgraphics(fig, plotFile, "Resolution", 150);

resultFile = fullfile(resultsDir, "rf_system_tm31_evm_results.mat");
save(resultFile, "Pin", "rc", "bw", "scs", "dm", "numSubframes", ...
    "sampleRate", "Tstep", "inputPower0dBm", "inputPAPR", ...
    "outputPower", "outputPAPR", "pdschEVMRMS", "pdschEVMPeak", ...
    "evmInfo", "eqSym", "refSym", "inWaveform", "outWaveform");

fprintf("RF system TM3.1 EVM testbench complete.\n");
fprintf("Model: %s (%s)\n", RF_TX.ModelName, RF_TX.Library);
fprintf("Pin from budget/testbench: %.2f dBm\n", Pin);
fprintf("Input waveform power before model gain: %.2f dBm\n", ...
    inputPower0dBm(end));
fprintf("Input PAPR: %.2f dB\n", inputPAPR(end));
fprintf("Measured output EIRP: %.2f dBm\n", outputPower(end));
fprintf("Output PAPR: %.2f dB\n", outputPAPR(end));
fprintf("3GPP PDSCH RMS EVM: %.3f %%\n", pdschEVMRMS);
fprintf("3GPP PDSCH Peak EVM: %.3f %%\n", pdschEVMPeak);
fprintf("Saved plot: %s\n", plotFile);
fprintf("Saved results: %s\n", resultFile);
