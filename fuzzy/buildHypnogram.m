% function [hypnogram, eventsAllowed] = buildHypnogram(eeg1, eeg2, eegRate, ...
%     emg, emgRate, eogl, eogr, eogRate, useSpindles, eegSpindles, spindlesList, kcomplexList)
function [hypnogram] = buildHypnogram(eeg1, eeg2, eegRate, ...
    emg, emgRate, eogl, eogr, eogRate, spindles1, spindles2, kcomplex1, ...
    kcomplex2)
%BUILDHIPNOGRAM Summary of this function goes here
%   Detailed explanation goes here

%% Configuration
    config = Configuration.getInstance;
    
    windowSize = config.hypnogramWindowSize;
    windowStep = config.hypnogramWindowStep;
    
    lcutoff = config.hypnogramLcutoff;
    hcutoff = config.hypnogramHcutoff;
    
    epochDuration = config.epochDuration;
    
%% Signal parameters
    eegLength = length(eeg1);
    totalSeconds = eegLength / eegRate;
    totalEpochs = totalSeconds / epochDuration;
    
    eoglAmplitude = signalAmplitude(eogl, eogRate, windowSize, windowStep);
    eogrAmplitude = signalAmplitude(eogr, eogRate, windowSize, windowStep);

    eoglAmplitude = eoglAmplitude - 1;
    eogrAmplitude = eogrAmplitude - 1;
    
    eogAverage = (eoglAmplitude + eogrAmplitude) / 2;
    
    emgMean = signalMean(emg, emgRate, windowSize, windowStep);
    emgMean = 2 * emgMean - 1;
    emgMean = 2 * (emgMean - min(emgMean)) / (max(emgMean) - min(emgMean)) - 1;
    
    [alphaPower1, deltaPower1, thetaPower1, betaPower1] = signalPower(eeg1, ...
        windowSize, eegRate, windowStep, lcutoff, hcutoff);
    
    totalPower = alphaPower1 + deltaPower1 + thetaPower1 + betaPower1;
    alphaPower1 = alphaPower1 ./ totalPower;
    deltaPower1 = deltaPower1 ./ totalPower;
    thetaPower1 = thetaPower1 ./ totalPower;
    betaPower1 = betaPower1 ./ totalPower;
    
    [alphaPower2, deltaPower2, thetaPower2, betaPower2] = signalPower(eeg2, ...
        windowSize, eegRate, windowStep, lcutoff, hcutoff);
    
    totalPower = alphaPower2 + deltaPower2 + thetaPower2 + betaPower2;
    alphaPower2 = alphaPower2 ./ totalPower;
    deltaPower2 = deltaPower2 ./ totalPower;
    thetaPower2 = thetaPower2 ./ totalPower;
    betaPower2 = betaPower2 ./ totalPower;
    
    alphaMeanPower = (alphaPower1 + alphaPower2) / 2;
    deltaMeanPower = (deltaPower1 + deltaPower2) / 2;
    thetaMeanPower = (thetaPower1 + thetaPower2) / 2;
    betaMeanPower = (betaPower1 + betaPower2) / 2;
    
