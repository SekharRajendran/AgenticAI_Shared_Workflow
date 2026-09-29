# Agentic AI Antenna-to-bits

## Trigger

Use this demo when the user asks for the Antenna-to-bits demo, RF/AMS agentic demo, antenna-to-bits optimization, 5G transmitter optimization, or a generic Agentic AI demo around RF system design.

## Demo Purpose

Show how an AI agent can help design, analyze, and optimize a 12 GHz 5G NR transmitter from signal generation through RF chain, PA nonlinearity, antenna array, and measured waveform quality.

The demo is generic. It is not tied to IMS booth wording or event-specific framing.

## Agent Role

Act as a concise RF systems engineer. Guide the user through the trade space, run MATLAB through the MATLAB Agentic Toolkit MCP server, and use the RF and AMS MATLAB Agentic Toolbox skills as the organizing workflow.

Keep the interaction technical and visual:

- Prefer MATLAB apps, plots, tables, and Simulink model windows over long code listings.
- Narrate one short sentence before running code.
- Print compact result lines only.
- Use precomputed waveforms by default; full RF/Simulink runs are optional and can take 30 to 60 seconds.

## Required Skill Routing

Use these MATLAB Agentic Toolbox skills during the demo:

| Demo activity | Skill |
|---|---|
| Cascaded gain, output power, noise, and nonlinear budget | `matlab-agentic-toolkit:matlab-analyze-rf-budget` |
| LNA Touchstone file, splitter EM data, antenna/array S-parameters | `matlab-agentic-toolkit:matlab-manage-sparameters` |
| Dipole and circular patch element/array pattern work | `matlab-agentic-toolkit:matlab-design-antenna` |
| Circuit-envelope/rfsystem waveform simulation and model inspection | `matlab-agentic-toolkit:matlab-simulate-rf-system` |
| Optional AMS timing, jitter, phase-noise, or mixed-signal waveform extensions | `matlab-agentic-toolkit:matlab-analyze-ams-waveform` |

Do not bypass the MCP server. All MATLAB code execution goes through the MATLAB Agentic Toolkit tools such as `mcp__matlab__evaluate_matlab_code` and `mcp__matlab__run_matlab_file`.

## Local Setup

Run at the start of a session:

```matlab
cd('C:\Demos\Events\2026\AgenticAI');
addpath('helpers');
loadOutWaveforms = 1;
```

Key files:

| File | Purpose |
|---|---|
| `Antenna2BitsDemoLive.pdf` | Source presentation/live-script export for the baseline flow |
| `Antenna2BitsDemoLive.mlx` | Live script that generated the PDF |
| `runAntenna2Bits.m` | Linear script covering the full design flow |
| `RF_TX_Model.slx` | 4-element RF transmitter model |
| `RF_TX_Model8.slx` | 8-element RF transmitter model |
| `MatchingNetworkDesign.m` | Matching-network exploration for patch array elements |
| `helpers/` | S-parameters, precomputed arrays, precomputed waveforms, EVM helpers |

Precomputed waveform naming is handled by `helpers/wvFileName.m`:

```text
PinLow_Dipole_N4_TXoutWaveform.mat
PinHigh_Dipole_N4_TXoutWaveform.mat
PinLow_Patch_N4_TXoutWaveform.mat
PinHigh_Patch_N4_TXoutWaveform.mat
PinLow_Dipole_N8_TXoutWaveform.mat
PinHigh_Dipole_N8_TXoutWaveform.mat
PinLow_Patch_N8_TXoutWaveform.mat
PinHigh_Patch_N8_TXoutWaveform.mat
```

Where `PinLow = -20 dBm` and `PinHigh = -13 dBm`.

## System Story

The transmitter is a 12 GHz 5G NR antenna-to-bits chain:

```text
5G NR waveform
  -> BFIC representative path: IF filter + LNA + RF upconverter + Wilkinson splitter
  -> N power amplifiers
  -> N-element antenna array
  -> EIRP, EVM, ACLR, PAPR measurements
```

Global parameters:

