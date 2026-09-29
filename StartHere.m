%% Antenna-to-Bits shared workflow entry point
% Run from any MATLAB working folder. This script moves MATLAB to the
% package root, verifies the required assets, and prints the guided steps.

packageRoot = fileparts(mfilename("fullpath"));
cd(packageRoot);
run(fullfile(packageRoot, "checkPackage.m"));

fprintf("\nAntenna-to-Bits shared workflow\n");
fprintf("1. Read: Agentic AI Antenna-to-bits Reference Chain.docx\n");
fprintf("2. Run: build12GHzTransmitterRFBudget.m\n");
fprintf("3. Analyze: buildReferenceRFBudgetAnalyzer.m\n");
fprintf("4. Review: Antenna2BitsDemoLive.pdf\n");
fprintf("5. Open baseline: openBaselineModel.m\n");
fprintf("6. Open resolution: openResolutionModel.m\n");
fprintf("7. Open matching network: openMatchingNetworkModel.m\n");
fprintf("\nSee START_HERE.md for the required checks at each step.\n");
