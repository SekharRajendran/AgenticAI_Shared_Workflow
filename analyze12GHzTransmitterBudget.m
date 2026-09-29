%% Analyze a 12 GHz Transmitter RF Budget
% Builds a representative single-conversion transmitter using the measured
% driver and Wilkinson splitter data supplied with this project. The budget
% represents one RF path through the transmitter.

clear;
clc;
close all;

projectRoot = fileparts(mfilename("fullpath"));
helpersDir = fullfile(projectRoot, "helpers");
resultsDir = fullfile(projectRoot, "tx12GHz_budget_results");

if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

%% Operating point
fIF = 4e9;
fLO = 8e9;
fRF = fIF + fLO;
signalBandwidth = 100e6;
inputPower = -20; % dBm, average small-signal input power

%% Transmitter chain
% 4 GHz IF filter
ifFilter = rffilter( ...
    Name="IFfilter", ...
    FilterType="InverseChebyshev", ...
    ResponseType="Bandpass", ...
    FilterOrder=5, ...
    PassbandFrequency=fIF + [-signalBandwidth/2 signalBandwidth/2], ...
    PassbandAttenuation=3);

% Measured driver-amplifier S-parameters and noise figure
driver = amplifier( ...
    Name="DriverAmp", ...
    Model="sparam", ...
    FileName=fullfile(helpersDir, "CMD240withNF.s2p"), ...
    OIP3=28, ...
    OP1dB=19, ...
    OPsat=22);

% 4-to-12 GHz upconverter
upconverter = modulator( ...
    Name="Upconverter", ...
    LO=fLO, ...
    ConverterType="Up", ...
    Gain=6, ...
    NF=3, ...
    OIP3=32);

% One output path through the measured corporate splitter
splitterData = load( ...
    fullfile(helpersDir, "WilkinsonSplitterData.mat"), ...
    "splitterSparam");
splitter = nport(splitterData.splitterSparam, "WilkinsonSplitter");
splitter.Input = 1;
splitter.Output = 2;
splitter.Termination = 50;

% Final power amplifier
pa = amplifier( ...
    Name="PowerAmp", ...
    Model="poly", ...
    Gain=25, ...
    NF=6, ...
    OIP3=45, ...
    OP1dB=33, ...
    OPsat=37.5);

% Reference dipole at the transmitter output
antennaElement = design(dipole, fRF);
antennaSParameters = sparameters(antennaElement, fRF);
antennaGain = pattern(antennaElement, fRF, 0, 0);
txAntenna = rfantenna( ...
    Name="DipoleAntenna", ...
    Type="Transmitter", ...
    Gain=antennaGain, ...
    Z=s2z(antennaSParameters.Parameters));

elements = [ifFilter driver upconverter splitter pa txAntenna];
budget = rfbudget( ...
    Elements=elements, ...
    InputFrequency=fIF, ...
    AvailableInputPower=inputPower, ...
    SignalBandwidth=signalBandwidth);

%% Stage contributions
stageNames = [ ...
    "IF filter"
    "Driver amplifier"
    "Upconverter"
    "Wilkinson splitter"
    "Power amplifier"
    "Dipole antenna"];

cumulativeGain = budget.TransducerGain(:);
stageGain = [cumulativeGain(1); diff(cumulativeGain)];

% Friis excess-noise terms, all referred to the chain input:
% Ftotal - 1 = sum((Fi - 1)/Gpreceding).
cumulativeNoiseFactor = 10.^(budget.NF(:)/10);
noiseContribution = [ ...
    cumulativeNoiseFactor(1) - 1
    diff(cumulativeNoiseFactor)];
noiseContribution(abs(noiseContribution) < 1e-12) = 0;
noiseContribution = max(noiseContribution, 0);
noiseContributionPct = 100 * noiseContribution / ...
    (cumulativeNoiseFactor(end) - 1);

precedingGainLinear = [1; 10.^(cumulativeGain(1:end-1)/10)];
stageNoiseFactor = 1 + noiseContribution .* precedingGainLinear;
stageNoiseFigure = 10*log10(stageNoiseFactor);

% Cascaded third-order distortion adds as reciprocal input IP3:
% 1/IIP3total = sum(Gpreceding/IIP3i).
cumulativeIIP3 = budget.IIP3(:);
inverseIIP3 = 10.^(-cumulativeIIP3/10);
im3Contribution = [inverseIIP3(1); diff(inverseIIP3)];
im3Contribution(abs(im3Contribution) < 1e-12) = 0;
im3Contribution = max(im3Contribution, 0);
im3ContributionPct = 100 * im3Contribution / inverseIIP3(end);