%% Fuzzy input construction
    
    emgAmplitudeInput = zeros(totalSeconds, 1);
    eogAmplitudeInput = zeros(totalSeconds, 1);
    eogMaxInput = zeros(totalSeconds, 1);
    alphaInput = zeros(totalSeconds, 1);
    betaInput = zeros(totalSeconds, 1);
    thetaInput = zeros(totalSeconds, 1);
    deltaInput = zeros(totalSeconds, 1);
    
    half = floor(epochDuration /  2);
    
    for k = 1:totalSeconds
        % Calculamos el tamañoo de la ventana con la que trabajar en cada 
        % iteracion (del tamañoo de 1 epoch excepto al principio y al final 
        % cuando no hay suficientes segundos). Los parametros serán los
        % datos de entrada del módulo de lógica difusa.
        if k < half
            window = 1:k + half;
            windowLength = k + half;
        elseif k > totalSeconds - half
            window = k - epochDuration + 1:totalSeconds;
            windowLength = totalSeconds - k + epochDuration;
        else
            window = k - half + 1:k + half;
            windowLength = 2 * half;
        end

        emgAmplitudeInput(k) = sum(emgMean(window)) / windowLength;
        eogAmplitudeInput(k) = sum(eogAverage(window)) / windowLength;
        eogMaxInput(k) = max(eogAverage(window));
        alphaInput(k) = sum(alphaMeanPower(window)) / windowLength;
        betaInput(k) = sum(betaMeanPower(window)) / windowLength;
        thetaInput(k) = sum(thetaMeanPower(window)) / windowLength;
        deltaInput(k) = sum(deltaMeanPower(window)) / windowLength;
    end
    
    spindlesListEpoch = zeros(totalEpochs, 1);
    for spindle = spindles1
        epochNum = spindle.epochNum;
        spindlesListEpoch(epochNum) = spindlesListEpoch(epochNum) + 1;
    end
    for spindle = spindles2
        epochNum = spindle.epochNum;
        spindlesListEpoch(epochNum) = spindlesListEpoch(epochNum) + 1;
    end
    
    useSpindles = mean(spindlesListEpoch) > 0.3;

    % Normalizacion de spindlesList
    maxSpindleValue = 2 * (ceil(mean(spindlesListEpoch)) + 1);
    spindlesListEpoch(spindlesListEpoch > maxSpindleValue) = maxSpindleValue;
    spindlesListEpoch = spindlesListEpoch / maxSpindleValue;
    
    % Construimos un vector de sleep spindles por segundos para el módulo 
    % de lógica difusa.
    spindlesListSecond = zeros(totalSeconds, 1);
    for j = 1:length(spindlesListEpoch) - 1
        if spindlesListEpoch(j) > 0
            startSecond = (j - 1) * epochDuration + 1;
            endSecond = j * epochDuration;
            spindlesListSecond(startSecond:endSecond) = spindlesListEpoch(j);
        end
    end
    
    
    kcomplexListSecond = zeros(totalSeconds, 1);
    for kcomplex = kcomplex1
        epochNum = kcomplex.epochNum;
        startSecond = (epochNum - 1) * epochDuration + 1;
        endSecond = epochNum * epochDuration;
        kcomplexListSecond(startSecond:endSecond) = ...
            kcomplexListSecond(startSecond:endSecond) + 1;
    end
    for kcomplex = kcomplex2
        epochNum = kcomplex.epochNum;
        startSecond = (epochNum - 1) * epochDuration + 1;
        endSecond = epochNum * epochDuration;
        kcomplexListSecond(startSecond:endSecond) = ...
            kcomplexListSecond(startSecond:endSecond) + 1;
    end

    fuzzyInput = [eogAmplitudeInput, eogMaxInput, emgAmplitudeInput, ...
        alphaInput, betaInput, thetaInput, deltaInput, spindlesListSecond, ...
        kcomplexListSecond];
    
%% Fuzzy reasoning
    % Seleccionamos los módulos de lógica difusa y los leemos
    fisFile.F0 = 'fuzzy/stateF0.fis';
    fisFile.F1 = 'fuzzy/stateF1.fis';
    fisFile.F2 = 'fuzzy/stateF2.fis';
    fisFile.FSP = 'fuzzy/stateFSP.fis';
    fisFile.FR = 'fuzzy/stateFR.fis';
    fuzzyF0 = readfis(fisFile.F0);
    fuzzyF1 = readfis(fisFile.F1);
    fuzzyF2 = readfis(fisFile.F2);
    fuzzyFSP = readfis(fisFile.FSP);
    fuzzyFR = readfis(fisFile.FR);

    % Enviamos los datos al módulo de lógica difusa. Aquellos con temp son 
    % módulos a los que se les ha aplicado un entrenamiento con algoritmos 
    % genéticos. El módulo de F1 no tiene ese entrenamiento por lo que no 
    % recibe los complejos k y el módulo de REM no tiene ni los complejos K
    % ni los spindles como parámetros de entrada.
    temp = evalMamdaniWithNaN(fuzzyInput, fuzzyF0, 0)';
    grade.F0 = temp(1,:);
    grade.F1 = evalMamdaniWithNaN(fuzzyInput(:, 1:end - 1), fuzzyF1, 0)';
    temp = evalMamdaniWithNaN(fuzzyInput, fuzzyF2, 0)';
    grade.F2 = temp(1,:);
    temp = evalMamdaniWithNaN(fuzzyInput, fuzzyFSP, 0)';
    grade.FSP = temp(1,:);
    grade.FR = evalMamdaniWithNaN(fuzzyInput(:, 1:end - 2), fuzzyFR, 0)';

    % Normalizamos los grados de pertenencia de las fases menos el módulo 
    % de F1, con el que se trabaja directamente. NOTA: Estos valores SON 
    % FIJOS con respecto al módulo de lógica difusa. Si se mantiene el 
    % módulo ha de mantenerse estos valores, si cambia el módulo también 
    % ha de cambiar el min y el max.
    grade.F0 = (grade.F0 - 0.0895) / (0.926 - 0.0895);
    grade.F2 = (grade.F2 - 0.2) / (0.832 - 0.2);
    grade.FSP = (grade.FSP - 0.0767) / (0.921 - 0.0767);
    grade.FR = (grade.FR - 0.0633) / (0.937 - 0.0633);
    
    grade.Samples_epoch = 30;
%% Output construction
    hypnogram = aplicarProcesados(grade, emgAmplitudeInput, ...
        eogAmplitudeInput, useSpindles, spindlesListEpoch)';
    
end

