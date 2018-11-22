% POSPROCESADO DE F1-F2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Retoca los cambios de fase entre F0-F1-F2.
function entrada = drowsySleepTransitions(entrada, mediaF0, mediaF1, mediaF2, ...
    mediaFSP, mediaFR, emg_comprometido, useSpindles, spindlesList, ...
    vectorSp, mediaEMG)
% entrada       El vector resultado inicial
% media         El vector con los grados de pertenencia de cada epoch
% spindlesList  La lista de sleep spindles
% emg_comprometido  Indica si la amplitud del EMG es mas alta de lo normal (fallo de calibracion o exceso de ruido)
numEpochs = length(entrada);
count = 0;

% Retocamos cambios de fase F0-F2. Si el grado de F0 es alto, se retrasa el
% cambio de fase, si tiene un grado de F1 alto, se pasa a F0-F1. Si no
% cumple ninguna de estas condiciones se deja como est�.
if ~emg_comprometido
    for j = 1:numEpochs - 2
        if entrada(j + 1) ~= 2
            continue
        end
        if entrada(j) == 0 && mediaF0(j + 1) > 0.4 && mediaF1(j + 1) < 0.2 && mediaF2(j + 1) < 0.7
            entrada(j + 1) = 0;
        elseif mediaF2(j) >= mediaF2(j + 1) + 0.5 && mediaF0(j + 1) >= 0.3
            entrada(j + 1) = 0;
        elseif entrada(j) == 0 && entrada(j + 2) == 0
            if mediaF1(j + 1) > 0.7
                entrada(j + 1) = 1;
            else
                entrada(j + 1) = 0;
            end
        end
    end
end

for j = 1:numEpochs - 1
    % Si hay spindles suficientes podemos descartar cambios de fase.
    if useSpindles
        if entrada(j) == 1 && entrada(j + 1) == 2 && mediaF1(j + 1) > 0.2 && spindlesList(j + 1) < 0.5 && mediaF2(j + 1) < 0.9
            entrada(j + 1) = 1;
        end
    end
    if (entrada(j) == 1 || entrada(j) == 2) && mediaF0(j) > 0.7 && mediaF1(j) < 0.7 && mediaF2(j) < 0.7 && ~emg_comprometido && entrada(j + 1) == 0
        entrada(j) = 0;
    end
    % Cambios de fase F0-F2 cuando no se encuentran en zonas de cambios intermitentes 
    if entrada(j) == 0 && entrada(j + 1) == 0
        count = count + 1;
    elseif entrada(j) == 0 && entrada(j + 1) == 2 && (mediaF1(j + 1) > 0.2 || mediaFR(j + 1) > 0.5) && count >= 2
        entrada(j + 1) = 1;
    elseif entrada(j) == 1 && entrada(j + 1) == 2 && count >= 2 && mediaF1(j + 1) > 0.5
        entrada(j + 1) = 1;
    else
        count = 0;
    end
end

% Retocamos los cambios de fase F0-F2. Si el grado de F1 es lo
% suficientemente alto, se convierte a F0-F1.
for j = 1:numEpochs - 1
    if entrada(j) == 0 && entrada(j + 1) == 2 
        if mediaF1(j + 1) >= 0.5 && mediaF0(j + 1) < mediaF2(j + 1) && mediaF1(j) < 0.9
            entrada(j + 1) = 1;
        elseif mediaF2(j + 1) < 0.7 && mediaF1(j + 1) > 0.2
            entrada(j + 1) = 1;
        end
    elseif entrada(j) == 1 && entrada(j + 1) == 2 
        if mediaF0(j + 1) >= 0.3 && mediaF1(j + 1) >= 0.5
            entrada(j + 1) = 1;
        elseif mediaF2(j + 1) < 0.7 && mediaF1(j + 1) > 0.2
            entrada(j + 1) = 1;
        end
    end
end

% Aquellas epochs F0 que tengan un grado medio, que est�n en una zona
% con bastantes spindles, que el emg est� relajado y que haya al menos
% uno o varios grados de pertenencia altos.
entrada(entrada == 0 & mediaF0 <= 0.7 & vectorSp >= 5 & mediaEMG <= -0.8 & ...
    (mediaF1 > 0.5 | mediaF2 > 0.5 | mediaFSP > 0.5 | mediaFR > 0.5)) = 2;
    
if ~emg_comprometido
    for j=1:numEpochs-1
        if entrada(j) == 0 && (entrada(j + 1) == 1 || entrada(j + 1) == 2) && ...
                mediaF0(j + 1) >= 0.5 && mediaF1(j + 1) <= 0.7
            if entrada(j + 1) == 2 && mediaF2(j + 1) <= 0.7 && mediaF1(j + 1) >= 0.3
                entrada(j + 1) = 1;
            else
                entrada(j + 1) = 0;
            end
        end
    end
end

% En el caso de que tengamos un bloque de F1 de longitud mayor de 10
% epochs, es decir, m�s de 5 minutos (la regla de los 3 minutos aplicada
% por muchos m�dicos afirma que el tiempo m�ximo de F1 sin spindles ni 
% complejos k visibles es de 3 minutos) se cambia a F2 directamente.
count = 0;
for j = 1:numEpochs
    if entrada(j) == 1 && count==0
        count = 1;
    elseif entrada(j) == 1 && count >= 1
        count = count + 1;
    elseif entrada(j) ~= 1 && count > 8
        for k = j - count:j
            if entrada(k) == 1 && (spindlesList(k) > 0.5 || vectorSp(k) >= 5 || mediaF2(k) >= mediaF1(k) + 0.25) && mediaF2(k) > mediaF1(k)
                entrada(k) = 2;
            elseif entrada(k) == 1 && entrada(k - 1) == 2
                entrada(k) = 2;
            end
        end
        count = 0;
    elseif entrada(j) ~= 1 && count > 0 && count <= 8
        count = 0;
    end
end

% Existen registros especiales con valores para la vigilia muy bajos. En
% este caso se retocan aumentando F0.
if mean(mediaF0(entrada ~= 0)) <= 0.05
    % La media de F0 es demasiado baja, lo que puede provocar demasiados
    % FNs para la vigilia.
    for j = 1:numEpochs - 1
        if entrada(j) ~= 0 && mediaF0(j) >= 0.5 
            entrada(j) = 0;
        elseif entrada(j) == 2 && (mediaF0(j) >= mediaF2(j) || mediaF0(j) >= 0.3)
            if mediaF1(j) >= 0.5
                entrada(j) = 1;
            else
                entrada(j) = 0;
            end
        elseif entrada(j) == 0 && mediaF0(j + 1) >= 0.3
            if entrada(j + 1) == 1 || entrada(j + 1) == 2
                entrada(j+1) = 0;
            end
        end
    end
end
    
% Despu�s de F2 no es normal volver directamente a F1
for j = 1:numEpochs - 1
    if entrada(j) == 2 && entrada(j + 1) == 1
        entrada(j + 1) = 2;
    end
end
