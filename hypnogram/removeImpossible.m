% POSPROCESADO N�4 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Corregimos el hipnograma eliminando epochs REM que se encuentren en zonas
% imposibles, como por ejemplo en una zona exclusivamente de vigilia en
% donde aparece de repente una epoch REM. Aquellos cambios de fase
% anomalos (tambien F0|F1 -> F3), son descartados. Despues corregimos el 
% hipnograma eliminando epochs REM peque�as y aisladas que no tengan 
% sentido y les damos el valor de -1. Una vez terminado, a todas las epochs
% con -1, recalcularemos su valor teniendo en cuenta solo las fases de 
% sue�o F0, FSL y FSP.
function entrada = removeImpossible(entrada, mediaF0, mediaF1, mediaF2, ...
    mediaFSP, mediaFR, emg_comprometido, vectorREM)
% entrada       El vector resultado inicial
% media         El vector con los grados de pertenencia de cada epoch
% emg_comprometido  Indica si la amplitud del EMG es mas alta de lo normal (fallo de calibracion o exceso de ruido)
count0 = 0;
count1 = 0;
count3 = 0;
numEpochs = length(entrada);
for j=1:numEpochs
    
    % Un pico REM aislado siempre se borra
    if j > 5 && j < numEpochs - 5 && entrada(j) == 5 && ...
            sum(entrada(j - 5:j + 5) == 5) == 1
        entrada(j) = -1;
    end
    
    % Un registro no deberia empezar por REM ni por FSP...
    if j <= 20 && (entrada(j) == 5 || entrada(j) == 3)
        entrada(j) = -1;
    end
    
    % Solo si entra en una epoch de fase de sue�o ligero (F1 o F2) y tiene
    % el grado de F0 demasiado alto.
    if ~emg_comprometido && (entrada(j) == 1 || entrada(j) == 2) && ...
            mediaF0(j) >= 0.7 && vectorREM(j) < 5
        if mediaF1(j) >= 0.3
            entrada(j) = 2;
        elseif mediaF1(j) >= mediaF0(j)
            entrada(j) = 1;
        else
            entrada(j) = 0;
        end
    end
    
    if j < numEpochs && entrada(j) == 0 && entrada(j+1) == 5 && ...
            mediaF0(j + 1) > 0.3 && mediaFR(j + 1) < 0.7 && vectorREM(j + 1) < 5
        entrada(j + 1) = 0;
    end
    
    % En algunas ocasiones se produce un pico de F0 dentro de una FSP, cuando
    % en realidad es FSL.
    if j <= numEpochs - 2 && entrada(j) == 3 && entrada(j + 1) == 0 && ...
            entrada(j + 2) == 3
        entrada(j + 1) = -2;
    elseif j <= numEpochs - 3 && entrada(j) == 3 && entrada(j + 1) == 0 && ...
            entrada(j + 2) == 2 && entrada(j + 3) == 3
        entrada(j + 1:j + 2) = -2;
    end
    if j < numEpochs - 5 && ...
            (entrada(j) == 0 && any(entrada(j + 1:j + 5) == 3)) || ...
            (entrada(j) == 2 && count3)
        if entrada(j + 1) == 3 && (emg_comprometido || mediaF2(j) >= 0.7)
            if mediaF0(j + 1) < 0.9
                entrada(j + 1) = 2;
            else
                entrada(j + 1) = 0;
            end
            count3 = 0;
        elseif entrada(j + 1) == 2
            count3 = 1;
        else
            entrada(j + 1) = 0;
            count3 = 0;
        end
    end
    
    % Cambios de epochs anomalos (bloque F5 delante de zona F0)
    if entrada(j) == 0
        count0 = count0 + 1;
    elseif (entrada(j) == 5 || entrada(j) == -1) && (count0 >= 30)
        entrada(j) = -1;
        count0 = count0 + 1;
    elseif (entrada(j) == 5 || entrada(j) == -1) && (count0 >= 10) && ...
            ~emg_comprometido
        entrada(j) = -1;
        count0 = count0 + 1;
    elseif (entrada(j) == 5 || entrada(j) == -1) && (count0 >= 5) && ...
            ~emg_comprometido
        currentMediaF0 = sum(mediaF0(j - count0:j - 1)) / count0;
        currentMediaF1 = sum(mediaF1(j - count0:j - 1)) / count0;
        if currentMediaF0 > 0.7 && currentMediaF1 < 0.5
            entrada(j) = -1;
            count0 = count0 + 1;
        else
            count0 = 0;
        end
    elseif entrada(j)==1 && count0 >= 5
        count1 = count1 + 1;
    elseif count1 > 5
        count0 = 0;
        count1 = 0;
    elseif count0 > 0
        count0 = 0;
        count1 = 0;
    end
end

for j = find(entrada == -1)'
    entrada(j) = 2;
    [~, pos] = max([mediaF0(j) mediaF1(j) mediaF2(j) mediaFSP(j)]);
    if pos == 1
        entrada(j) = 0;
    end
    if pos == 2 && entrada(j - 1) ~= 2
        entrada(j) = 1;
    end
    if pos == 4 && mediaFSP(j) >= 0.9
        entrada(j) = 3;
    end
end

entrada(entrada == -2) = 2;
