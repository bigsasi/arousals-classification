% POSPROCESADO N�3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Se retocan algunos casos. En primer lugar, se borran fases REM si el EMG
% es demasiado alto. Para determinar esto, calculamos la media del EMG en
% las fases de sue�o ligero (F1 y F2), si esa media supera -0.7, estamos
% ante un registro con el emg bastante alto y aquellas epochs F5 que cumplen
% determinadas condiciones, se cambian. Si el EMG es menor, entonces
% comprobamos algunos m�s par�metros.
% El segundo procesado que aplicamos tiene que ver con los registros que
% presentan grados de F3 altos en zonas claramente de vigilia (F0). En este
% caso estamos antes un registo con anomal�as en el EOG y EMG (la �nica
% explicaci�n para que haya coincidencias entre F0 y F3, el EEG son
% totalmente diferentes).
function [entrada, anomaliaF0F3] = removeFalseRem(entrada, useSpindles, ...
    vectorREM, vectorSp, mediaF0, mediaF1, mediaFSP, mediaFR, mediaEMG)
% entrada       El vector resultado inicial
% vectorREM     El vector de picos REM
% media         El vector con los grados de pertenencia de cada epoch
% salida        El vector resultado final
mediaEMGFSL = mean(mediaEMG(entrada == 1 | entrada == 2));
if mediaEMGFSL <= -0.7
    % Caso normal. Se retoca muy poco.
    selection = entrada == 5 & vectorREM < 5 & mediaF0 >= 0.7 & mediaFR < 0.5;
    entrada(selection & mediaF1 + 0.2 > mediaF0) = 1;
    entrada(selection & mediaF1 + 0.2 <= mediaF0) = 0;
else
    % Caso anomalo. Se cambia toda la rem con EMG alto.
    entrada(entrada == 5 & vectorREM <= 3 & ...
        (mediaEMG > -0.7 | mediaF0 > 0.7)) = 0;
end

% Anomalias entre F0 y F3.
mediaF3Alta = mean(mediaFSP(entrada == 0 & mediaF0 >= 0.7)) >= 0.04;
if mediaF3Alta && useSpindles
    anomaliaF0F3 = 1;
    % Damos mayor fuerza al grado de pertenencia de F0. Si hay indicios 
    % de fase REM
    entrada(mediaF0 >= 0.5 & vectorREM < 5) = 0;
    entrada(entrada == 3 & vectorREM > 0) = 5;
    % Ahora retocamos cambios de fase. Recorremos el hipnograma hacia
    % adelante retocando el final de fase REM.
    for j = 1:length(entrada) - 1
        if entrada(j) == 0 && entrada(j + 1) == 3
            entrada(j + 1) = 2;
        elseif entrada(j) == 5 && entrada(j + 1) == 2 && vectorSp(j + 1) == 0
            entrada(j + 1) = 5;
        end
    end
    % Ahora retocamos cambios de fase. Recorremos el hipnograma hacia
    % atras, retocando el principio de fase REM.
    for j = length(entrada):-1:2
        if entrada(j) == 5 && entrada(j - 1) == 2 && ...
                ((useSpindles && vectorSp(j - 1) == 0) || ...
                (~useSpindles && mediaF1(j - 1) <= 0.5) || ...
                vectorREM(j - 1) > 0)
            entrada(j - 1) = 5;
        end
    end
else
    anomaliaF0F3 = 0;
end
