%% Verify the shared Antenna-to-Bits workflow package

packageRoot = fileparts(mfilename("fullpath"));
addpath(packageRoot);
addpath(fullfile(packageRoot, "helpers"));

productName = [ ...
    "RF Toolbox"
    "Antenna Toolbox"
    "Simulink"
    "5G Toolbox (waveform and EVM reruns)"];
isLicensed = [ ...
    license("test", "RF_Toolbox")
    license("test", "Antenna_Toolbox")
    license("test", "Simulink")
    license("test", "5G_Toolbox")];

requiredFile = [ ...
    fullfile(packageRoot, "Agentic AI Antenna-to-bits Reference Chain.docx")
    fullfile(packageRoot, "Antenna2BitsDemoLive.pdf")
    fullfile(packageRoot, "build12GHzTransmitterRFBudget.m")
    fullfile(packageRoot, "buildReferenceRFBudgetAnalyzer.m")
    fullfile(packageRoot, "helpers", "CMD240withNF.s2p")
    fullfile(packageRoot, "helpers", "WilkinsonSplitterData.mat")
    fullfile(packageRoot, "RF_TX_Model.slx")
    fullfile(packageRoot, "RF_TX_Model8.slx")];
fileAvailable = isfile(requiredFile);

fprintf("Product check:\n");
disp(table(productName, isLicensed, VariableNames=["Product", "Licensed"]));
fprintf("Workflow-asset check:\n");
disp(table(requiredFile, fileAvailable, ...
    VariableNames=["File", "Available"]));

if ~all(isLicensed(1:3))
    error("RF Toolbox, Antenna Toolbox, and Simulink are required.");
end
if ~all(fileAvailable)
    error("The package is incomplete. Re-extract the shared-workflow ZIP.");
end
if ~isLicensed(4)
    warning("5G Toolbox is unavailable. The budget and models can be inspected, " + ...
        "but the NR waveform and EVM workflow cannot be rerun.");
end
