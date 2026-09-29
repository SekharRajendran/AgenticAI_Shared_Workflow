%% Open the four-element baseline model with its required relative paths

packageRoot = fileparts(mfilename("fullpath"));
helpersDir = fullfile(packageRoot, "helpers");

addpath(packageRoot);
addpath(helpersDir);
cd(helpersDir);
open_system(fullfile(packageRoot, "RF_TX_Model.slx"));
