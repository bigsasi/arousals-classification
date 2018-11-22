% POSPROCESADO N�5 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Borramos los bloques REM cuyos valores de EMG sean superiores a la media
% y los bloques REM que sean peque�os (menos de 3 epochs de duracion.
function entrada = removeShortRemPeriods(entrada, remList, mediaF0, mediaF1, ...
    mediaF2, mediaFSP, mediaFR)
% entrada       El vector resultado inicial
% remList       La lista de bloques REM
% media         El vector con los grados de pertenencia de cada epoch
media_emg = mean(remList(:, 5));
mediaGeneral = mean(remList(:, 7));
desviGeneral = std(remList(:, 7));

if mediaGeneral >= 1 || desviGeneral >= 1
    
    if mediaGeneral < 3 && desviGeneral < 3 && mediaGeneral > 1
        limiteSpindles = mediaGeneral;
    elseif mediaGeneral < 3 && desviGeneral < 3 && desviGeneral > 1
        limiteSpindles = mediaGeneral + desviGeneral;
    else
        limiteSpindles = 10;
    end
    
    for j = 1:size(remList,1)
        rango = remList(j,1):remList(j,2);
        currentMediaF5 = mean(mediaFR(rango));

        % Comprobamos los valores de media de REM
        if remList(j, 7) > limiteSpindles && currentMediaF5 < 0.5
            entrada(rango) = -1;
        end

        % Comprobamos los valores del emg
        if media_emg + 0.1 <= remList(j, 5) && mean(mediaF0(rango)) > 0.5
            entrada(rango) = -1;
            remList(j, 6) = 1;
        elseif j > 1 && j < size(remList, 1) && remList(j, 3) <= 2 && ...
                remList(j - 1, 2) + 3 < remList(j, 1) && ...
                remList(j + 1, 1) - 3 > remList(j, 2)
            entrada(rango) = -1;
            remList(j, 6) = 1;
        end
        
    end
    % Por �ltimo cogemos los -1 y los convertimos
    for j = find(entrada == -1)'
        [~, pos] = max([mediaF0(j) mediaF1(j) mediaF2(j) mediaFSP(j)]);     % Calculamos el maximo     
        entrada(j) = pos - 1;
    end
end

