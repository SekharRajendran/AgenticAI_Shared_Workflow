%% Open the matching-network model with its required EM workspace objects

packageRoot = fileparts(mfilename("fullpath"));
helpersDir = fullfile(packageRoot, "helpers");

addpath(packageRoot);
addpath(helpersDir);

patchData = load(fullfile(helpersDir, "PatchArray_N4.mat"), "antennaArray");
splitterData = load( ...
    fullfile(helpersDir, "WilkinsonSplitterData.mat"), ...
    "splitterCorporate");

assignin("base", "antennaArray", patchData.antennaArray);
assignin("base", "splitterCorporate", splitterData.splitterCorporate);

cd(helpersDir);
open_system(fullfile(packageRoot, "RF_TX_Model_MN.slx"));
