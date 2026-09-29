# Antenna-to-Bits Shared Workflow

This is a complete, shareable copy of the original `AgenticAI` workflow folder. Its source structure has been preserved so MATLAB scripts, models, and helper data retain their existing relative paths.

## Begin here

1. Read `Agentic AI Antenna-to-bits Reference Chain.docx`. It is the design specification.
2. Read `Antenna2BitsDemoLive.pdf`. It shows the intended end-to-end demo sequence.
3. In MATLAB, change to this folder and run:

   ```matlab
   StartHere
   ```

## Workflow sequence

1. Use the Word specification to identify the 4 GHz IF, 8 GHz LO, 12 GHz RF, 100 MHz bandwidth, and -20 dBm baseline.
2. Review and run `build12GHzTransmitterRFBudget.m`.
3. Run `buildReferenceRFBudgetAnalyzer.m` to show the budget in RF Budget Analyzer.
4. Use the PDF and `helpers/WilkinsonSplitterData.mat` to inspect the EM-derived corporate Wilkinson splitter; `helpers/CMD240withNF.s2p` is the LNA/driver Touchstone file used by the budget.
5. Open `RF_TX_Model.slx` for the baseline RF system model.
6. Open `RF_TX_Model8.slx` for the alternative array model used to address the EIRP gap.
7. Compare EIRP, EVM, ACLR, hardware count, and calibration burden against the original objective.

## Traceability

| Workflow need | Source file |
|---|---|
| Design specification | `Agentic AI Antenna-to-bits Reference Chain.docx` |
| Detailed demo procedure | `Antenna2BitsDemoLive.pdf` |
| One-path RF budget at -20 dBm | `build12GHzTransmitterRFBudget.m` |
| Budget Analyzer launcher | `buildReferenceRFBudgetAnalyzer.m` |
| LNA/driver S-parameters | `helpers/CMD240withNF.s2p` |
| EM-derived Wilkinson S-parameters | `helpers/WilkinsonSplitterData.mat` |
| Baseline model | `RF_TX_Model.slx` |
| Resolution model | `RF_TX_Model8.slx` |

## Distribution scope

All original source scripts, models, helper files, data files, PDFs, and result examples from `AgenticAI` are included. Simulink build caches (`slprj`) and `.slxc` cache files are intentionally excluded because MATLAB regenerates them.

## GitHub repository readiness

This folder includes `.gitignore`, `.gitattributes`, contribution guidance, and GitHub issue/PR templates. Read `GITHUB_PUBLISH.md` before creating a remote repository.

Default to a **private** repository until the redistribution rights for the Word/PDF documentation, S-parameter files, EM data, and model assets are confirmed. See `DISTRIBUTION_NOTICE.md`.
