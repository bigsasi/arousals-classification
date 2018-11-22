function [ru, event] = buildReasoningUnit(eventDef, signalRate, signalLength,...
    samplesEpoch)

lengthEvent = size(eventDef, 1);

event = zeros(1, signalLength);

ru = [];

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
    % Epoch en el que se produce el evento
    ru(k).epochNum = ceil(eventDef(k, 1) ./ samplesEpoch); 
    event(ru(k).start:ru(k).end) = 1; 
end