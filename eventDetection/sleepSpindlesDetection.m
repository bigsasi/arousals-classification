function [spindles1, spindles2] = sleepSpindlesDetection(eeg1, eeg2, ...
    eegRate, emgRate)
%SLEEPSPINDLESANALYSIS Summary of this function goes here
%   Detailed explanation goes here

%% Configuration
    config = Configuration.getInstance;
    
    windowSize = config.spindlesWindowSize;
    windowStep = config.spindlesWindowStep;
    
    background = config.spindlesBackground;
    
    lcutoff = config.spindlesLcutoff;
    hcutoff = config.spindlesHcutoff;
    
    spindlesThreshold = config.spindlesThreshold;
    emgThreshold = config.spindlesEmgThreshold;
    alphaThreshold = config.spindlesAlphaThreshold;
    
%% Signal parameters

    if floor(emgRate / 2) > 62.5
        hcutoff(2) = floor(emgRate / 2);
    end

    eegLength = length(eeg1);
        
    [spindlePower1, emgPower1, alphaPower1, deltaPower1, thetaPower1, ...
        betaPower1] = signalPower(eeg1, windowSize, eegRate, windowStep, ...
        lcutoff, hcutoff);


    totalPower = alphaPower1 + deltaPower1 + thetaPower1 + betaPower1;
    spindlePowerPercentage1 = spindlePower1 ./ totalPower .* 100;
    emgPowerPercentage1 = emgPower1 ./ totalPower .* 100;
    alphaPowerPercentage1 = alphaPower1 ./ totalPower .* 100;
    
    [spindlePower2, emgPower2, alphaPower2, deltaPower2, thetaPower2, ...
        betaPower2] = signalPower(eeg2, windowSize, eegRate, windowStep, ...
        lcutoff, hcutoff);


    totalPower = alphaPower2 + deltaPower2 + thetaPower2 + betaPower2;
    spindlePowerPercentage2 = spindlePower2 ./ totalPower .* 100;
    emgPowerPercentage2 = emgPower2 ./ totalPower .* 100;
    alphaPowerPercentage2 = alphaPower2 ./ totalPower .* 100;

    spindleBaseline1 = baseline(background, windowStep, spindlePower1);
    emgBaseline1 = baseline(background, windowStep, emgPower1);
    alphaBaseline1 = baseline(background, windowStep, alphaPower1);
    
    spindleBaseline2 = baseline(background, windowStep, spindlePower2);
    emgBaseline2 = baseline(background, windowStep, emgPower2);
    alphaBaseline2 = baseline(background, windowStep, alphaPower2);
    
%% Events detection

    spindleEvents1 = getSignalEvents(spindlePower1, spindlesThreshold, ...
        spindleBaseline1);
    emgEvents1 = getSignalEvents(emgPower1, emgThreshold, emgBaseline1);
    alphaEvents1 = getSignalEvents(alphaPower1, alphaThreshold, alphaBaseline1);
    
    spindleEvents2 = getSignalEvents(spindlePower2, spindlesThreshold, ...
        spindleBaseline2);
    emgEvents2 = getSignalEvents(emgPower2, emgThreshold, emgBaseline2);
    alphaEvents2 = getSignalEvents(alphaPower2, alphaThreshold, alphaBaseline2);
    
    spindlesDef1 = getSpindlesList(spindlePowerPercentage1, ...
        emgPowerPercentage1, alphaPowerPercentage1, spindleEvents1, ...
        emgEvents1, alphaEvents1, windowSize * eegRate, windowStep, ...
        windowStep * eegRate);
    
    spindlesDef2 = getSpindlesList(spindlePowerPercentage2, ...
        emgPowerPercentage2, alphaPowerPercentage2, spindleEvents2, ...
        emgEvents2, alphaEvents2, windowSize * eegRate, windowStep, ...
        windowStep * eegRate);
    
%% Output construction

    [spindles1, ~] = buildReasoningUnit(spindlesDef1, eegRate, eegLength, ...
        30 * eegRate);
    
    [spindles2, ~] = buildReasoningUnit(spindlesDef2, eegRate, eegLength, ...
        30 * eegRate);

end

