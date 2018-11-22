function EEGarousals = getArousalsList(alphaEvents, arousalEvents, thetaEvents, ...
    windowSizeSamples, windowStep, windowStepSamples, eeg)

config = Configuration.getInstance;

minDurationArousal = ceil(config.arousalMinDuration / windowStep);
% numWindows = length(alphaEvents);
delay = round((windowSizeSamples - windowStepSamples) / 2); % In samples

% arousalsEvents = zeros(numWindows, 1, 'int8');
% arousalsEvents(emgPower > thresholdArousal) = 1;
% arousalEvents = arousalEvents;
% Avoid problems erasing starting and ending events
arousalEvents(1) = 0;
arousalEvents(end) = 0;
[inicios, fines] = getEventIndexes(arousalEvents);
for k = 1:length(inicios)
    if fines(k) - inicios(k) < ceil(config.arousalEventDuration / windowStep)
        arousalEvents(inicios(k):fines(k)) = 0;
    end
end

% Establish Alpha arousal events
[inicios, fines] = getEventIndexes(alphaEvents);
for k = 1:length(inicios)
    if fines(k) - inicios(k) > ceil(config.arousalEventDuration / windowStep)
        arousalEvents(inicios(k):fines(k)) = 1;
    end
end

% Establish Theta arousal events
[inicios, fines] = getEventIndexes(thetaEvents);
for k = 1:length(inicios)
    if fines(k) - inicios(k) > ceil(config.arousalEventDuration / windowStep)
        arousalEvents(inicios(k):fines(k)) = 1;
    end
end

% noisySignal = alphaEvents + thetaEvents + arousalEvents;

% Discard events with duration less than 3 seconds
[inicios, fines] = getEventIndexes(arousalEvents);
for k = 1:length(inicios)
    if fines(k) - inicios(k) < minDurationArousal
        arousalEvents(inicios(k):fines(k)) = 0;
    end
%     if any(noisySignal(inicios(k):fines(k)) == 3)
%         arousalEvents(inicios(k):fines(k)) = 0;
%     end
end

% [inicios, fines] = getEventIndexes(arousalEvents);
% for k = 1:length(inicios)
%     initialSample = round(inicios(k) * windowStepSamples);
%     endSample = round(fines(k) * windowStepSamples);
%     if sum(eeg(initialSample:endSample) == max(eeg)) >= 5 || ...
%     sum(any(eeg(initialSample:endSample) == min(eeg))) >= 5
%         arousalEvents(inicios(k):fines(k)) = 0;
%     end
% end

% Now we return back events indexes
tmp = diff(arousalEvents);
initialWindow = find(tmp == 1) + 1; 
initialSample = round(initialWindow * windowStepSamples + delay);
endWindow = find(tmp == -1);
endSample = min(round(endWindow * windowStepSamples + delay), length(eeg));


EEGarousals = zeros(length(initialSample), 4);
for k = 1:length(initialSample)
    EEGarousals(k,:) = [initialSample(k), endSample(k), initialWindow(k), endWindow(k)];
end