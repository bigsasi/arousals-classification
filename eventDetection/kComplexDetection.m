function [kcomplex1, kcomplex2] = kComplexDetection(eeg1, eeg2, eegRate, ...
    emg, emgRate)
%ANALISISKCOMPLEX Summary of this function goes here
%   Detailed explanation goes here

%% Configuration
    config = Configuration.getInstance;
    
    windowSize = config.kcomplexWindowSize;
    windowStep = config.kcomplexWindowStep;
    
    lcutoff = config.kcomplexLcutoff;
    hcutoff = config.kcomplexHcutoff;
    
    background = config.kcomplexBackground;
    
    deltaThreshold = config.kcomplexDeltaThreshold;
    emgThreshold = config.kcomplexEmgThreshold;
    
%% Signal parameters

    if floor(emgRate / 2) > 62.5
        hcutoff(1) = floor(emgRate / 2);
    end

    eegLength = length(eeg1);
        
    [emgPower1, alphaPower1, deltaPower1, thetaPower1, betaPower1] = ...
        signalPower(eeg1, windowSize, eegRate, windowStep, lcutoff, hcutoff);


    totalPower = alphaPower1 + deltaPower1 + thetaPower1 + betaPower1;
    emgPowerPercentage1 = emgPower1 ./ totalPower .* 100;
    alphaPowerPercentage1 = alphaPower1 ./ totalPower .* 100;

    [emgPower2, alphaPower2, deltaPower2, thetaPower2, betaPower2] = ...
        signalPower(eeg2, windowSize, eegRate, windowStep, lcutoff, hcutoff);


    totalPower = alphaPower2 + deltaPower2 + thetaPower2 + betaPower2;
    emgPowerPercentage2 = emgPower2 ./ totalPower .* 100;
    alphaPowerPercentage2 = alphaPower2 ./ totalPower .* 100;
    
    emgAmplitude = signalAmplitude(emg, emgRate, windowSize, windowStep);
    
    emgAmplitudeBaseline = baseline(background, windowStep, emgAmplitude);
    
    deltaBaseline1 = baseline(background, windowStep, deltaPower1);
    emgBaseline1 = baseline(background, windowStep, emgPower1);
    
    deltaBaseline2 = baseline(background, windowStep, deltaPower2);
    emgBaseline2 = baseline(background, windowStep, emgPower2);
    
%% Events detection

    minDuration = ceil(0.5 / windowStep);

    emgAmplitudeEvents = getSignalEvents(emgAmplitude, 1.5, emgAmplitudeBaseline);
    [inicios, fines] = getEventIndexes(emgAmplitudeEvents);
    for k = 1:length(inicios)
        if fines(k) - inicios(k) < minDuration
            emgAmplitudeEvents(inicios(k):fines(k)) = 0;
        end
    end
    
    deltaEvents1 = getSignalEvents(deltaPower1, deltaThreshold, deltaBaseline1);
    emgEvents1 = getSignalEvents(emgPower1, emgThreshold, emgBaseline1);
    
    deltaEvents2 = getSignalEvents(deltaPower2, deltaThreshold, deltaBaseline2);
    emgEvents2 = getSignalEvents(emgPower2, emgThreshold, emgBaseline2);
    
    kcomplexDef1 = getKComplexList(emgPowerPercentage1, ...
        alphaPowerPercentage1, eegRate, windowStep, windowStep, ...
        deltaEvents1, emgEvents1, windowSize * eegRate, emgAmplitudeEvents);

    kcomplexDef2 = getKComplexList(emgPowerPercentage2, ...
        alphaPowerPercentage2, eegRate, windowStep, windowStep, ...
        deltaEvents2, emgEvents2, windowSize * eegRate, emgAmplitudeEvents);

%% Output construction

    [kcomplex1, ~] = buildReasoningUnit(kcomplexDef1, eegRate,...
        eegLength, 30 * eegRate);

    [kcomplex2, ~] = buildReasoningUnit(kcomplexDef2, eegRate,...
        eegLength, 30 * eegRate);
end

