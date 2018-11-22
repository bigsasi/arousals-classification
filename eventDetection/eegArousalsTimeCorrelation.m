function [eeg1ArousalRU, eeg2ArousalRU, emgArousalRU, outputRU] = ...
    eegArousalsTimeCorrelation(SleepStages, epoch_duration, emgRate, eegRate, arousalsDef1, arousalsDef2, EMGArousals)

samplesEpoch = epoch_duration * eegRate;
numEpochs = length(SleepStages.Signal);
numSeconds = numEpochs * epoch_duration;
arousalsEeg1 = zeros(numSeconds, 1);
arousalsEeg2 = zeros(numSeconds, 1);
arousalsEmg = zeros(numSeconds, 1);
arousalsEpochEeg = zeros(numEpochs, 1);
arousalsEpochEegEmg = zeros(numEpochs, 1);
delta = 0; % Num seconds previous and after the detected event in which the event is considered for correlation

[eeg1ArousalRU, eeg1SignalEvents] = buildRU(arousalsDef1, eegRate, ...
    samplesEpoch, numEpochs);

for arousal = eeg1ArousalRU
    from = max(1, round(arousal.startSecond - delta));
    to = min(numSeconds, round(arousal.endSecond + delta));
    arousalsEeg1(from:to) = 1;    
end

[eeg2ArousalRU, eeg2SignalEvents] = buildRU(arousalsDef2, eegRate, ...
    samplesEpoch, numEpochs);

for arousal = eeg2ArousalRU
    from = max(1, round(arousal.startSecond - delta));
    to = min(numSeconds, round(arousal.endSecond + delta));
    arousalsEeg2(from:to) = 1;    
end

[emgArousalRU, emgSignalEvents] = buildRU(EMGArousals, emgRate, ...
    samplesEpoch, numEpochs);

for arousal = emgArousalRU
    from = max(1, round(arousal.startSecond - delta));
    to = min(numSeconds, round(arousal.endSecond + delta));
    arousalsEmg(from:to) = 1;    
end

arousalsEeg1Eeg2 = arousalsEeg1 & arousalsEeg2; % EEG1 & EGG2
arousalsEegEmg = arousalsEeg1Eeg2 & arousalsEmg; % EEG1 & EEG2 & EMG

% Array marking epochs with arousals both in eeg1 and eeg2
[inicios, fines] = getEventIndexes(arousalsEeg1Eeg2);
for k = 1:length(inicios)
    startSec = inicios(k);
    endSec = fines(k);
    epochNum = calculateEpoch(startSec, endSec, epoch_duration, numEpochs);
    arousalsEpochEeg(epochNum) = 1;
end

% Array marking epochs with arousals if they are in eeg1, eeg2 and emg
[inicios, fines] = getEventIndexes(arousalsEegEmg);
for k = 1:length(inicios)
    startSec = inicios(k);
    endSec = fines(k);
    epochNum = calculateEpoch(startSec, endSec, epoch_duration, numEpochs);
    arousalsEpochEegEmg(epochNum) = 1;
end

% Si tenemos al menos 3 epochs seguidos despierto, descartamos arousal
maskAllowed = ones(numEpochs, 1);
% Si empieza despierto, descartamos arousal en todos los epochs
aZero = 0;
for k = 1:3
    if SleepStages.Signal(k) == 0
        aZero = aZero + 1;
    else
        aZero = 0;
    end
end
if aZero == 3
    maskAllowed(1:3) = 0;
end
% A partir de ahi, el primer epoch despierto se permite, el arousal pudo causar
% un cambio de fase en ese epoch
for k = 4:numEpochs
    if SleepStages.Signal(k) == 0
        aZero = aZero +1;
    else
        aZero = 0;
    end
    
    if aZero >= 3
        maskAllowed(k - aZero + 2:k) = 0;
    end
end
arousalsVectorSystem = arousalsEpochEeg .* maskAllowed;

% In REM we require also an EMG event to overlap
remStages = (SleepStages.Signal == 5);
arousalsVectorSystem(remStages) = arousalsVectorSystem(remStages) & ...
    arousalsEpochEegEmg(remStages);

