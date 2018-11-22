function [spindlesDef] = getSpindlesList(spindlePower, emgPower, alphaPower, ...
    spindleEvents, emgEvents, alphaEvents, winSamples, windowStep, windowStepSamples)

% spindlesList      La lista con los spindles detectados (inicio-fin)
% eegPower          Percent of relative power for each band for EEG: 
%   1. eegSpindlePower 
%   2. eegEMGPower 
%   3. eegAlphaPower 
%   4. eegDeltaPower 
%   5. eegThetaPower 
%   6. eegBetaPower
% spindleEvents     Lista con eventos marcados si spindle power > threshold
% emgEvents         Lista con eventos marcados si emg power > threshold
% alphaEvents       Lista con eventos marcados si alpha power > threshold
% windowStep        El salto de ventana (en segundos)

% Cancel events with duration < 0.5 secs
minDurationSpindle = ceil(0.5 / windowStep);    
% Calculation of time delay due to effects of windowing
delay = round((winSamples - windowStepSamples) / 2); % In samples

% Discard Sleep Spindles events with duration less than 0.5 seconds
starts = find(diff(spindleEvents) == 1) + 1;
ends = find(diff(spindleEvents) == -1);
if ends(end) < starts(end)
    starts = starts(1:end - 1);
end
for k = 1:length(starts)
    if length(starts(k):ends(k)) < minDurationSpindle
        spindleEvents(starts(k):ends(k)) = 0;
    end
end

% DISCARD FALSE POSITIVE SS EVENTS BY DETECTED EMG ARTIFACT EVENTS

% STEP 1: Substract those samples containing EMG event
finalSpindleEvents = spindleEvents - emgEvents;
% STEP 2: Substract those samples containing Alpha event
finalSpindleEvents = finalSpindleEvents - alphaEvents;
% STEP 3: Substract those samples containing EMG power percentage higher than SS power percentage
finalSpindleEvents = finalSpindleEvents - int8(spindlePower <= emgPower);
% STEP 4: Substract those samples containing Alpha power percentage higher than SS power percentage
finalSpindleEvents = finalSpindleEvents - int8(spindlePower <= alphaPower);
% Substracting EMG or Alpha where there is no SS event causes values below zero
finalSpindleEvents(finalSpindleEvents < 0) = 0;


% STEP 5: re-compute spindles with 0.5 time restriction
environment = 30; % In seconds
environment = ceil(environment/windowStep); % Translated to windows
inicios = find(diff(finalSpindleEvents) == 1) + 1;
fines = find(diff(finalSpindleEvents) == -1);
if not(isempty(inicios) || isempty(fines))
    % Arreglamos casos donde en la se�al empieza o finaliza en evento
    if (fines(1) < inicios(1))
        finalSpindleEvents(1:fines(1)) = 0;
        fines = fines(2:end);
    end
    if (fines(end) < inicios(end))
        finalSpindleEvents(inicios(end):end) = 0;
        inicios = inicios(1:end-1);
    end
    % Para reducir el tiempo computacional, establecemos constantes fuera
    % del bucle
    longitud = length(emgPower);
    for k = 1:length(inicios)
        if (length(inicios(k):fines(k)) < minDurationSpindle)
            finalSpindleEvents(inicios(k):fines(k)) = 0;
        end
        % Discarding in periods of high EMG activity (in an envirment of
        % the possible SS)
        if (mean(emgPower(max(inicios(k) - environment/2,1):min(fines(k) + environment/2, longitud))) >= 10)
            finalSpindleEvents(inicios(k):fines(k)) = 0;
        end
        % Discarding in periods of high Alpha activity (in an envirment of
        % the possible SS)
        if (mean(alphaPower(max(inicios(k) - environment/2,1):min(fines(k) + environment/2, longitud))) >= 15)
            finalSpindleEvents(inicios(k):fines(k)) = 0;
        end
    end
end

% Now we return back events indexes
inicios = find(diff(finalSpindleEvents) == 1) + 1;
fines = find(diff(finalSpindleEvents) == -1);
diferencias = fines-inicios+1;
spindlesDef = zeros(length(inicios), 2);
for k = 1:length(inicios)
    inicio = inicios(k) * windowStepSamples + delay;
    inicio = round(inicio);
    duracion = diferencias(k) * windowStepSamples;
    duracion = round(duracion);
    spindlesDef(k,:) = [inicio inicio+duracion];
end