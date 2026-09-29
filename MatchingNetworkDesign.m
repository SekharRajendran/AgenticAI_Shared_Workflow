fRF = 12e9;
BW = 1e8;
N = 4;
rfAntenna = design(patchMicrostripCircular, fRF);
rfAntenna.Radius = 7e-3;
pattern(rfAntenna, fRF);
antennaSparam = sparameters(rfAntenna, [-2*BW, 2*BW]+fRF, ...
    'SweepOption', 'interp');

antennaArray  = linearArray(Element=rfAntenna,...
    ElementSpacing=rfAntenna.Radius*2.1, ... %max(rfAntenna.Radius*2.1,lambda/2),...
    NumElements=N,Tilt=-90);
pattern(antennaArray, fRF);
arraySparam = sparameters(antennaArray, [-2*BW, 2*BW]+fRF, ...
    'SweepOption', 'interp');

%% Design matching networks (one per element, using array S-parameters)
freq = arraySparam.Frequencies;
sData = arraySparam.Parameters;
matchNetworks = cell(1, N);

for k = 1:N
    elemSdata = squeeze(sData(k, k, :));
    elemSparam = sparameters(reshape(elemSdata, 1, 1, []), freq);

    mn = matchingnetwork( ...
        'SourceImpedance', 50, ...
        'LoadImpedance', elemSparam, ...
        'CenterFrequency', fRF, ...
        'Bandwidth', BW, ...
        'Components', 2);

    addEvaluationParameter(mn, 'gammain', '<', -15, [-BW/2 BW/2]+fRF, 2);
    addEvaluationParameter(mn, 'Gt', '>', -1, [-BW/2 BW/2]+fRF, 1);

    [topology, performance] = circuitDescriptions(mn);
    fprintf('Element %d — best score: %.2f\n', k, performance.performanceScore{1});
    disp(topology(1,:));

    matchNetworks{k} = exportCircuits(mn);
end

%% Compare S(k,k) without and with matching networks
figure;
tiledlayout(1, N);
for k = 1:N
    nexttile;

    % Without MN: raw array S_kk
    skk = squeeze(sData(k, k, :));
    skk_dB = 20*log10(abs(skk));

    % With MN: cascade matching network + antenna load
    ckt = matchNetworks{k};
    abcdMN = abcdparameters(sparameters(ckt, freq));
    ZL = 50 * (1 + skk) ./ (1 - skk);
    gammaIn = zeros(size(freq));
    for f = 1:numel(freq)
        A = abcdMN.Parameters(1,1,f);
        B = abcdMN.Parameters(1,2,f);
        C = abcdMN.Parameters(2,1,f);
        D = abcdMN.Parameters(2,2,f);
        Zin = (A*ZL(f) + B) / (C*ZL(f) + D);
        gammaIn(f) = (Zin - 50) / (Zin + 50);
    end
    skk_matched_dB = 20*log10(abs(gammaIn));

    plot(freq/1e9, skk_dB, 'b', freq/1e9, skk_matched_dB, 'r', 'LineWidth', 1.5);
    xlabel('Frequency (GHz)'); ylabel('dB');
    title(sprintf('Element %d', k));
    legend('No MN', 'With MN', 'Location', 'best');
    grid on;
end
sgtitle('S_{kk} comparison: without vs with matching network');

%% Populate Simulink model with matching network values
mdl = 'RF_TX_Model_MN';
load_system(mdl);

cBlockNames = {'C', 'C1', 'C2', 'C3'};
lBlockNames = {'L', 'L1', 'L2', 'L3'};

for k = 1:N
    ckt = matchNetworks{k};
    elements = ckt.Elements;

    for e = 1:numel(elements)
        el = elements(e);
        if isa(el, 'capacitor')
            set_param([mdl '/' cBlockNames{k}], 'Capacitance', num2str(el.Capacitance));
            fprintf('Element %d: C = %.4g F\n', k, el.Capacitance);
        elseif isa(el, 'inductor')
            set_param([mdl '/' lBlockNames{k}], 'Inductance', num2str(el.Inductance));
            fprintf('Element %d: L = %.4g H\n', k, el.Inductance);
        end
    end
end

save_system(mdl, [], 'OverwriteIfChangedOnDisk', true);
