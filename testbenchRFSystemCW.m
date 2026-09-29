%% CW Testbench for RF_TX_Model rfsystem
% Drives the saved RF_TX rfsystem object with a 100 MHz complex CW envelope.
% The input drive Pin is taken from the current RF budget object when one
% exists in the base workspace; otherwise the reference budget value is used.

clear; clc; close all;

projectRoot = fileparts(mfilename("fullpath"));
helpersDir = fullfile(projectRoot, "helpers");
resultsDir = fullfile(projectRoot, "rf_system_results");

addpath(helpersDir);
addpath(projectRoot);
originalFolder = pwd;
folderCleanup = onCleanup(@() cd(originalFolder));
cd(helpersDir);
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

%% Load the RF system object and model dependencies
load(fullfile(helpersDir, "modelTX.mat"), "RF_TX", "Tstep", "fIF", "fRF");
load(fullfile(helpersDir, "WilkinsonSplitterData.mat"), "splitterCorporate");
load(fullfile(helpersDir, "DipoleArray_N4.mat"), "antennaArray", "rfAntenna");

fLO = fRF - fIF;
BW = 100e6;

assignin("base", "RF_TX", RF_TX);
assignin("base", "Tstep", Tstep);
assignin("base", "fIF", fIF);
assignin("base", "fLO", fLO);
assignin("base", "fRF", fRF);
assignin("base", "BW", BW);
assignin("base", "splitterCorporate", splitterCorporate);
assignin("base", "antennaArray", antennaArray);
assignin("base", "rfAntenna", rfAntenna);

release(RF_TX);
reset(RF_TX);

%% Test configuration
cwFrequency = 45e6;        % Hz, complex envelope tone frequency
simTime = 20e-6;           % seconds
referencePin = -20;        % dBm, reference budget input power

if evalin("base", "exist('budget','var') && isa(budget,'rfbudget')")
    Pin = evalin("base", "budget.AvailableInputPower");
else
    Pin = referencePin;
end
assignin("base", "Pin", Pin);

sampleRate = 1/Tstep;
nSamples = floor(simTime/Tstep);
t = (0:nSamples-1).' * Tstep;

%% Build a 0 dBm normalized CW envelope, then let RF_TX_Model apply Pin
inWaveform = exp(1j*2*pi*cwFrequency*t);

inPowerMeter = powermeter( ...
    "ReferenceLoad", 1, ...
    "Measurement", "Average power", ...
    "WindowLength", numel(inWaveform));
inputPowerBeforeScale = inPowerMeter(inWaveform);
inWaveform = inWaveform .* 10^(-inputPowerBeforeScale(end)/20);
release(inPowerMeter);
inputPower0dBm = inPowerMeter(inWaveform);

%% Run the rfsystem workflow: stream the waveform through RF_TX
outWaveform = RF_TX(inWaveform);

%% Measure output power after settling
settlingSamples = min(1024, floor(0.1*numel(outWaveform)));
measurementIndex = (settlingSamples + 1):numel(outWaveform);

outPowerMeter = powermeter( ...
    "ReferenceLoad", 1, ...
    "Measurement", "Average power", ...
    "WindowLength", numel(measurementIndex));
outputPower = outPowerMeter(outWaveform(measurementIndex));

measuredGain = outputPower(end) - Pin;

%% Save waveform and spectrum plots
fig = figure("Name", "RF System CW Testbench");
tiledlayout(fig, 2, 1);

nexttile;
plot(t(1:min(2000, end))*1e6, real(inWaveform(1:min(2000, end))));
hold on;
plot(t(1:min(2000, end))*1e6, real(outWaveform(1:min(2000, end))));
grid on;
xlabel("Time (us)");
ylabel("Real envelope");
title("100 MHz CW Envelope");
legend("Input", "Output", "Location", "best");

nexttile;
nfft = 2^nextpow2(numel(outWaveform));
freqAxis = sampleRate*(-nfft/2:nfft/2-1).'/nfft;
outSpectrum = fftshift(fft(outWaveform, nfft));
plot(freqAxis/1e6, 20*log10(abs(outSpectrum)/max(abs(outSpectrum))));
grid on;
xlabel("Envelope frequency (MHz)");
ylabel("Normalized magnitude (dB)");
title("Output Spectrum");
xlim(cwFrequency/1e6 + [-50 50]);
ylim([-100 5]);

plotFile = fullfile(resultsDir, "rf_system_cw_testbench.png");
exportgraphics(fig, plotFile, "Resolution", 150);

resultFile = fullfile(resultsDir, "rf_system_cw_testbench_results.mat");
save(resultFile, "Pin", "cwFrequency", "sampleRate", "Tstep", ...
    "simTime", "inputPower0dBm", "outputPower", "measuredGain", ...
    "inWaveform", "outWaveform");

fprintf("RF system CW testbench complete.\n");
fprintf("Model: %s (%s)\n", RF_TX.ModelName, RF_TX.Library);
fprintf("Input carrier: %.3f GHz, output carrier: %.3f GHz\n", ...
    fIF/1e9, fRF/1e9);
fprintf("CW envelope frequency: %.1f MHz\n", cwFrequency/1e6);
fprintf("Pin from budget/testbench: %.2f dBm\n", Pin);
fprintf("Normalized source power before model gain: %.2f dBm\n", ...
    inputPower0dBm(end));
fprintf("Measured output power: %.2f dBm\n", outputPower(end));
fprintf("Measured end-to-end gain: %.2f dB\n", measuredGain);
fprintf("Saved plot: %s\n", plotFile);
fprintf("Saved results: %s\n", resultFile);

open_system(RF_TX);
