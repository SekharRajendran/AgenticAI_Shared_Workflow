%% Analyze Reference RF Budget Chain
% RF budget analysis for the reference chain described in
% "Agentic AI Antenna-to-bits Reference Chain.docx".

clear; clc; close all;

projectRoot = fileparts(mfilename("fullpath"));
helpersDir = fullfile(projectRoot, "helpers");
resultsDir = fullfile(projectRoot, "rf_budget_results");

addpath(helpersDir);
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

%% Global parameters
fIF = 4e9;
fLO = 8e9;
fRF = fIF + fLO;
BW = 100e6;
PinLinear = -20;       % dBm
N = 4;                 % baseline dipole array size
paprEstimate = 10;     % dB, representative 5G NR PAPR
compressionMargin = 3; % dB, peak drive beyond PA P1dB estimate

%% Stage 1 - IF filter, BFIC #1
ifFilter = rffilter( ...
    "Name", "IFfilter", ...
    "FilterType", "InverseChebyshev", ...
    "ResponseType", "Bandpass", ...
    "FilterOrder", 5, ...
    "PassbandFrequency", fIF + [-BW/2 BW/2], ...
    "PassbandAttenuation", 3);

%% Stage 2 - Driver amplifier, BFIC #2
driverAmp = amplifier( ...
    "Name", "DriverAmp", ...
    "Model", "sparam", ...
    "FileName", fullfile(helpersDir, "CMD240withNF.s2p"), ...
    "OIP3", 28, ...
    "OP1dB", 19, ...
    "OPsat", 22);

%% Stage 3 - RF tuner / upconverter, BFIC #3
rfTuner = modulator( ...
    "Name", "RFtuner", ...
    "Model", "mod", ...
    "LO", fLO, ...
    "ConverterType", "Up", ...
    "Gain", 6, ...
    "NF", 3, ...
    "OIP3", 32);

%% Stage 4 - Wilkinson corporate splitter, BFIC #4
splitterData = load(fullfile(helpersDir, "WilkinsonSplitterData.mat"), ...
    "splitterSparam");
splitter = nport(splitterData.splitterSparam, "WilkinsonSplitter");
splitter.Input = 1;
splitter.Output = 2;
splitter.Termination = 50;

%% Stage 5 - Power amplifier
pa = amplifier( ...
    "Name", "PA", ...
    "Model", "poly", ...
    "Gain", 25, ...
    "NF", 6, ...
    "OIP3", 45, ...
    "OP1dB", 33, ...
    "OPsat", 37.5);

%% Stage 6 - Baseline antenna element
rfAntenna = design(dipole, fRF);
antennaSparam = sparameters(rfAntenna, fRF);
antennaGain = pattern(rfAntenna, fRF, 0, 0);
budgetAntenna = rfantenna( ...
    "Name", "DipoleAnt", ...
    "Type", "Transmitter", ...
    "Gain", antennaGain, ...
    "Z", s2z(antennaSparam.Parameters));

%% Build RF budget
elements = [ifFilter driverAmp rfTuner splitter pa budgetAntenna];
budget = rfbudget( ...
    "Elements", elements, ...
    "InputFrequency", fIF, ...
    "AvailableInputPower", PinLinear, ...
    "SignalBandwidth", BW);

stageNames = ["IF filter"; "Driver amp"; "RF tuner"; ...
    "Wilkinson splitter"; "Power amp"; "Dipole antenna"];
stageTable = table( ...
    stageNames, ...
    budget.OutputFrequency(:)/1e9, ...
    budget.TransducerGain(:), ...
    budget.NF(:), ...
    budget.OIP3(:), ...
    budget.OutputPower(:), ...
    'VariableNames', ["Stage", "OutputFreq_GHz", "GainT_dB", ...
    "NF_dB", "OIP3_dBm", "Pout_dBm"]);

disp("Reference RF budget, representative path");
disp(stageTable);