| Quantity | Value |
|---|---:|
| IF | 4 GHz |
| LO | 8 GHz |
| RF | 12 GHz |
| Bandwidth | 100 MHz |
| 5G waveform | NR-FR1-TM3.1, 100 MHz, 30 kHz SCS, FDD |
| Baseline array | 4 dipoles |
| Baseline input power | -20 dBm |
| Target | EIRP above 42 dBm with EVM below about 3% |

Important explanation:

The RF Budget represents one RF path through the BFIC, one PA, and one antenna reference. The full transmitter result is rolled up using array directivity and coherent combining across `N` elements.

## Intro Flow

Use this order for the live walkthrough:

1. State the objective: increase EIRP from about 33 dBm to above 42 dBm while controlling EVM and ACLR.
2. Build and show the RF budget for one representative path.
3. Roll the single-path PA output into a 4-element array EIRP estimate.
4. Generate and inspect the 5G NR waveform.
5. Open the 4-element RF system model as the visual circuit-level representation.
6. Load the precomputed baseline waveform and measure EIRP, PAPR, EVM, and ACLR.
7. Offer the three optimization levers: PA drive, antenna directivity, and array size.

## Baseline Build

Run through the six stages from the PDF/live script:

| Stage | MATLAB object or data | Skill |
|---|---|---|
| IF filter | `rffilter`, inverse Chebyshev bandpass around 4 GHz | RF budget |
| LNA | `amplifier`, model from `CMD240withNF.s2p` | S-parameters, RF budget |
| RF tuner | `modulator`, LO = 8 GHz, gain = 6 dB | RF budget |
| Wilkinson splitter | `nport` from `WilkinsonSplitterData.mat` | S-parameters |
| PA | `amplifier`, polynomial model, gain = 25 dB, OP1dB = 33 dBm, OPsat = 37.5 dBm | RF budget |
| Antenna | `dipole`, converted to `rfantenna` budget element | Antenna design, RF budget |

Representative code:

```matlab
fIF = 4e9;
fLO = 8e9;
fRF = fIF + fLO;
lambda = physconst("LightSpeed")/fRF;
BW = 100e6;
N = 4;

ifFilter = rffilter("Name","IFfilter", FilterType="InverseChebyshev", ...
    ResponseType="Bandpass", FilterOrder=5, ...
    PassbandFrequency=[-BW/2 BW/2]+fIF, PassbandAttenuation=3);

lna = amplifier("Name","LNA", Model="sparam", FileName="CMD240withNF.s2p", ...
    OIP3=28, OP1dB=19, OPsat=22);

rfTuner = modulator("Name","RFtuner", Model="mod", LO=fLO, ...
    Gain=6, NF=3, OIP3=32);

load WilkinsonSplitterData.mat;
splitter = nport("Name","WilkinsonSplitter", ...
    NetworkData=sparameters(splitterSparam));

pa = amplifier("Name","PA", Model="poly", ...
    Gain=25, NF=6, OIP3=45, OP1dB=33, OPsat=37.5);

rfAntenna = design(dipole, fRF);
S = sparameters(rfAntenna, fRF);
budgetAntenna = rfantenna("Gain", pattern(rfAntenna, fRF, 0, 0), ...
    "Z", s2z(S.Parameters));

elements = [ifFilter lna rfTuner splitter pa budgetAntenna];
Pin = -20;
b = rfbudget(Elements=elements, InputFrequency=fIF, ...
    AvailableInputPower=Pin, SignalBandwidth=BW);
show(b);
```

Baseline roll-up:

```matlab
PA_idx = 5;
PAout = b.OutputPower(PA_idx);

antennaArray = design(linearArray(Element=rfAntenna), fRF, rfAntenna);
antennaArray.NumElements = N;
figure; pattern(antennaArray, fRF);

arrayDirectivity = peakRadiation(antennaArray, fRF);
maxEIRP = PAout + arrayDirectivity + 10*log10(N);

fprintf("Input power = %.1f dBm\n", Pin);
fprintf("PA output per path = %.1f dBm\n", PAout);
fprintf("Array directivity = %.1f dBi\n", arrayDirectivity);
fprintf("Estimated EIRP = %.1f dBm\n", maxEIRP);
```

