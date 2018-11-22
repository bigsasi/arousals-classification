% Esta funcion se encargar de aplicar todos los procesados que se realicen
% al vector final
function [hypnogram] = aplicarProcesados(grade, ...
                                         emgAmplitude, ...
                                         eogAmplitude, ...
                                         useSpindles, ...
                                         spindlesList)
% grade        fuzzy values for each epoch
% useSpindles  apply spindles processes
% spindlesList list of sleep spindles
% hypnogram    final hypnogram

epochDuration = grade.Samples_epoch;
numEpochs = floor(length(grade.F0) / epochDuration);


% LO PRIMERO ES CONSTRUIR VECTORES QUE A�ADAN INFORMACION A LOS GRADOS DE
% PERTENENCIA. ESTOS VECTORES HACEN REFERENCIA A EVENTOS TALES COMO SLEEP
% SPINDLES, COMPLEJOS K, MOVIMIENTOS REM...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Obtenemos los PICOS DE REM (segundos con mas de 0.8 de grado de
% pertenencia. Damos mucha mayor importancia al modulo REM al estar basado
% en eventos de movimiento ocular REM.
highREM = zeros(numEpochs, 1);
epochREM = floor(find(grade.FR > 0.8) / epochDuration) + 1;
if ~isempty(epochREM)
    epochREMConfirm = [epochREM(1); 1];
    last = 1;
    for j=2:length(epochREM)
        if epochREM(j) ~= epochREMConfirm(1, end)
            epochREMConfirm(:, last + 1) = [epochREM(j); 1];
            last = last + 1;
        else
            epochREMConfirm(2, last) = epochREMConfirm(2, last) + 1;
        end
    end
    lim = 5;    % El limite establecido para a�adir puntos
    for j = 1:size(epochREMConfirm, 2)
        if epochREMConfirm(2, j) > 10
            %Si en la epoch hay mas de 25 picos, es una epoch muy clara, le
            %damos un peso de 2, si solo tiene mas de 10 le damos 1.
            suma = 1;
            if epochREMConfirm(2,j) > 25, suma = suma + 1; end

            epoch = epochREMConfirm(1, j);
            if epoch <= lim
                highREM(1:epoch + lim) = highREM(1:epoch + lim) + suma;
            elseif numEpochs - epoch <= lim
                highREM(epoch - lim:end) = highREM(epoch - lim:end) + suma;
            else
                highREM(epoch - lim:epoch + lim) = highREM(epoch - lim:epoch + lim) + suma;
            end
        end
    end
end

% De un modo an�logo al anterior, construimos un vector con los sleep 
% spindles. Consideramos un valor importante si la media de spindle es 
% superior a 0.7.
highSpindle = zeros(numEpochs, 1);
lim = 5;    % El limite establecido para a�adir puntos
for j=1:numEpochs
    suma = 0;
    if spindlesList(j) >= 0.3, suma = suma + 1; end
    if spindlesList(j) >= 0.7, suma = suma + 1; end

    if j - lim >= 1 && j + lim <= numEpochs
        highSpindle(j - lim:j + lim) = highSpindle(j - lim:j + lim) + suma;
    end
end


% CONSTRUIMOS EL 1� HIPNOGRAMA EN FUNCION UNICAMENTE DE LOS GRADOS DE PERT.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hypnogram = zeros(numEpochs, 1);
avgEMG = zeros(numEpochs, 1);
avgEOG = zeros(numEpochs, 1);
% avgDelta = zeros(numEpochs, 1);
avgF0 = zeros(numEpochs, 1);
avgF1 = zeros(numEpochs, 1);
avgF2 = zeros(numEpochs, 1);
avgFSP = zeros(numEpochs, 1);
avgFR = zeros(numEpochs, 1);

for j = 1:numEpochs
    is = 1 + epochDuration * (j - 1);
    es = j * epochDuration;
    avgEMG(j) = sum(emgAmplitude(is:es));    % EMG
    avgEOG(j) = sum(eogAmplitude(is:es));    % EOG media
    avgF0(j) = sum(grade.F0(is:es));         % Fase 0
    avgF1(j) = sum(grade.F1(is:es));         % Fase 1
    avgF2(j) = sum(grade.F2(is:es));         % Fase 2
    avgFSP(j) = sum(grade.FSP(is:es));       % Fase Sue�o Profundo
    avgFR(j) = sum(grade.FR(is:es));         % Fase REM
end

avgEMG = avgEMG / epochDuration;
avgEOG = avgEOG / epochDuration;
% avgDelta = avgDelta / epochDuration;
avgF0 = avgF0 / epochDuration;
avgF1 = avgF1 / epochDuration;
avgF2 = avgF2 / epochDuration;
avgFSP = avgFSP / epochDuration;
avgFR = avgFR / epochDuration;

for j = 1:numEpochs
    [~, pos] = max([avgF0(j) avgF1(j) avgF2(j) avgFSP(j) avgFR(j)]);     % Calculamos el maximo     
    hypnogram(j) = pos - 1;
end
hypnogram(hypnogram == 4) = 5;

% Damos preferencia a la fase REM
hypnogram(avgFR >= 0.7) = 5;

% APLICAMOS el primer posprocesado. Unir los bloques REM
hypnogram = mergeRemBlocks(hypnogram, highREM);

% Creamos remList para el siguiente posprocesado y lo aplicamos. Seguimos
% uniendo REM. En este caso, bloques cercanos los unos de los otros.
remList = buildRemList(hypnogram, avgEMG, spindlesList, highSpindle, ...
    useSpindles, 0);
if ~isempty(remList)
    hypnogram = mergeRemBlocks2(hypnogram, remList, avgF0, avgF1, ...
        avgF2, avgFSP);
end

% Siguiente posprocesado. Quitamos falsos positivos claros provocados por
% los procesados anteriores.
[hypnogram, anomaliaF0F3] = removeFalseRem(hypnogram, useSpindles, ...
    highREM, highSpindle, avgF0, avgF1, avgFSP, avgFR, avgEMG);

% Posprocesado de sleep spindles
emg_comprometido = 0;
% eog_comprometido = 0;
remList = buildRemList(hypnogram, avgEMG, spindlesList, highSpindle, ...
    useSpindles, 0);
if useSpindles
    [hypnogram, emg_comprometido] = ...
        doSpindles(hypnogram, remList, spindlesList, highSpindle, ...
        avgF0, avgF1, avgF2, avgFSP, avgFR, avgEMG, avgEOG);
end

% Empezamos a borrar falsos positivos de REM situados en zonas 
% claramente erroneas.
hypnogram = removeImpossible(hypnogram, avgF0, avgF1, avgF2, ...
    avgFSP, avgFR, emg_comprometido, highREM);
previousHypnogram(1,:) = hypnogram;
% Reconstruimos remList una vez mas con los nuevos cambios y aplicamos 
% el siguiente procesado. Ahora utilizamos el EMG para determinar los 
% falsos positivos en REM.
remList2 = buildRemList(hypnogram, avgEMG, spindlesList, highSpindle, ...
    useSpindles, 0);
if ~isempty(remList2) && ~emg_comprometido
    hypnogram = removeShortRemPeriods(hypnogram, remList2, avgF0, avgF1, ...
        avgF2, avgFSP, avgFR);
end
previousHypnogram(2,:) = hypnogram;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Y del mismo modo, zonas dudosas con emg muy bajo pueden ser 
% convertidas a REM si cumplen las condiciones.
if useSpindles
    hypnogram = checkLowEmg(hypnogram, highSpindle, avgF0, avgFSP, avgFR, highREM);
end
previousHypnogram(3,:) = hypnogram;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Aplicamos el procesado de F1-F2.
hypnogram = drowsySleepTransitions(hypnogram, avgF0, avgF1, avgF2, avgFSP, ...
    avgFR, emg_comprometido, useSpindles, spindlesList, highSpindle, avgEMG);
previousHypnogram(4,:) = hypnogram;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Procesado de conflictos entre F1 y F5.
hypnogram = remFromN1(hypnogram, avgF0, avgF1, avgF2, avgFSP, ...
    avgFR, previousHypnogram, emg_comprometido, anomaliaF0F3);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Procesado aplicado solo si el paciente no presenta REM. Esta 
% situaci�n puede darse si el paciente presenta sue�o REM sin apenas 
% movimiento REM.
remList3 = buildRemList(hypnogram, avgEMG, spindlesList, highSpindle, useSpindles, 1);
blanco = 0;
if isempty(remList3)
    blanco = 1;
    hypnogram = remWithoutMovements(hypnogram, avgF0, avgF1, avgF2, ...
        avgFSP, avgFR, highREM);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEMPORALES

% POSPROCESADO EMG. Para cada bloque REM, miramos la actividad del EMG. Si
% supera la media de la amplitud del EMG + std(), entonces se interpreta como un
% cambio de fase, si el cambio se produce al principio o al final, es
% posible que sea un bloque REM "gordo" (cuando empieza demasiado pronto o 
% termina demasiado tarde, provocando falsos positivos).

prohibidos = find(avgF0 <= 0.3 & avgF2 < 0.5 & avgFR >= 0.7);
prohibidos = prohibidos(prohibidos & hypnogram(prohibidos - 1) ~= 0);
% Nos aseguramos que las epochs REM fijas (prohibidos) sigan siendolo. 
%     resultado(prohibidos) = 5;


remList4 = buildRemList(hypnogram, avgEMG, spindlesList, highSpindle, useSpindles, 1);
if ~isempty(remList4) && ~emg_comprometido
    for j = 1:size(remList4, 1)
        % Si la desviaci�n t�pica es mayor de 0.05, entonces es muy
        % probable que sea un bloque con muchos cortes.
        limiteEMG = remList4(j, 5) + max(std(avgEMG(remList4(j, 1):remList4(j, 2))), 0.2);
        for k = remList4(j,1):remList4(j,2)
            if (limiteEMG < avgEMG(k) || avgF0(k) >= 0.9) && avgF0(k)>=0.7 && avgF1(k) < 0.5 && avgFR(k) <= 0.5 && ~any(k == prohibidos)
                hypnogram(k) = 0;
            end
        end
    end
end


% PROCESADO DE AMPLIACION/REDUCCION/ELIMINACION de F0-F5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
remList5 = buildRemList(hypnogram, avgEMG, spindlesList, highSpindle, useSpindles, 1);
% Comprobamos si tiene previamente un F0. De ser as� es posible que
% sea un falso positivo.
limiteEMG = mean(avgEMG(hypnogram == 1 | hypnogram == 2)) >= -0.8;
if ~isempty(remList5) && ~limiteEMG
    for j=1:size(remList5, 1)
        aux = remList5(j, 1) - 1;
        if aux > 0 && hypnogram(aux) <= 0
            count = 0;
            for k = remList5(j, 1):remList5(j, 2)
                if hypnogram(k) == 5 && highSpindle(k) >= 3 && (avgF0(k) > 0.9 || avgF1(k) > 0.9 || avgF2(k) > 0.9 || avgFSP(k) > 0.9)
                    hypnogram(k - count:k) = -1;
                    count = 0;
                elseif (count < 3 || avgFR(k) < 0.9) && highSpindle(k) >= 3 
                    count = count + 1;
                else
                    break;
                end
                if k == remList5(j, 2) && count > 0
                    hypnogram(k-count:k) = -1;
                end
            end
        end
    end
    for j = 2:numEpochs
        if hypnogram(j) == -1
            [~, pos] = max([avgF0(j) avgF1(j) avgF2(j) avgFSP(j)]);
            switch pos
                case 1
                    if ~emg_comprometido
                        hypnogram(j) = 0;
                    elseif hypnogram(j-1)~=2
                        hypnogram(j) = 1;
                    else
                        hypnogram(j) = 2;
                    end
                case 2
                    if hypnogram(j-1)~=2
                        hypnogram(j) = 1;
                    else
                        hypnogram(j) = 2;
                    end
                case 3
                    if hypnogram(j-1)~=0
                        hypnogram(j) = 2;
                    else
                        hypnogram(j) = 1;
                    end
            end
        end
    end
end


remList5 = buildRemList(hypnogram, avgEMG, spindlesList, highSpindle, useSpindles, 1);
porcentajeREM = sum(hypnogram == 5) / numEpochs;  % Porcentaje de fase REM
if ~isempty(remList5) && porcentajeREM >= 0.1
    for j=1:size(remList5, 1)
        rango = remList5(j, 1):remList5(j, 2);
        % Un bloque de tama�o 1 lo consideramos un FP.
        if remList5(j, 3) <= 1
            hypnogram(rango) = -1;
        end
        if hypnogram(remList5(j, 1) - 1) == 0 || hypnogram(remList5(j, 1) - 1) == 1
            % Contabilizamos los picos REM, miramos los valores
            % maximos de vectorREM para saber si es o no un bloque
            % 'fuerte'. Si es superior a 5 lo dejamos.
            % Si esta precedido de F0 es mas probable que sea FP, si est�
            % precedido de F1, puede que haya que recortarlo.
            vrem = highREM(rango);
            if hypnogram(remList5(j, 1) - 1) == 0
                if max(vrem) <= 5 || remList5(j, 3) <= 5
                    hypnogram(rango) = -1;
                elseif any(vrem <= 1)
                    lista = rango;
                    hypnogram(lista(vrem <= 1)) = -1;
                end
            elseif remList5(j, 1) > 5 && all(hypnogram(remList5(j, 1) - 5:remList5(j, 1) - 1) <= 1)
                if max(vrem) <= 5 || remList5(j, 3) <= 5
                    hypnogram(rango) = -1;
                elseif any(vrem <= 1)
                    lista = rango;
                    hypnogram(lista(vrem <=1)) = -1;
                end
            elseif blanco
                hypnogram(rango) = -1;
            end
        end
        % Mas de un 20% del sue�o en REM es demasiado. Suponemos que se trata de un
        % registro con falsos positivos. Para establecer una decision, tomamos el
        % vectorREM y el vectorSp.
        if porcentajeREM >= 0.2 && sum(highREM(rango) < highSpindle(rango)) >= remList5(j, 3)
            % Si vectorSp es mayor que vectorREM
            hypnogram(rango) = -1;
        elseif porcentajeREM >= 0.2 && sum(highREM(rango) < highSpindle(rango)) >= remList5(j, 3) * 2 / 3 && max(highREM(rango)) < 5
            % Si vectorSp es algo mayor que vectorREM
            hypnogram(rango) = -1;
        end

    end

    for j = 2:numEpochs
        if hypnogram(j) == -1
            hypnogram(j) = 2;
            [~, pos] = max([avgF0(j) avgF1(j) avgF2(j) avgFSP(j)]);
            if pos == 1
                if ~emg_comprometido
                    hypnogram(j) = 0;
                elseif hypnogram(j-1)~=2
                    hypnogram(j) = 1;
                end
            end
            if pos == 2 && hypnogram(j - 1) ~= 2
                hypnogram(j) = 1;
            end
            if pos == 3 && hypnogram(j - 1) == 0
                hypnogram(j) = 1;
            end
            if pos == 4
                hypnogram(j) = 3;
            end
        end
    end
elseif porcentajeREM < 0.1
%         disp('Caso con poco REM');
    lista = find(hypnogram ~= 5 & highREM >= 3);
    for j=1:length(lista)
        if (lista(j) - 1) > 0 % Fixed: attempted to access resultado(0) (Diego 12/09/2013)
            if highSpindle(lista(j)) < 5 && (hypnogram(lista(j) - 1) == 2 || hypnogram(lista(j) - 1) == 5) 
                hypnogram(lista(j)) = 5;
            end
        end
    end
end

remList6 = buildRemList(hypnogram, avgEMG, spindlesList, highSpindle, useSpindles, 1);

for j=1:size(remList6, 1) - 1
    if remList6(j, 2) + 10 >= remList6(j + 1, 1)
%         fprintf('Demasiado cerca 2 bloques REM: %d\n', remList6(j,1));
        tramo = remList6(j, 2):remList6(j + 1, 1);
        tramo_valido = tramo(avgF0(tramo) < 0.7);
        hypnogram(tramo_valido) = 5;
    end
end