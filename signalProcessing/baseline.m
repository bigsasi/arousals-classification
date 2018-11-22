function [baseline] = baseline(backgroundTime, windowStep, signalParameter)
%BASELINE Mean baseline for a signal parameter
%   
%   This function returns a baseline for a given signal parameter using the
%   desired background.
%
%   backgroundTime  time in seconds for the background mean
%   windowStep      time in seconds one window is displaced from the previous one
%   signalParameter the parameter for wich the baseline is being calculated.
%   baseline        output baseline containing for each window the mean value for the
%                   previous backgroundTime seconds

    backgroundSize = round(backgroundTime / windowStep);
	backgroundWindows = length(1:windowStep:backgroundTime);
    numWindows = length(signalParameter);
    
    rawBaseline = zeros(backgroundSize, numWindows);
    background(1:backgroundSize) = mean(signalParameter(1:backgroundWindows));
    next = 1;
    for k = 1:numWindows
        rawBaseline(:, k) = background;
        next = next + 1;
        background(next) = signalParameter(k);
        if next == backgroundSize, next = 0; end
    end
    baseline = sum(rawBaseline, 1)' / backgroundSize;
end