Expected baseline:

| Baseline quantity | Value | Meaning |
|---|---:|---|
| RF path shown in budget | 1 chain | Representative BFIC/PA/antenna path |
| Input power | -20 dBm | Linear operating point |
| PA output per path | about 19 dBm | Single-chain PA output from RF budget |
| Array size | 4 dipoles | Four transmit elements |
| Array directivity | about 9 dBi | Broadside 4-dipole directivity |
| Coherent combining | +6 dB | `10*log10(4)` |
| Estimated EIRP | about 33 dBm | Baseline array result |

## Waveform and RF System Measurement

Use the 5G NR waveform from the PDF/live script:

```matlab
rc = "NR-FR1-TM3.1";
bw = "100MHz";
scs = "30kHz";
dm = "FDD";

Tstep = 1/491.52e6;
Tstop = 0.51e-3;

tmwavegen = hNRReferenceWaveformGenerator(rc,bw,scs,dm);
tmwavegen = makeConfigWritable(tmwavegen);
tmwavegen.Config.SampleRate = 1/Tstep;
tmwavegen.Config.NumSubframes = 1;
[inWaveform,~,~] = generateWaveform(tmwavegen, tmwavegen.Config.NumSubframes);
inWaveform = inWaveform(1:round(Tstop/Tstep));

PowMet = powermeter("ReferenceLoad",1,"Measurement","All", ...
    "WindowLength",length(inWaveform));
[AvgPow,~,~] = PowMet(inWaveform);
inWaveform = inWaveform .* 10^(-AvgPow(end)/20);
release(PowMet);
[~,~,PAPRIn] = PowMet(inWaveform);
fprintf("Input signal PAPR = %.1f dB\n", PAPRIn(end));
```

Open the model and load the precomputed baseline:

```matlab
load("modelTX.mat");
load DipoleArray_N4.mat;
open_system(RF_TX);

Pin = -20;
rfAntenna = dipole;
N = 4;
load(wvFileName(Pin, rfAntenna, N));
```

Measure:

```matlab
SpectAnalyzer = spectrumAnalyzer;
SpectAnalyzer.SampleRate = 1/Tstep;
SpectAnalyzer.ReferenceLoad = 1;
SpectAnalyzer.RBWSource = "Property";
SpectAnalyzer.RBW = 1e6;

release(SpectAnalyzer);
SpectAnalyzer(outWaveform);
SpectAnalyzer.ChannelMeasurements.Type = "acpr";
SpectAnalyzer.ChannelMeasurements.Span = BW;
SpectAnalyzer.ChannelMeasurements.AdjacentBW = BW;
SpectAnalyzer.ChannelMeasurements.NumOffsets = 1;
SpectAnalyzer.ChannelMeasurements.ACPROffsets = BW*1.05;
SpectAnalyzer.ChannelMeasurements.Enabled = true;
tmp = getMeasurementsData(SpectAnalyzer);
ACLR = max(tmp.ChannelMeasurements.ACPRLower, tmp.ChannelMeasurements.ACPRUpper);

release(PowMet);
[AvgPowOut,~,PAPROut] = PowMet(outWaveform);

cfg = struct();
cfg.Evm3GPP = false;
cfg.TargetRNTIs = [];
cfg.PlotEVM = true;
cfg.DisplayEVM = false;
cfg.Label = tmwavegen.ConfiguredModel{1};
cfg.UseWholeGrid = true;
cfg.PdcchEnable = false;
[evmInfo,~,~] = hNRDownlinkEVM(tmwavegen.Config, outWaveform, cfg);

fprintf("Measured EIRP = %.1f dBm\n", AvgPowOut(end));
fprintf("EVM RMS = %.2f%%\n", evmInfo.PDSCH.OverallEVM.RMS*100);
fprintf("ACLR = %.1f dBc\n", ACLR);
fprintf("Output PAPR = %.1f dB\n", PAPROut(end));
```

Baseline result:

