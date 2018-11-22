% PROCESADO BLANCO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Caso ESPECIAL. Si en una zona, TODOS los GRADOS DE PERTENENCIA son BAJOS,
% es posible que estemos ante una zona REM dificil de detectar (pocos picos
% REM en el oculograma). Analizamos los grados de pertenencia, teniendo 
% casos especiales, los grados de F1 tienden m�s a REM. Las zonas de F1 con
% F0 son falsos positivos.
function entrada = remWithoutMovements(entrada, mediaF0, mediaF1, mediaF2, ...
    mediaFSP, mediaFR, vectorREM)
% entrada       El vector entrada inicial
% media         El vector con los grados de pertenencia de cada epoch
% vectorREM     El vector que indica la presencia de zonas REM

% 1� localizamos las epochs con m�s probabilidad de ser fase REM
entrada(entrada == 2 & mediaF0 < 0.1 & mediaF1 >= 0.3 & ...
    mediaF2 < 0.9 & mediaFSP < 0.1 & mediaFR > 0.2) = 5;
entrada(entrada == 2 & vectorREM > 0) = 5;
numEpochs = length(entrada);
% Y construimos los bloques REM a partir de esas epochs...hacia adelante
for j = 1:numEpochs - 2
    if entrada(j) == 5 && entrada(j+1) ~= 5
        if mediaF0(j + 1) < 0.5 && mediaF1(j + 1) < 0.7 && mediaFSP(j + 1) < 0.5 && mediaFR(j + 1) >= 0.2
            entrada(j + 1) = 5;
        end
    end
end
% ...y hacia atr�s
for j = numEpochs:-1:3
    if entrada(j) == 5 && entrada(j - 1) ~= 5
        if mediaF0(j - 1) < 0.5 && mediaF1(j - 1) < 0.7 && mediaFSP(j - 1) < 0.5 && mediaFR(j - 1) >= 0.2
            entrada(j - 1) = 5;
        end
    end
end
