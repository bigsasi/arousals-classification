function [arousalsOutput] = arousalsDetection(eeg1, eeg2, eegRate, ...
    emg, emgRate, sleepStages)
%ANALISISAROUSALS Summary of this function goes here
%   Detailed explanation goes here


%% Configuration variables
    
    config = Configuration.getInstance;

    windowSize = config.arousalWindowSize;
    windowStep = config.arousalWindowStep;
    background = config.arousalBackground;
    arousalThreshold = config.arousalThreshold;
    alphaThreshold = config.arousalAlphaThreshold;
    thetaThreshold = config.arousalThetaThreshold;
    gradientLimit = config.arousalGradientLimit;
    
    lcutoff = config.arousalLcutoff;
    hcutoff = config.arousalHcutoff;
    
    epochDuration = config.epochDuration;    
    
    
%% Signal parameters 

%     if floor(emgRate / 2) > hcutoff(1)
%         hcutoff(1) = floor(emgRate / 2); 
%     end
    
    eegLength = length(eeg1);
    totalWindows = length(1:eegRate * windowStep:eegLength);
    
    [emgPower1, alphaPower1, thetaPower1] = signalPower(eeg1, windowSize, eegRate, ...
        windowStep, lcutoff, hcutoff);
    
    [emgPower2, alphaPower2, thetaPower2] = signalPower(eeg2, windowSize, eegRate, ...
        windowStep, lcutoff, hcutoff);
    
    emgBaseline1 = baseline(background, windowStep, emgPower1);
    alphaBaseline1 = baseline(background, windowStep, alphaPower1);
    thetaBaseline1 = baseline(background, windowStep, thetaPower1);
    
    emgBaseline2 = baseline(background, windowStep, emgPower2);
    alphaBaseline2 = baseline(background, windowStep, alphaPower2);
    thetaBaseline2 = baseline(background, windowStep, thetaPower2);
    
    backWindows = round(background / windowStep);
    arousalBaseline1 = emgBaseline1;
    for k = 1:totalWindows
        ref = max(k - backWindows, 1);
        high = emgBaseline1(k) - emgBaseline1(ref);
        gradient = high / backWindows;
        if gradient > gradientLimit
            arousalBaseline1(ref:k) = arousalBaseline1(max(ref - 1, 1));
        end
    end
    
    arousalBaseline2 = emgBaseline2;
    for k = 1:totalWindows;
        ref = max(k - backWindows, 1);
        high = emgBaseline2(k) - emgBaseline2(ref);
        gradient = high / backWindows;
        if gradient > gradientLimit
            arousalBaseline2(ref:k) = arousalBaseline2(max(ref - 1, 1));
        end
    end
    
%% Events detection
    alphaEvents1 = getSignalEvents(alphaPower1, alphaThreshold, alphaBaseline1);
    arousalEvents1 = getSignalEvents(emgPower1, arousalThreshold, arousalBaseline1);
    thetaEvents1 = getSignalEvents(thetaPower1, thetaThreshold, thetaBaseline1);
        
    alphaEvents1 = extendEvents(alphaEvents1, alphaPower1, alphaThreshold, alphaBaseline1);
    arousalEvents1 = extendEvents(arousalEvents1, emgPower1, arousalThreshold, arousalBaseline1);
    thetaEvents1 = extendEvents(thetaEvents1, thetaPower1, thetaThreshold, thetaBaseline1);  
    
    alphaEvents1 = clearEvents(alphaEvents1, alphaPower1, alphaThreshold, alphaBaseline1);
    arousalEvents1 = clearEvents(arousalEvents1, emgPower1, arousalThreshold, arousalBaseline1);
    thetaEvents1 = clearEvents(thetaEvents1, thetaPower1, thetaThreshold, thetaBaseline1);  
    
    alphaEvents2 = getSignalEvents(alphaPower2, alphaThreshold, alphaBaseline2);
    arousalEvents2 = getSignalEvents(emgPower2, arousalThreshold, arousalBaseline2);    
    thetaEvents2 = getSignalEvents(thetaPower2, thetaThreshold, thetaBaseline2);
        
    alphaEvents2 = extendEvents(alphaEvents2, alphaPower2, alphaThreshold, alphaBaseline2);
    arousalEvents2 = extendEvents(arousalEvents2, emgPower2, arousalThreshold, arousalBaseline2);
    thetaEvents2 = extendEvents(thetaEvents2, thetaPower2, thetaThreshold, thetaBaseline2);
    
    alphaEvents2 = clearEvents(alphaEvents2, alphaPower2, alphaThreshold, alphaBaseline2);
    arousalEvents2 = clearEvents(arousalEvents2, emgPower2, arousalThreshold, arousalBaseline2);
    thetaEvents2 = clearEvents(thetaEvents2, thetaPower2, thetaThreshold, thetaBaseline2);
    
    
    arousalsDef1 = getArousalsList(alphaEvents1, arousalEvents1, thetaEvents1, ...
        windowSize * eegRate, windowStep, windowStep * eegRate, eeg1);

    
    arousalsDef2 = getArousalsList(alphaEvents2, arousalEvents2, thetaEvents2, ...
        windowSize * eegRate, windowStep, windowStep * eegRate, eeg2);
    
    % EMG Events, with KC configuration
    windowSizeKC = windowSize;
    windowStepKC = 2 * windowStep;
    background2 = 3 * background;
    
    emgAmplitude = signalAmplitude(emg, emgRate, windowSizeKC, windowStepKC);
    emgAmplitudeBaseline = baseline(background2, windowStepKC, emgAmplitude);
    emgEvents = getEMGAmplEvents(emgAmplitudeBaseline, emgAmplitude, windowStepKC, eegRate, windowSizeKC);
    
