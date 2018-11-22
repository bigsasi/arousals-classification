% Returns seconds from the recording start for the given datetime format
% (EDF header compliant)
function [outSecs] = EDFtime2seconds(EDFstrTime, refTime, numDays)
% EDFstrTime, refTime   HH.MM.SS
% numDays : integer to be used when date from starting and date from
% refTime are different (it adds numDays * secsPerDay to the calculation)
outSecs = -1;

seconds = -1;
if (length(refTime)==8) % Primero comprobamos si el formato de hora coincide
    [horas, resto] = strtok(refTime,'.');
    [minutos, resto] = strtok(resto,'.');
    segundos = strtok(resto,'.');
    if (str2double(minutos)>60)||(str2double(segundos)>60)
        outSecs = -1;
        disp('Error: invalid input date format');
        return;
    else
        seconds = str2double(segundos) + str2double(minutos)*60 + str2double(horas)*3600;
    end
end
if (isempty(seconds))
    disp('Error (refTime): it was not possible to compute the number of seconds');
    outSecs = -1;
    return;
end

secondsEDF = -1;
if (length(EDFstrTime)==8) % Primero comprobamos si el formato de hora coincide
    [horas, resto] = strtok(EDFstrTime,'.');
    [minutos, resto] = strtok(resto,'.');
    segundos = strtok(resto,'.');
    if (str2double(minutos)>60)||(str2double(segundos)>60)
        outSecs = -1;
        disp('Error: invalid input date format');
        return;
    else
        secondsEDF = str2double(segundos) + str2double(minutos)*60 + str2double(horas)*3600;
    end
end
if (isempty(secondsEDF))
    disp('Error (EDFstrTime): it was not possible to compute the number of seconds');
    outSecs = -1;
    return;
end

outSecs = (seconds - secondsEDF) + 24*3600*numDays;

