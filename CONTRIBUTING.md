# Contributing

## Before editing

1. Run `StartHere`.
2. Read `START_HERE.md` to identify the stage you are changing.
3. Preserve the link from specification to RF budget to Simulink model.

## MATLAB and Simulink changes

- Keep source `.m` scripts readable and use relative paths.
- When changing an `.slx` model, include the related source/script change or explain why the model-only change is necessary.
- Do not commit `slprj/`, `.slxc`, autosave files, or locally generated ZIP packages.
- Keep source S-parameter and helper data under `helpers/`; do not replace them with machine-specific paths.

## Minimum validation

Run:

```matlab
StartHere
run("build12GHzTransmitterRFBudget.m")
runtests("tests", Tag="Unit")
```

Then confirm the budget still uses the 4 GHz IF, 8 GHz LO, 100 MHz bandwidth, -20 dBm input point, `CMD240withNF.s2p`, and `WilkinsonSplitterData.mat`.

If the change affects a model, also run:

```matlab
runtests("tests", Tag="Integration")
```

If 5G Toolbox is available, also rerun the waveform/EVM workflow.
