function [mean] = signalMean(signal, signalRate, windowSize, windowStep)
%SIGNALAMPLITUDE Summary of this function goes here
%   Detailed explanation goes here
    windowStepSamples = signalRate * windowStep;
    windowSizeSamples = signalRate * windowSize;
    signalLength = length(signal);
    
    numWindows = length(1:windowStepSamples:signalLength);
    mean = zeros(numWindows, 1);
    
    currentWindow = 0;
    for currentSample = 1:windowStepSamples:signalLength - windowSizeSamples
        currentWindow = currentWindow + 1;
        sample = floor(currentSample);
        limit = sample + windowSizeSamples - 1;
        
        selectedWindow = signal(sample:limit);
        
        mean(currentWindow) = sum(selectedWindow);
    end
    
    currentSample = currentSample + windowStepSamples;
    for currentSample = currentSample:windowStepSamples:signalLength
        currentWindow = currentWindow + 1;
        sample = floor(currentSample);
        limit = signalLength;
        
        selectedWindow = signal(sample:limit);
        
        mean(currentWindow) = sum(selectedWindow);
    end
    
    mean = mean / windowSizeSamples;
end

