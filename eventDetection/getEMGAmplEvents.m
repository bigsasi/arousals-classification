function [emgAmplEvents, signalEvents] = getEMGAmplEvents(emgBaseline, ...
    emgAmplitude, windowStep, signalRate, windowSize)
%GETEMGAMPLEVENTS Summary of this function goes here
%   Detailed explanation goes here

    thresholdAmplEMG = 1.5;

    numWindows = length(emgBaseline);
    windowSizeSamples = round(windowSize * signalRate);
    windowStepSamples = round(windowStep * signalRate);
    delay = round((windowSizeSamples - windowStepSamples) / 2); % In samples

    signalEvents = zeros(numWindows, 1, 'int8');
    signalEvents(emgAmplitude > (emgBaseline * thresholdAmplEMG)) = 1;

    minDuration = ceil(0.5 / windowStep);

    % EMG amplitude events (discarding those with duration less than 0.5 secs)
    [inicios, fines] = getEventIndexes(signalEvents);
    for k = 1:length(inicios)
        if length(inicios(k):fines(k)) < minDuration
            signalEvents(inicios(k):fines(k)) = 0;
        end
    end

    [inicios, fines] = getEventIndexes(signalEvents);
    inicios = inicios * windowStepSamples + delay;
    fines = fines * windowStepSamples + delay;
    emgAmplEvents = zeros(length(inicios), 2, 'single');
    for k = 1:length(inicios)
        emgAmplEvents(k,:) = [inicios(k), fines(k)];
    end

end