%% Estimate baseline array EIRP
paStage = 5;
paOutputLinear = budget.OutputPower(paStage);

antennaArray = design(linearArray("Element", rfAntenna), fRF, rfAntenna);
antennaArray.NumElements = N;
arrayDirectivity = peakRadiation(antennaArray, fRF);
eirpLinear = paOutputLinear + arrayDirectivity + 10*log10(N);

fprintf("\nLinear baseline\n");
fprintf("Input power: %.1f dBm\n", PinLinear);
fprintf("PA output per path: %.2f dBm\n", paOutputLinear);
fprintf("%d-dipole array directivity: %.2f dBi\n", N, arrayDirectivity);
fprintf("Estimated array EIRP: %.2f dBm\n", eirpLinear);

%% Compare Friis and Harmonic Balance near PA compression
gainToPAOutput = budget.TransducerGain(paStage);
pinAtP1dB = pa.OP1dB - gainToPAOutput;

budget.AvailableInputPower = pinAtP1dB;
budget.Solver = "Friis";
paOutputP1dBFriis = budget.OutputPower(paStage);

budget.Solver = "HarmonicBalance";
paOutputP1dBHB = budget.OutputPower(paStage);

pinDriven = pinAtP1dB - paprEstimate + compressionMargin;
budget.AvailableInputPower = pinDriven;
paOutputDriven = budget.OutputPower(paStage);
eirpDriven = paOutputDriven + arrayDirectivity + 10*log10(N);

fprintf("\nPA drive comparison\n");
fprintf("Estimated CW input at PA P1dB: %.2f dBm\n", pinAtP1dB);
fprintf("PA output at P1dB input, Friis: %.2f dBm\n", paOutputP1dBFriis);
fprintf("PA output at P1dB input, HarmonicBalance: %.2f dBm\n", paOutputP1dBHB);
fprintf("Selected modulated drive: %.2f dBm\n", pinDriven);
fprintf("Driven PA output per path, HarmonicBalance: %.2f dBm\n", paOutputDriven);
fprintf("Driven estimated array EIRP: %.2f dBm\n", eirpDriven);

%% Save budget plots
budget.AvailableInputPower = PinLinear;
budget.Solver = "Friis";

fig = figure("Name", "RF Budget Metrics");
tiledlayout(fig, 2, 2);
stageIndex = 1:numel(stageNames);
stageLabels = cellstr(stageNames);
plotOIP3 = budget.OIP3(:);
plotOIP3(isinf(plotOIP3)) = NaN;

nexttile;
bar(stageIndex, budget.OutputPower(:));
title("Output Power");
ylabel("dBm");
grid on;
set(gca, "XTick", stageIndex, "XTickLabel", stageLabels);
xtickangle(35);

nexttile;
bar(stageIndex, budget.TransducerGain(:));
title("Transducer Gain");
ylabel("dB");
grid on;
set(gca, "XTick", stageIndex, "XTickLabel", stageLabels);
xtickangle(35);

nexttile;
bar(stageIndex, budget.NF(:));
title("Noise Figure");
ylabel("dB");
grid on;
set(gca, "XTick", stageIndex, "XTickLabel", stageLabels);
xtickangle(35);

nexttile;
bar(stageIndex, plotOIP3);
title("OIP3");
ylabel("dBm");
grid on;
set(gca, "XTick", stageIndex, "XTickLabel", stageLabels);
xtickangle(35);

exportgraphics(fig, fullfile(resultsDir, "reference_rf_budget_metrics.png"), ...
    "Resolution", 150);

fig = figure("Name", "4-Dipole Array Pattern");
pattern(antennaArray, fRF);
title("4-Dipole Array Pattern at 12 GHz");
exportgraphics(fig, fullfile(resultsDir, "dipole_array_pattern.png"), ...
    "Resolution", 150);

fprintf("\nSaved plots to:\n%s\n", resultsDir);

% Uncomment to inspect the chain interactively.
% rfBudgetAnalyzer(budget);
