% POSPROCESADO N�6 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A�ade fase REM si las medias son razonables y hay pocos spindles.
function entrada = checkLowEmg(entrada, vectorSp, mediaF0, mediaFSP, mediaFR, vectorREM)
% entrada       El vector resultado inicial
% remList       La lista de bloques REM
% spindlesList  La lista de sleep spindles
% media         El vector con los grados de pertenencia de cada epoch
for j = find(entrada == 5)'
    if j == length(entrada), continue; end
    if entrada(j + 1) ~= 5
        % Iniciamos una comprobaci�n de distintos parametros
        if mediaF0(j + 1) < 0.7 && mediaFSP(j + 1) < 0.5 && ...
                mediaFR(j + 1) >= 0.1 && vectorREM(j + 1) > 0 && ...
                vectorSp(j + 1) < 3
            entrada(j + 1) = 5;
        end
    end
end

