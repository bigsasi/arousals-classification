% Esta funcion recoge informacion sobre todos los bloques REM que hay en el
% hipnograma. Da igual el tama�o del bloque.
function remList = buildRemList(entrada, mediaEMG, spindlesList, vectorSp, useSpindles, unir)
% entrada           El vector resultado
% epoch             El tama�o de la epoch
% spindlesList      El listado de spleep spindles
% useSpindles  Booleano que indica si hay suficientes spindles
% parametroEMG      Estructura con informaci�n (EOG, EMG y EEG)
% unir              Si se tiene en cuenta la proximidad entre bloques REM
k=1;
bloqueREM = 0;
tam = length(entrada);
remList = zeros(tam, 7);
% columna 1 = Inicio
% columna 2 = Fin
% columna 3 = Tama�o
% columna 4 = Media de sleep spindles por bloque
% columna 5 = Media de la amplitud del EMG por bloque
% columna 6 = Si ha sido borrado
% columna 7 = Media del vectorSp por bloque
for j=1:tam
    if ~bloqueREM && entrada(j) == 5
        % Inicio del bloque REM
        remList(k,1) = j;                   
        bloqueREM = 1;
    elseif bloqueREM && (entrada(j)~=5 || j==tam)
        % Fin del bloque REM
        inicioBloque = remList(k, 1);
        remList(k,2) = j - 1;                
        remList(k,3) = j - inicioBloque - 1;  
        if useSpindles
            remList(k, 4) = mean(spindlesList(inicioBloque:j - 1));
            remList(k, 7) = mean(vectorSp(inicioBloque:j - 1));
        end
        remList(k,5) = mean(mediaEMG(inicioBloque:j - 1));
        bloqueREM = 0;
        k = k + 1;
    end
end
remList(k:end, :) = [];

remList2 = zeros(size(remList, 1), 7);
if ~isempty(remList) && unir
    k = 1;
    count = 0;
    for j=1:size(remList, 1)
        if count == 0 && (j == size(remList,1) || remList(j,2) + 3 < remList(j+1, 1))
            % �ltimo bloque o no se solapa con el siguiente
            remList2(k, :) = remList(j,:);    
            k = k + 1;
        elseif j < size(remList, 1) && remList(j, 2) + 3 >= remList(j + 1, 1)
            count = count + 1;
        elseif count > 0
            remList2(k, 1) = remList(j - count, 1);
            remList2(k, 2) = remList(j, 2);
            remList2(k, 3) = remList2(k, 2) - remList2(k, 1);
            remList2(k, 4) = mean(remList(j - count:j, 4));
            remList2(k, 5) = mean(remList(j - count:j, 5));
            remList2(k, 6) = 0;
            remList2(k, 7) = mean(vectorSp(remList2(k, 1):remList2(k, 2)));
            k = k + 1;
            count = 0;
        end
    end
    remList = remList2(1:k - 1, :);
end
