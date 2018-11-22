function [commonEvents] = compareEvents(expertEvents, alg1Name, alg1Events, ...
    alg2Name, alg2Events)
%COMPAREEVENTS Compare and order events between the expert and two different
%algorithms
%   Compare events between an expert and two different algorithms, returning an
%   ordered matrix where each row contains information about one event.
%   Information is placed in the specific column for the algorithm that detected
%   such event. If two or more events from different sources are related, the
%   columns for that event row contain the individual information from each
%   source. 
%
%   expertEvent:    events detected by the expert.
%   alg1Name:       name given to the first algorithm.
%   alg1Events:     events detected by the first algorithm.
%   alg2Name:       name given to the second algorithm.
%   alg2Events:     events detected by the second algorithm.
    global alg1StartName;
    global alg1DurationName;
    global alg2StartName;
    global alg2DurationName;
    
    alg1StartName = strcat(alg1Name, 'Start');
    alg1DurationName = strcat(alg1Name, 'Duration');
    alg2StartName = strcat(alg2Name, 'Start');
    alg2DurationName = strcat(alg2Name, 'Duration');
    
    for k = 1:length(expertEvents), expertEvents(k).source = 0; end
    for k = 1:length(alg1Events), alg1Events(k).source = 1; end
    for k = 1:length(alg2Events), alg2Events(k).source = 2; end
    
    orderedEvents = order(expertEvents, alg1Events);
    orderedEvents = order(orderedEvents, alg2Events);
    
    totalEvents = length(orderedEvents);

    commonEvents(totalEvents).expertStart = 0;
    commonEvents(totalEvents).expertDuration = 0;
    commonEvents(totalEvents).(alg1StartName) = 0;
    commonEvents(totalEvents).(alg1DurationName) = 0;
    commonEvents(totalEvents).(alg2StartName) = 0;
    commonEvents(totalEvents).(alg2DurationName) = 0;
    
    commonEvents(1) = copyEvent(orderedEvents(1));
    lastCommon = 2;
    
    for i = 2:totalEvents
        prevSource = orderedEvents(i - 1).source;
        source = orderedEvents(i).source;
        if source ~= prevSource
            intersec = min(orderedEvents(i - 1).duration, 3);
            if orderedEvents(i).start + intersec <= orderedEvents(i - 1).start + orderedEvents(i - 1).duration
                commonEvents(lastCommon - 1) = updateEvent(commonEvents(lastCommon - 1), orderedEvents(i));
            else
                commonEvents(lastCommon) = copyEvent(orderedEvents(i));
                lastCommon = lastCommon + 1;
            end
        else
            commonEvents(lastCommon) = copyEvent(orderedEvents(i));
            lastCommon = lastCommon + 1;
        end
    end
    
    commonEvents(lastCommon:end) = [];
    
    for i=1:length(commonEvents)
        expertStart = commonEvents(i).expertStart;
        expertEnd = expertStart + commonEvents(i).expertDuration;
        
        alg1Start = commonEvents(i).(alg1StartName);
        alg1End = alg1Start + commonEvents(i).(alg1DurationName);
        
        alg2Start = commonEvents(i).(alg2StartName);
        alg2End = alg2Start + commonEvents(i).(alg2DurationName);
        
        
        commonEvents(i).ctExpertAlg1 = 0;
        commonEvents(i).ctExpertAlg2 = 0;
        commonEvents(i).ctAlg1Alg2 = 0;
        commonEvents(i).commonTime = 0;
        
        if expertStart > 0 && alg1Start > 0, commonEvents(i).ctExpertAlg1 = ...
                min(expertEnd, alg1End) - max(expertStart, alg1Start); end
        
        if expertStart > 0 && alg2Start > 0, commonEvents(i).ctExpertAlg2 = ...
                min(expertEnd, alg2End) - max(expertStart, alg2Start); end
        
        if alg1Start > 0 && alg2Start > 0, commonEvents(i).ctAlg1Alg2 = ...
                min(alg1End, alg2End) - max(alg1Start, alg2Start); end
        
        if alg1Start > 0 && alg2Start > 0 && expertStart > 0
            minEnd = min(expertEnd, min(alg1End, alg2End));
            maxStart = max(expertStart, max(alg1Start, alg2Start));
            commonEvents(i).commonTime = minEnd - maxStart;
        end
    end
end

function commonEvent = updateEvent(commonEvent, orderedEvent)
    global alg1StartName;
    global alg1DurationName;
    global alg2StartName;
    global alg2DurationName;
    
    if orderedEvent.source == 0
        commonEvent.expertStart = orderedEvent.start;
        commonEvent.expertDuration = orderedEvent.duration;
    elseif orderedEvent.source == 1
        commonEvent.(alg1StartName) = orderedEvent.start;
        commonEvent.(alg1DurationName) = orderedEvent.duration;    
    else
        commonEvent.(alg2StartName) = orderedEvent.start;
        commonEvent.(alg2DurationName) = orderedEvent.duration;
    end
end

function commonEvent = copyEvent(orderedEvent)
    global alg1StartName;
    global alg1DurationName;
    global alg2StartName;
    global alg2DurationName;
    
    commonEvent.expertStart = 0;
    commonEvent.expertDuration = 0;
    commonEvent.(alg1StartName) = 0;
    commonEvent.(alg1DurationName)= 0;
    commonEvent.(alg2StartName) = 0;
    commonEvent.(alg2DurationName) = 0;
    
    if orderedEvent.source == 0
        commonEvent.expertStart = orderedEvent.start;
        commonEvent.expertDuration = orderedEvent.duration;
    elseif orderedEvent.source == 1
        commonEvent.(alg1StartName) = orderedEvent.start;
        commonEvent.(alg1DurationName) = orderedEvent.duration;    
    else
        commonEvent.(alg2StartName) = orderedEvent.start;
        commonEvent.(alg2DurationName) = orderedEvent.duration;
    end
end

function orderedEvents = order(events1, events2)
    numEvents1 = length(events1);
    numEvents2 = length(events2);
    orderedEvents(numEvents1 + numEvents2).start = 0;
    
    lastEvent2 = 1;
    lastCommon = 1;
    for i = 1:numEvents1
        start1 =  events1(i).start;
        for j = lastEvent2:numEvents2
            start2 = events2(j).start;
            if start2 < start1
                orderedEvents(lastCommon).start = events2(j).start;
                orderedEvents(lastCommon).duration = events2(j).duration;
                orderedEvents(lastCommon).source = events2(j).source;
                lastCommon = lastCommon + 1;
                lastEvent2 = lastEvent2 + 1;
            else
                break;
            end
        end
        orderedEvents(lastCommon).start = events1(i).start;
        orderedEvents(lastCommon).duration = events1(i).duration;
        orderedEvents(lastCommon).source = events1(i).source;
        lastCommon = lastCommon + 1;
    end
    
    for j = lastEvent2:numEvents2
        orderedEvents(lastCommon).start = events2(j).start;
        orderedEvents(lastCommon).duration = events2(j).duration;
        orderedEvents(lastCommon).source = events2(j).source;
        lastCommon = lastCommon + 1;
    end
end