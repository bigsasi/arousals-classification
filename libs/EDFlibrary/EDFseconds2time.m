% Returns datetime string corresponding to the number of seconds passed as argument from the beginning of the recording
% (EDF header compliant)
function [strTime] = EDFseconds2time(seconds, tipo)
% seconds   Los segundos
% tipo      Si es 1, se muestran en formato HH:MM:SS

disp('TODO');
return;

for i=1:length(seconds)
    minutes = floor(seconds(i)/60);
    hours = floor(minutes/60);
    % Nota: suponemos que no hay más de 24 horas de registro...
    decimas_ = 0;
    seconds_ = mod(seconds(i), 60);
    if seconds_~=round(seconds_)
        decimas_ = uint8((seconds_ - floor(seconds_))*100);
        seconds_ = uint8(floor(seconds_));
    end
    minutes_ = uint8(mod(minutes, 60));
    hours_ = uint8(mod(hours, 24));
    if tipo==0
        strTime(i,:) = sprintf('%02d:%02d:%02d', hours_, minutes_, seconds_);
    else
        strTime(i,:) = sprintf('%02d:%02d:%02d,%02d', hours_, minutes_, seconds_, decimas_);
    end
end