| Metric | Baseline |
|---|---:|
| EIRP | about 33.0 dBm |
| EVM RMS | about 0.54% |
| ACLR | about -51 dBc |
| Output PAPR | about 10 dB |

## Optimization Lever 1: Increase PA Drive

Use `matlab-agentic-toolkit:matlab-analyze-rf-budget` to compare Friis and HarmonicBalance around compression.

Core explanation:

The PA has OP1dB = 33 dBm. The cumulative gain from system input to PA output is about 39 dB, so a CW input around `33 - 39 = -6 dBm` reaches P1dB. A 5G NR waveform has about 10 dB PAPR, so an average input near `-16 dBm` puts peaks near P1dB. The demo uses `-13 dBm` to push peaks about 3 dB into compression while keeping EVM acceptable.

```matlab
PA_idx = 5;
G2PAout = b.TransducerGain(PA_idx);

Pin_at_P1dB = elements(PA_idx).OP1dB - G2PAout;
b.AvailableInputPower = Pin_at_P1dB;
b.Solver = "Friis";
PAoutFriis = b.OutputPower(PA_idx);

b.Solver = "HarmonicBalance";
PAoutHB = b.OutputPower(PA_idx);

PinSat = Pin_at_P1dB - 10 + 3;
fprintf("Pin at PA P1dB for CW = %.1f dBm\n", Pin_at_P1dB);
fprintf("Friis PA output = %.1f dBm\n", PAoutFriis);
fprintf("HB PA output = %.1f dBm\n", PAoutHB);
fprintf("Selected modulated drive = %.1f dBm\n", PinSat);
```

Expected result:

| Metric | 4 dipoles, -20 dBm | 4 dipoles, -13 dBm |
|---|---:|---:|
| EIRP | 33.0 dBm | 39.5 dBm |
| EVM RMS | 0.54% | 2.55% |
| ACLR | -51 dBc | -40 dBc |
| Output PAPR | 10.0 dB | 8.9 dB |

Tradeoff:

Higher drive is the cheapest EIRP gain because it uses the same hardware. It costs linearity, visible as higher EVM, worse ACLR, and lower output PAPR from peak compression.

## Optimization Lever 2: Increase Antenna Directivity

Use `matlab-agentic-toolkit:matlab-design-antenna` and `matlab-agentic-toolkit:matlab-manage-sparameters`.

Switch from dipoles to circular patches:

```matlab
rfAntenna = design(patchMicrostripCircular, fRF);
rfAntenna.Radius = 7e-3;
figure; pattern(rfAntenna, fRF);

antennaArray = linearArray(Element=rfAntenna, ...
    ElementSpacing=max(rfAntenna.Radius*2.1, lambda/2), ...
    NumElements=4, Tilt=-90);
figure; pattern(antennaArray, fRF);

arrayDirectivity = peakRadiation(antennaArray, fRF);
arraySparam = sparameters(antennaArray, fRF);
fprintf("Patch array directivity = %.1f dBi\n", arrayDirectivity);
fprintf("S11 = %.1f dB\n", 20*log10(abs(arraySparam.Parameters(1,1))));
fprintf("S12 = %.1f dB\n", 20*log10(abs(arraySparam.Parameters(1,2))));
```

Key talking points:

- Dipole element gain is about 2 dBi; the 4-dipole array directivity is about 9 dBi.
- Circular patch element gain is about 6 to 7 dBi; the 4-patch array directivity is about 13 to 14 dBi.
- At 12 GHz, the patch is physically close to a half-wavelength radiator, so compact spacing produces mutual coupling.
- Matching can improve S11 but does not remove S12. Coupled power entering neighbor ports is not recovered as broadside EIRP.
- Increasing spacing reduces coupling but eventually creates grating lobes.

Expected result:

| Metric | 4 dipoles, -13 dBm | 4 circular patches, -13 dBm |
|---|---:|---:|
| EIRP | 39.5 dBm | 42.2 dBm |
| EVM RMS | 2.55% | 2.55% |
| ACLR | -40 dBc | -39 dBc |

Tradeoff:

