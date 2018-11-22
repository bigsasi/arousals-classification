% POSPROCESADO DE SLEEPSPINDLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% En funci�n de los sleepspindles se realizan unos pocos posprocesados. Es
% necesario que haya un numero minimo de spindles, porque de lo contrario
% no ser�n relevantes. Si un paciente es muy viejo apenas tendr� spindles y
% este posprocesado no se aplicar�.
function [entrada, emg_comprometido] = ...
    doSpindles(entrada, remList, spindlesList, vectorSp, mediaF0, ...
    mediaF1, mediaF2, mediaFSP, mediaFR, mediaEMG, mediaEOGM)
% entrada           El vector resultado inicial
% remList           La lista de bloques REM
% spindlesList      La lista de sleep spindles
% vectorREM         El vector de picos REM
% media             El vector con los grados de pertenencia de cada epoch
% mediaEMG          El vector con el valor de amplitud del EMG para cada epoch
% emg_comprometido  Indica si la amplitud del EMG es mas alta de lo normal (fallo de calibracion o exceso de ruido)
numEpochs = length(entrada);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculamos la media y la desviacion tipica del EMG para las fases 
% que hemos supuesto que son sue�o ligero. Si se sale de los valores 
% normales (-0.7 de amplitud en F2 es bastante alto...), entonces 
% descartamos el EMG y los grados de pertenencia y calculamos F2 en funci�n
% de los spindles.
% Mantenemos una variable en el caso de que tengamos un registro con 
% problemas de calibraci�n en el EMG. Se comprobar� en los siguientes 
% procesado y se aplicar�n o no en funci�n de esta variable.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
emg_comprometido = 0;
% eog_comprometido = 0;
mediaEMGFSL = mean(mediaEMG(entrada == 1 | entrada == 2));
if mediaEMGFSL > -0.7
    fprintf('AVISO, DETECTADO EMG DEMASIADO ALTO. POSIBLES ERRORES EN EL ANALISIS\n');
    emg_comprometido = 1;
    for j=3:numEpochs - 3
        if (entrada(j) == 0 || entrada(j) == 1) && mediaF0(j) <= 0.9
            if spindlesList(j) >= 0.5 || (mediaF0(j) < 0.8 && sum(spindlesList(j - 2:j + 2)) >= 0.5)
                entrada(j) = 2;
            elseif vectorSp(j) >= 10 || (vectorSp(j) > 0 && mediaF2(j) >= 0.1) 
                entrada(j) = 2;
            end
        elseif entrada(j) == 0 && mediaF0(j) < 0.5
            entrada(j) = 2;
        end
    end
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Comprobamos el valor del EOG durante todo el registro. Si tenemos 
%  valores an�malos (un eog demasiado alto), entonces el an�lisis es 
%  probable que sea incorrecto debido a una mala calibraci�n del EOG, o 
%  alg�n problema con el paciente. En ese caso, los grados de pertenencia 
%  calculados ser�n incorrectos y se corrigen con otros procesados.
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (sum(entrada == 2) / numEpochs <= 0.1) && mean(mediaEOGM) >= 0 && ~emg_comprometido
%     fprintf('AVISO, DETECTADO EOG DEMASIADO ALTO. POSIBLES ERRORES EN EL ANALISIS\n');
%     eog_comprometido = 1;
    entrada(mediaFR < 0.5) = 0;
    entrada(~(mediaFR < 0.5)) = 2;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ahora analizamos todos los bloques REM detectados. Para cada bloque 
% comprobamos la media de spindles/epoch, si es superior a 0.5 suponemos 
% que se trata de un falso positivo; si no, miramos el vectorSp para ver si 
% presenta un valor mayor de 10, de ser as� suponemos que dentro de ese 
% bloque hay trozos que puede que no sean REM (puede ser que tenga que 
% empezar m�s tarde, terminar antes, o que dentro del bloque haya un tramo 
% de F2).
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for j = 1:size(remList, 1)
    rango = remList(j, 1):remList(j, 2);
    if isempty(rango)
        continue
    end
    maxSp = max(vectorSp(rango));
    minSp = min(vectorSp(rango));
    if (remList(j, 7) >= 10 || remList(j, 4) >= 0.5) && remList(j, 3) > 0
        entrada(rango) = -1;
    elseif minSp < 5 && maxSp >= 10 && ...
            sum(entrada(max(1, remList(j, 1) - 10):max(1, remList(j, 1) - 1)) == 0) < 5
        entrada(rango((vectorSp(rango) > 5 & mediaFR(rango) < 0.5 & mediaF2(rango) > 0.5) | vectorSp(rango) >= 10)) = -1;
    elseif maxSp > minSp * 2
        entrada(rango((vectorSp(rango) > 5 & mediaFR(rango) < 0.5 & mediaF2(rango) > 0.5) | vectorSp(rango) >= 10)) = -1;
    elseif remList(j, 4) >= 0.4 && any(spindlesList(rango) == 1)
        entrada(rango) = -1;
    elseif remList(j, 4) >= 0.3 && remList(j, 7) >= 5 && mean(remList(:, 7)) <= 3
        entrada(rango) = -1;
    end
end
    
for j = find(entrada == -1)'
    entrada(j) = 2;
    [~, pos] = max([mediaF0(j) mediaF1(j) mediaF2(j) mediaFSP(j)]);
    if pos == 1 && ~emg_comprometido
        entrada(j) = 0;
    end
    if pos == 2 && entrada(j - 1) ~= 2 && vectorSp(j) == 0
        entrada(j) = 1;
    end
    if pos == 4 && mediaFSP(j) >= 0.9
        entrada(j) = 3;
    end
end
