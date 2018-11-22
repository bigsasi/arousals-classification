function [Kcomplexes] = getKComplexList(emgPower, alphaPower, SampleRate,...
    windowStep, windowStepKC, deltaEvents, emgEvents, HwinSize, emgSignalEvents)
% Kcomplexes            La lista con los complejos K detectados
% emgPower              Percent of relative power for emg band
% alphaPower            Percent of relative power for alpha band
% windowStepKC          El salto de ventana (en segundos)
% windowSizeKCSamples   El tama�o de la ventana de complejos K (en samples)
% windowStepKCSamples   El salto de ventana (en samples)
% windowStepRatioKC     

windowStepRatioKC = floor(windowStepKC / windowStep);
windowStepSamples = round(windowStep * SampleRate);

delay = round(HwinSize/2 - windowStepSamples/2);

signal_eventsKC = deltaEvents; % Calculated at getSpindlesList
    
% DISCARDING FALSE POSITIVES
    
% STEP 1: Substract those samples containing EMG amplitude increase
[inicios, fines] = getEventIndexes(emgSignalEvents);
iniciosKC = ceil(inicios * windowStepRatioKC);
finesKC = ceil(fines * windowStepRatioKC);
for k = 1:length(inicios)
    signal_eventsKC(iniciosKC(k):finesKC(k)) = 0;
end  

% STEP 3: Substract those samples containing EMG power percentage >= 15%
signal_eventsKC = signal_eventsKC - int8(emgPower >= 15);

% STEP 4: Substract those samples containing Alpha power percentage >= 15%
signal_eventsKC = signal_eventsKC - int8(alphaPower >= 15);

% Substracting EMG or Alpha where there is no SS event causes values below zero
signal_eventsKC(signal_eventsKC < 0) = 0; 

% Cancel events with duration < 0.5 secs or > 3 secs
minDurationKComplex = ceil(0.5 / windowStep);
maxDurationKComplex = ceil(3 / windowStep);

% Establish K-complex events (discarding those with duration less than 0.5 secs and higher than 3 secs)
inicios = find(diff(signal_eventsKC) == 1) + 1;
fines = find(diff(signal_eventsKC) == -1);
environment = 15; % In seconds
environment = ceil(environment/windowStep); % Translated to windows
if not(isempty(inicios) || isempty(fines))
    % Arreglamos casos donde en la se�al empieza o finaliza en evento
    if (fines(1) < inicios(1))
        signal_eventsKC(1:fines(1)) = 0;
        fines = fines(2:end);
    end
    if (fines(end) < inicios(end))
        signal_eventsKC(inicios(end):end) = 0;
        inicios = inicios(1:end-1);
    end
    longitud = length(emgPower);
    diferencias = fines-inicios+1;
    max_inicios = max(inicios - environment, 1);
    min_fines = min(fines + environment, longitud);
    for k = 1:length(inicios)
        % discarding those with duration less than 0.5 secs and higher than
        % 3 secs
        if (diferencias(k) < minDurationKComplex)
            signal_eventsKC(inicios(k):fines(k)) = 0;
        end
        if (diferencias(k) > maxDurationKComplex)
            signal_eventsKC(inicios(k):fines(k)) = 0;
        end
        % Discarding in the presence of EMG artifacts (total event not just
        % samples as before)
        if (sum(emgEvents(inicios(k):fines(k))) > 0)
            signal_eventsKC(inicios(k):fines(k)) = 0;
        end
        % Discarding in periods of high EMG activity (in an envirment of
        % the possible K-complex)
        if (mean(emgPower(max_inicios(k):min_fines(k))) >= 10)
            signal_eventsKC(inicios(k):fines(k)) = 0;
        end
        % Discarding in periods of high Alpha activity (in an envirment of
        % the possible K-complex)
        if (mean(alphaPower(max_inicios(k):min_fines(k))) >= 15)
            signal_eventsKC(inicios(k):fines(k)) = 0;
        end
    end
end

% Now we return back events indexes
inicios = (find(diff(signal_eventsKC) == 1) + 1);
fines = find(diff(signal_eventsKC) == -1);
diferencias = fines-inicios+1;
Kcomplexes = zeros(length(inicios), 2);
for k = 1:length(inicios)
    inicio = inicios(k)*windowStepSamples + delay;
    duracion = diferencias(k)*windowStepSamples;
    Kcomplexes(k,:) = [inicio inicio+duracion];
end