%% Build Output
    
    [arousalsEeg1, arousalsEeg2, arousalsEMG, arousalsOutput] = ...
        eegArousalsTimeCorrelation(sleepStages, 30, emgRate, ...
        eegRate, arousalsDef1, arousalsDef2, emgEvents);
    
    save ('lastArousalDetection.mat', '-v6', 'alphaBaseline1', 'alphaBaseline2', ...
        'alphaEvents1', 'alphaEvents2', 'alphaPower1', 'alphaPower2', ...
        'arousalBaseline1', 'arousalBaseline2', 'arousalEvents1', ...
        'arousalEvents2', 'arousalsEeg1', 'arousalsEeg2', 'arousalsEMG', ...
        'arousalsOutput', 'emgAmplitude', 'emgAmplitudeBaseline', ...
        'emgBaseline1', 'emgBaseline2', 'emgEvents', 'emgPower1', ...
        'emgPower2', 'thetaBaseline1', 'thetaBaseline2', 'thetaEvents1', ...
        'thetaEvents2', 'thetaPower1', 'thetaPower2', 'sleepStages', ...
        'arousalsDef1', 'arousalsDef2', 'eeg1', 'eeg2');
end

function events = extendEvents(prevEvents, parameter, threshold, baseline)
    config = Configuration.getInstance;
    
    originalThreshold = threshold;
    parameterLength = length(parameter);
    events = prevEvents;
    if config.eventSurrounding == 0
        return
    end
    for k = 1:3
        threshold = max(threshold * config.thresholdSmoothing, originalThreshold / 2);
        [startIndex, endIndex] = getEventIndexes(events);
        for i = 1:length(startIndex)
%             if startIndex(i) <= 5793 && endIndex(i) >= 5793
%                 keyboard
%             end
            eventDuration = endIndex(i) - startIndex(i) + 1;
            surrounding = max(ceil(eventDuration * 0.1), config.eventSurrounding);
            
            signalThreshold = parameter(startIndex(i)) / baseline(startIndex(i)) * config.thresholdSmoothing;
            applyThreshold = min(signalThreshold, threshold);
            range = max(1, startIndex(i) - surrounding):startIndex(i);
            events(range) = parameter(range) > baseline(range) .* applyThreshold;
            
            signalThreshold = parameter(endIndex(i)) / baseline(endIndex(i)) * config.thresholdSmoothing;
            range = endIndex(i):min(endIndex(i) + surrounding, parameterLength);
            applyThreshold = min(signalThreshold, threshold);
            events(range) = parameter(range) > baseline(range) .* applyThreshold;
        end
        events(1) = 0;
        events(end) = 0;
    end
    
    [inicios, fines] = getEventIndexes(events);
    for k = 1:length(inicios) - 1
        length1 = fines(k) - inicios(k);
        length2 = fines(k + 1) - inicios(k + 1);
        if fines(k) + length1 >= inicios(k + 1) || ...
           fines(k) + length2 >= inicios(k + 1)
            range = fines(k):inicios(k + 1);
            signalThreshold = parameter(range) ./ baseline(range);
            if all(signalThreshold) > 1
                events(fines(k):inicios(k + 1)) = 1;
            end
        end
    end
end

function events = clearEvents(prevEvents, parameter, threshold, baseline)
    events = prevEvents;
    [inicios, fines] = getEventIndexes(events);
    for k = 1:length(inicios)

        range = inicios(k):fines(k);
        signalThreshold = parameter(range) ./ baseline(range);
        overThreshold = sum(signalThreshold(signalThreshold > threshold) - threshold);
        belowThreshold = sum(threshold - signalThreshold(signalThreshold < threshold));
        first = inicios(k);
        last = fines(k);
        for i = inicios(k):fines(k);
            signalThreshold = parameter(i) / baseline(i);
            if signalThreshold > threshold
                first = i;
                break
            end
            belowThreshold = belowThreshold + (threshold - signalThreshold);
        end
        for i = fines(k):-1:inicios(k)
            signalThreshold = parameter(i) / baseline(i);
            if signalThreshold > threshold
                last = i;
                break
            end
            belowThreshold = belowThreshold + (threshold - signalThreshold);
        end

        if belowThreshold > overThreshold
            events(inicios(k):first - 1) = 0;
            events(last + 1:fines(k)) = 0;
        end
    end
end