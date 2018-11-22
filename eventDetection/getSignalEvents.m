function [events] = getSignalEvents(signalParameter, threshold, baseline)
%GETSIGNALEVENTS Return events for a signal parameter given a baseline and
%certain threshold
%   This functions returns an array with market events for a signal parameter
%   when this paraemter is higher than a baseline multiplied by a threshold.
    numWindows = length(signalParameter);

    events = zeros(numWindows, 1, 'int8');
    events(signalParameter > (threshold * baseline)) = 1;
    % To avoid problems for detecting events starting and ending points, do not
    % allow to start or end with an event.
    events(1) = 0;
    events(end) = 0;
end


