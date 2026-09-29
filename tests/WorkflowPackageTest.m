classdef WorkflowPackageTest < matlab.unittest.TestCase
    %WorkflowPackageTest Smoke and integration tests for the shared workflow.

    properties (Access = private)
        PackageRoot
        HelpersDir
    end

    methods (TestClassSetup)
        function configurePackage(testCase)
            testCase.PackageRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.HelpersDir = fullfile(testCase.PackageRoot, "helpers");
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture(testCase.PackageRoot));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture(testCase.HelpersDir));
        end
    end

    methods (Test, TestTags = {'Unit'})
        function testCoreAssetsExist(testCase)
            requiredFiles = [ ...
                fullfile(testCase.PackageRoot, ...
                    "Agentic AI Antenna-to-bits Reference Chain.docx")
                fullfile(testCase.PackageRoot, "Antenna2BitsDemoLive.pdf")
                fullfile(testCase.PackageRoot, ...
                    "build12GHzTransmitterRFBudget.m")
                fullfile(testCase.HelpersDir, "CMD240withNF.s2p")
                fullfile(testCase.HelpersDir, "WilkinsonSplitterData.mat")
                fullfile(testCase.PackageRoot, "RF_TX_Model.slx")
                fullfile(testCase.PackageRoot, "RF_TX_Model8.slx")
                fullfile(testCase.PackageRoot, "RF_TX_Model_MN.slx")];

            testCase.verifyTrue(all(isfile(requiredFiles)));
        end

        function testLnaTouchstoneLoads(testCase)
            networkData = sparameters( ...
                fullfile(testCase.HelpersDir, "CMD240withNF.s2p"));

            testCase.verifySize(networkData.Parameters, ...
                [2 2 numel(networkData.Frequencies)]);
        end

        function testWilkinsonDataLoads(testCase)
            splitterData = load( ...
                fullfile(testCase.HelpersDir, "WilkinsonSplitterData.mat"), ...
                "splitterCorporate", "splitterSparam");

            testCase.verifyClass(splitterData.splitterSparam, "sparameters");
            testCase.verifyNotEmpty(splitterData.splitterCorporate);
        end

        function testBaselineBudget(testCase)
            run(fullfile(testCase.PackageRoot, ...
                "build12GHzTransmitterRFBudget.m"));

            testCase.verifyEqual(budget.InputFrequency, 4e9, AbsTol=1);
            testCase.verifyEqual(budget.SignalBandwidth, 100e6, AbsTol=1);
            testCase.verifyEqual(budget.AvailableInputPower, -20, AbsTol=1e-12);
            testCase.verifyEqual(budget.OutputFrequency(end), 12e9, AbsTol=1);
            testCase.verifyEqual(budget.OutputPower(5), 18.87, AbsTol=0.1);
        end
    end

    methods (Test, TestTags = {'Integration'})
        function testBaselineModelCompiles(testCase)
            originalFolder = pwd;
            testCase.addTeardown(@() cd(originalFolder));
            cd(testCase.HelpersDir);

            in = Simulink.SimulationInput("RF_TX_Model");
            in = in.setModelParameter("StopTime", "0");
            out = sim(in);

            testCase.verifyTrue(any(strcmp(who(out), "tout")));
        end

        function testResolutionModelCompiles(testCase)
            originalFolder = pwd;
            testCase.addTeardown(@() cd(originalFolder));
            cd(testCase.HelpersDir);

            in = Simulink.SimulationInput("RF_TX_Model8");
            in = in.setModelParameter("StopTime", "0");
            out = sim(in);

            testCase.verifyTrue(any(strcmp(who(out), "tout")));
        end

        function testMatchingNetworkModelCompiles(testCase)
            originalFolder = pwd;
            testCase.addTeardown(@() cd(originalFolder));
            cd(testCase.HelpersDir);
            patchData = load( ...
                fullfile(testCase.HelpersDir, "PatchArray_N4.mat"), ...
                "antennaArray");
            splitterData = load( ...
                fullfile(testCase.HelpersDir, "WilkinsonSplitterData.mat"), ...
                "splitterCorporate");

            in = Simulink.SimulationInput("RF_TX_Model_MN");
            in = in.setModelParameter("StopTime", "0");
            in = in.setVariable("antennaArray", patchData.antennaArray);
            in = in.setVariable("splitterCorporate", ...
                splitterData.splitterCorporate);
            out = sim(in);

            testCase.verifyTrue(any(strcmp(who(out), "tout")));
        end
    end
end