Patch antennas can meet the 42 dBm target with the same number of RF chains, but the realized gain is limited by coupling and array layout constraints.

## Optimization Lever 3: Double the Array

Use antenna and RF system skills together. Move from 4 to 8 elements:

```matlab
N = 8;
rfAntenna = patchMicrostripCircular;
load("modelTX8.mat");
load PatchArray_N8.mat;
open_system(RF_TX);

Pin = -13;
load(wvFileName(Pin, rfAntenna, N));
```

Expected result:

| Metric | 4 circular patches, -13 dBm | 8 circular patches, -13 dBm |
|---|---:|---:|
| EIRP | 42.2 dBm | 48.7 dBm |
| EVM RMS | 2.55% | 2.88% |
| ACLR | -39 dBc | -38 dBc |
| Output PAPR | 8.9 dB | 8.9 dB |

Tradeoff:

Doubling the array is predictable, but it doubles the RF paths, PAs, antennas, board area, power consumption, and calibration burden.

## Summary Table

Use this table at the end:

| Configuration | EIRP | EVM RMS | ACLR | Takeaway |
|---|---:|---:|---:|---|
| 4 dipoles, linear drive | 33.0 dBm | 0.54% | -51.2 dBc | Clean baseline, below target |
| 4 dipoles, higher drive | 39.5 dBm | 2.55% | -39.5 dBc | Same hardware, linearity cost |
| 4 circular patches, higher drive | 42.2 dBm | 2.55% | -39.0 dBc | Meets target with same RF-chain count |
| 8 dipoles, linear drive | 39.0 dBm | 0.53% | -52.3 dBc | Clean, still below target |
| 8 circular patches, linear drive | 41.8 dBm | 0.53% | -52.0 dBc | Very close, excellent quality |
| 8 dipoles, higher drive | 46.0 dBm | 2.88% | -38.4 dBc | Meets target with simpler antennas |
| 8 circular patches, higher drive | 48.7 dBm | 2.88% | -37.9 dBc | Highest EIRP, highest hardware/antenna complexity |

Recommended framing:

- Minimum hardware to meet target: 4 circular patches with higher drive.
- Best signal quality near target: 8 circular patches with linear drive.
- Highest margin: 8 circular patches with higher drive.
- Simpler antennas with margin: 8 dipoles with higher drive.

Core takeaway:

Every dB has a cost: PA linearity, antenna coupling, or hardware scale. The agent helps quantify those tradeoffs with RF budget analysis, measured/EM S-parameters, antenna patterns, and waveform-quality metrics.

## Optional Branches

### Matching Networks

Use `MatchingNetworkDesign.m` if the user asks whether S11 can be fixed. Explain that matching can improve return loss but cannot eliminate mutual coupling (`S12`).

### DPD

Digital predistortion can recover linearity while driving the PA harder, but it requires an observation path, wideband ADC, model adaptation, and per-element or compromise DPD for arrays. Treat it as a separate design problem.

### CFR

Crest factor reduction lowers PAPR before the PA. It can reduce PA spectral regrowth but introduces in-band distortion, so EVM becomes the limiting metric.

### AMS Extension

If the user pivots to PLL, LO, clock, ADC, DAC, jitter, phase noise, or mixed-signal waveform quality, switch to `matlab-agentic-toolkit:matlab-analyze-ams-waveform`. Ask for phase-noise offset points before measuring phase noise, and report integrated RMS jitter after phase-noise analysis.

## Guardrails

- Use the MATLAB MCP server only. Do not launch MATLAB externally.
- Do not run full Simulink/rfsystem simulations by default. Load precomputed waveforms unless the user explicitly asks for a live run.
- Do not run heavy full-wave array EM solves during the demo. Use precomputed array data or lightweight pattern analysis.
- Never use `sim()` for this flow. The RF system object is invoked as `outWaveform = RF_TX(inWaveform)` only when a live run is explicitly requested.
- Keep code output short and user-facing.
- Ground numeric claims in `Antenna2BitsDemoLive.pdf`, `Antenna2BitsDemoLive.mlx`, `runAntenna2Bits.m`, and the helper data in this folder.
