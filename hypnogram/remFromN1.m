% POSPROCESADO N�7 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% F1 tiene un comportamiento en ocasiones similar a REM, sobre todo en
% actividad cerebral. En el caso de conflicto entre los grados de
% pertenencia de ambos, es probable que se trate de fase REM. Si delante 
% de un bloque REM hay F1, es posible que esas epochs sean en realidad REM. 
% Si est�n lo suficientemente cerca se convierten, salvo que en alg�n 
% procesado anterior se hayan borrado. Contamos a partir del procesado 5, 
% ya que los 4 primeros son procesados b�sicos que no afectan a los bloques
% REM (el tratamiento de los bloques REM empieza a partir del procesado N�5).
function entrada = remFromN1(entrada, mediaF0, mediaF1, mediaF2, ...
    mediaFSP, mediaFR, previousHypnogram, emg_comprometido, anomaliaF0F3)
% entrada           El vector resultado inicial
% media             El vector con los grados de pertenencia de cada epoch
% procesados        Todos los anteriores cambios realizados sobre el hipnograma
% emg_comprometido  Indica si la amplitud del EMG es mas alta de lo normal (fallo de calibracion o exceso de ruido)
% anomaliaF0F3      Indica si existen valores raramente altos para F3 en zonas con actividad cerebral de alta frecencia
numEpochs = length(entrada);
count = 0;
for j = numEpochs:-1:3
    if entrada(j) == 5 && entrada(j - 1) == 1 && mediaFR(j - 1) >= 0.1
        entrada(j - 1) = 5;
    elseif entrada(j) == 5 && entrada(j - 1)==0 && (entrada(j - 2) == 1 || entrada(j - 2) == 2)
        entrada(j-1) = 5;
    elseif (entrada(j) == 5 && entrada(j - 1) == 2) || (count > 0 && entrada(j - 1) == 2)
        count = count + 1;
    elseif entrada(j) == 2 && mediaF2(j) < 0.9 && count > 0 && count <= 3 
        if (entrada(j - 1) == 1 || entrada(j - 1) == 5) && ~any(previousHypnogram(:, j - 1) == 5)
            entrada(j - 1:j + count) = 5;
            count = 0;
        elseif entrada(j - 1) == 0 && mediaF0(j - 1) > 0.7 && mediaF1(j - 1) > 0.7 && mediaF2(j - 1) > 0.7 && mediaFR(j - 1) > 0.2
            entrada(j - 1:j + count) = 5;
            count = 1;
        end
    elseif count > 0
        count = 0;
    end
end

count = 0;
for j = 2:numEpochs - 1
    % F5-F1
    if ~emg_comprometido
        if entrada(j) == 5 && entrada(j + 1) == 1
            entrada(j + 1) = 5;
        elseif entrada(j - 1) == 5 && entrada(j) == 0 && entrada(j + 1) == 1
            entrada(j + 1) = 5;
        elseif entrada(j) == 5 && entrada(j + 1) == 2
            count = 1;
        elseif count > 0 && count <= 5 
            if entrada(j + 1) == 2
                count = count + 1;
            elseif entrada(j + 1) == 0 && ~any(any(previousHypnogram(:, j - count + 1:j) == 5) == 1)
                entrada(j - count:j) = 5;
                count = 0;
            end
        elseif count > 0
            count = 0;
        end
    end
    if ~anomaliaF0F3
        % F3-F5. Casos muy poco comunes, retocamos si vemos que el grado de
        % pertenencia de F3 y F5 son ambos demasiado altos.  
        if entrada(j) == 3 && entrada(j + 1) == 5 
            if mediaFSP(j + 1) < 0.5
                entrada(j + 1) = -1;
            else
                entrada(j + 1) = 3;
            end
        elseif entrada(j) == -1 && entrada(j + 1) == 5
            if mediaFR(j + 1) < 0.5 && mediaF2(j + 1) >= 0.7
                entrada(j + 1) = -1;
            elseif any(mediaF2(j + 1:j + 3) >= 0.9) && mediaFSP(j + 1) > 0.1
                entrada(j + 1) = -1;
            end
        end
    end
end
entrada(entrada == -1) = 2;