% Compression headroom is reported where component P1dB data is available.
p1dBMargin = nan(size(stageNames));
p1dBMargin(2) = driver.OP1dB - budget.OutputPower(2);
p1dBMargin(5) = pa.OP1dB - budget.OutputPower(5);

stageTable = table( ...
    stageNames, ...
    budget.OutputFrequency(:)/1e9, ...
    stageGain, ...
    cumulativeGain, ...
    stageNoiseFigure, ...
    budget.NF(:), ...
    budget.IIP3(:), ...
    budget.OIP3(:), ...
    budget.OutputPower(:), ...
    noiseContributionPct, ...
    im3ContributionPct, ...
    p1dBMargin, ...
    VariableNames=[ ...
        "Stage"
        "OutputFrequency_GHz"
        "StageGain_dB"
        "CumulativeGain_dB"
        "StageNF_dB"
        "CumulativeNF_dB"
        "CumulativeIIP3_dBm"
        "CumulativeOIP3_dBm"
        "OutputPower_dBm"
        "NoiseContribution_pct"
        "IM3Contribution_pct"
        "P1dBMargin_dB"]);

%% Identify limiting stages
[largestLoss, gainLimiterIndex] = min(stageGain);
[~, noiseLimiterIndex] = max(noiseContributionPct);
[~, linearityLimiterIndex] = max(im3ContributionPct);
[largestGain, gainProviderIndex] = max(stageGain);

paStage = 5;
systemGainToPA = budget.TransducerGain(paStage);
systemNF = budget.NF(paStage);
systemIIP3 = budget.IIP3(paStage);
systemOIP3 = budget.OIP3(paStage);
paOutputPower = budget.OutputPower(paStage);

fprintf("12 GHz transmitter chain (one RF path)\n");
fprintf("IF + LO -> RF: %.1f + %.1f -> %.1f GHz\n", ...
    fIF/1e9, fLO/1e9, fRF/1e9);
fprintf("Bandwidth: %.0f MHz; input power: %.1f dBm\n\n", ...
    signalBandwidth/1e6, inputPower);
disp(stageTable);

fprintf("\nBudget through the PA output\n");
fprintf("Gain: %.2f dB\n", systemGainToPA);
fprintf("Noise figure: %.2f dB\n", systemNF);
fprintf("IIP3 / OIP3: %.2f / %.2f dBm\n", systemIIP3, systemOIP3);
fprintf("Output power: %.2f dBm\n", paOutputPower);
fprintf("PA P1dB headroom: %.2f dB\n", p1dBMargin(paStage));

fprintf("\nLimiting stages\n");
fprintf("Gain loss: %s (%.2f dB stage gain)\n", ...
    stageNames(gainLimiterIndex), largestLoss);
fprintf("Largest gain provider: %s (+%.2f dB)\n", ...
    stageNames(gainProviderIndex), largestGain);
fprintf("Noise figure: %s (%.1f%% of excess-noise factor)\n", ...
    stageNames(noiseLimiterIndex), noiseContributionPct(noiseLimiterIndex));
fprintf("Linearity: %s (%.1f%% of reciprocal-IIP3 degradation)\n", ...
    stageNames(linearityLimiterIndex), im3ContributionPct(linearityLimiterIndex));

%% Save tabular and visual results
writetable(stageTable, fullfile(resultsDir, "tx12GHz_stage_budget.csv"));

fig = figure(Name="12 GHz Transmitter Budget", Color="w");
tiledlayout(fig, 2, 2, TileSpacing="compact");
stageIndex = 1:numel(stageNames);

nexttile;
bar(stageIndex, stageGain);
yline(0, "k-");
title("Incremental Stage Gain");
ylabel("Gain (dB)");
grid on;

nexttile;
bar(stageIndex, budget.OutputPower(:));
title("Cumulative Output Power");
ylabel("Power (dBm)");
grid on;

nexttile;
bar(stageIndex, noiseContributionPct);
title("Excess-Noise Contribution");
ylabel("Contribution (%)");
grid on;

nexttile;
bar(stageIndex, im3ContributionPct);
title("Reciprocal-IIP3 Contribution");
ylabel("Contribution (%)");
grid on;

for tileIndex = 1:4
    ax = nexttile(tileIndex);
    ax.XTick = stageIndex;
    ax.XTickLabel = stageNames;
    ax.XTickLabelRotation = 35;
end

exportgraphics( ...
    fig, ...
    fullfile(resultsDir, "tx12GHz_budget_and_limiters.png"), ...
    Resolution=180);

fprintf("\nSaved results to:\n%s\n", resultsDir);

% Uncomment to inspect or modify the chain interactively.
% rfBudgetAnalyzer(budget);