[inicios, fines] = getEventIndexes(arousalsEeg1Eeg2);
countEvents = 0;
outputRU(length(inicios)).eventInEMG = 0;
for k = 1:length(inicios)
    startSec = inicios(k);
    endSec = fines(k);
    epochNum = calculateEpoch(startSec, endSec, epoch_duration, numEpochs);
    
   
    % Ya que puede que EEG1 & EEG2 (vectorOverlap4) no sea suficiente
    % p.ej. para fases REM que requieren EMG event
    if arousalsVectorSystem(epochNum)
        
        countEvents = countEvents + 1;
        start_event_seconds = nan;
        end_event_seconds = 0;
        
        indexEventEEG1 = 0;
        indexEvent1 = find([eeg1ArousalRU.epochNum] == epochNum);
        indexEventEEG2 = 0;
        indexEvent2 = find([eeg2ArousalRU.epochNum] == epochNum);
        
        if isempty(indexEvent1) || isempty(indexEvent2)
            continue;
        end
        
        % Empiezo por EMG
        indexEventEMG = 0;
        if SleepStages.Signal(epochNum) == 5
            indexEvent = find([emgArousalRU.epochNum] == epochNum);
            if isempty(indexEvent)
                outputRU(countEvents).eventInEMG = 0;
            else
                % Si hay mas de uno me quedo con el que mas se aproxime a startSec
                foutput = abs([emgArousalRU(indexEvent).startSecond] - startSec);
                [emgArousalRU(indexEvent).possibleEvent] = deal(1);
                [~, index] = min(foutput);

                indexEventEMG = indexEvent(index);
                outputRU(countEvents).eventInEMG = emgArousalRU(indexEventEMG).possibleEvent; % Legacy (podriamos borrar esto si no evaluamos evento individualmente)
                start_event_seconds = min(start_event_seconds, emgArousalRU(indexEventEMG).startSecond);
                end_event_seconds = max(end_event_seconds, emgArousalRU(indexEventEMG).endSecond);
            end
        end
        outputRU(countEvents).indexEventEMG = indexEventEMG;
        
        %EEG1
        if isempty(indexEvent1)
            outputRU(countEvents).eventInEEG1 = 0;
        else
            % Si hay mas de uno me quedo con el que mas se aproxime a
            % startSec
            foutput = abs([eeg1ArousalRU(indexEvent1).startSecond] - startSec);
            [eeg1ArousalRU(indexEvent1).possibleEvent] = deal(1);

            [~, index] = min(foutput);
            indexEventEEG1 = indexEvent1(index);
            outputRU(countEvents).eventInEEG1 = eeg1ArousalRU(indexEventEEG1).possibleEvent; % Legacy (podriamos borrar esto si no evaluamos evento individualmente)
            start_event_seconds = min(start_event_seconds, eeg1ArousalRU(indexEventEEG1).startSecond);
            end_event_seconds = max(end_event_seconds, eeg1ArousalRU(indexEventEEG1).endSecond);
        end
        outputRU(countEvents).indexEventEEG1 = indexEventEEG1;
        
        %EEG2
        if isempty(indexEvent2)
            outputRU(countEvents).eventInEEG2 = 0;
        else
            % Si hay más de uno me quedo con el que m�s se aproxime a
            % startSec
            foutput = abs([eeg2ArousalRU(indexEvent2).startSecond] - startSec);
            [eeg2ArousalRU(indexEvent2).possibleEvent] = deal(1);
            
            [~, index] = min(foutput);
            indexEventEEG2 = indexEvent2(index);
            outputRU(countEvents).eventInEEG2 = eeg2ArousalRU(indexEventEEG2).possibleEvent; % Legacy (podriamos borrar esto si no evaluamos evento individualmente)
            start_event_seconds = min(start_event_seconds, eeg2ArousalRU(indexEventEEG2).startSecond);
            end_event_seconds = max(end_event_seconds, eeg2ArousalRU(indexEventEEG2).endSecond);
        end
        outputRU(countEvents).indexEventEEG2 = indexEventEEG2;
        
        % Final pattern assigments
        if start_event_seconds > 0
            outputRU(countEvents).startSecond = start_event_seconds;
            outputRU(countEvents).endSecond = end_event_seconds;
        else
%             fprintf('ENTRO AQUI, AROUSAL DESCARTADA...%d', countEvents);
            outputRU(countEvents).startSecond = -1;
            outputRU(countEvents).endSecond = -1;
        end
        outputRU(countEvents).epochNum = epochNum;
        outputRU(countEvents).possibleArousal = 1;
        
        if outputRU(countEvents).indexEventEMG
            event = emgArousalRU(outputRU(countEvents).indexEventEMG);
            emgSignalEvents(event.start:event.end) = 1;
        end

        if outputRU(countEvents).indexEventEEG1
            event = eeg1ArousalRU(outputRU(countEvents).indexEventEEG1);
            eeg1SignalEvents(event.start:event.end) = 1;
        end

        if outputRU(countEvents).indexEventEEG2
            event = eeg2ArousalRU(outputRU(countEvents).indexEventEEG2);
            eeg2SignalEvents(event.start:event.end) = 1;
        end        
    end
end

outputRU(countEvents + 1:end) = [];

function [epochNum] = calculateEpoch(startSec, endSec, epoch_duration, numEpochs)
epochNum = min(floor((startSec + (endSec-startSec) / 2) / epoch_duration) + 1,...
    numEpochs);

function [ru, event] = buildRU(eventDef, signalRate, samplesEpoch, numEpochs)

lengthEvent = length(eventDef);
event = zeros(samplesEpoch * numEpochs, 1, 'int8');

% Preallocate array of structs
ru(lengthEvent).start = 0;

for k = 1:lengthEvent
    % Muestra de inicio
    ru(k).start = eventDef(k, 1);
    % Segundo de inicio
    ru(k).startSecond = eventDef(k, 1) / signalRate;
    % Muestra de fin
    ru(k).end = eventDef(k, 2);
    % Segundo de fin
    ru(k).endSecond = eventDef(k, 2) / signalRate;
    % Duracion del evento (en segundos)
    ru(k).duration = ru(k).endSecond - ru(k).startSecond;
    % Segundo central del evento
    middle_sample = ru(k).start + (ru(k).end - ru(k).start) / 2;
    ru(k).midSecond = middle_sample / signalRate;
    % Epoch en el que se produce el evento
    ru(k).epochNum = min(floor(middle_sample / samplesEpoch) + 1, numEpochs); 
    
    event(ru(k).start:ru(k).end) = 3; 
end