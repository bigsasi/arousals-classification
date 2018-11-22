
% POSPROCESADO N�1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Usamos vectorREM para indicar que grupos de fase REM hay que corregir. Si
% vectorREM tiene valores altos, se convierten esas epochs a REM. Cuanto
% m�s alto sea vectorREM, m�s picos de fase REM hay cerca.
function entrada = mergeRemBlocks(entrada, vectorREM)
% entrada       El vector resultado inicial
% vectorREM     El vector de picos REM
% salida        El vector resultado final
count = 0;
inicio = 0;
numEpochs = length(entrada);
for j=1:numEpochs
    % Entramos en zona REM e iniciamos el proceso
    if ~inicio && vectorREM(j) > 1
        inicio = 1;         
    end
    if inicio && vectorREM(j) > 1
        count = count + 1;
    elseif count > 0 && vectorREM(j) <= 1
        if j - count > 1 && any(entrada(j - count - 1:j) == 5) && any(vectorREM(j - count - 1:j) > 2)
            entrada(j - count:j - 1) = 5;
        end
        count = 0;
        inicio = 0;
    end
end
