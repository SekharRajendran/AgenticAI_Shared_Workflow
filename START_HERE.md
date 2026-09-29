# Start here

This folder is a guided engineering workflow, not a set of unrelated examples.

## 1. Read the objective

Open `Agentic AI Antenna-to-bits Reference Chain.docx`.

- Baseline: four dipoles, -20 dBm input, about 33 dBm EIRP.
- Target: more than 42 dBm EIRP with RMS EVM below about 3%.
- Fixed chain: 4 GHz IF filter, LNA, 8 GHz-LO upconverter, corporate Wilkinson splitter, PA, and antenna array.

## 2. Create the RF budget from the specification

Open and review `build12GHzTransmitterRFBudget.m`, then run it:

```matlab
run("build12GHzTransmitterRFBudget.m")
```

The script uses:

- `helpers/CMD240withNF.s2p` for the LNA/driver.
- `helpers/WilkinsonSplitterData.mat` for the EM-derived corporate splitter.

At -20 dBm input, expect roughly 18.9 dBm PA output and 20.8 dBm per-path EIRP.

## 3. Inspect the RF Toolbox object

Run:

```matlab
run("buildReferenceRFBudgetAnalyzer.m")
```

This builds the same representative path and opens RF Budget Analyzer.

## 4. Inspect the EM and RF system models

Use `Antenna2BitsDemoLive.pdf` for the splitter and dipole construction sequence, then open:

```matlab
run("openBaselineModel.m")
```

The baseline result is about 33 dBm EIRP with low EVM, so it does not meet the EIRP objective.

## 5. Evaluate the resolution model

Open:

```matlab
run("openResolutionModel.m")
```

Compare the higher-element-count model against the baseline. State whether the EIRP and EVM targets are met, and identify the additional hardware and calibration cost.

## 6. Inspect the matching-network alternative

Run:

```matlab
run("openMatchingNetworkModel.m")
```

The launcher loads the corporate splitter and patch-array workspace objects required by `RF_TX_Model_MN.slx`.
