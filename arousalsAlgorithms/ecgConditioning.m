function [signalfiltered] = ecgConditioning(ecg, ecgRate, signal, signalRate)
%ECGCONDITIONING Conditiong of signal using ecg
%   
%   This functions aloows conditioning signal 'signal' with the ecg signal,
%   allowing to remove unwanted spikes.
%
%   ecg         ECG signal
%   ecgRate     ECG Sample Rate
%   signal      Signal to be conditioned
%   signalRate  Signal rate

    ecgLength = length(ecg);

    ecgAbruptChange = zeros(ecgLength, 1, 'int8');
    ecgDiffsNoAbs = diff(ecg);
    ecgDiffs = abs(ecgDiffsNoAbs);
    meanDiff = mean(ecgDiffs);

    ecgAbruptChange(ecgDiffsNoAbs > 5 * meanDiff) = 1;
    ecgAbruptChange = ecgAbruptChange + [ecgAbruptChange(1:end - 1); 0] + ...
        [0; ecgAbruptChange(2:end)];
    ecgAbruptChange(ecgAbruptChange > 1) = 1;

    detected = diff(ecgAbruptChange);
    inicios = find(detected == 1) + 1;
    fines = find(detected == -1);
    if ecgAbruptChange(1)
        fines = fines(2:end);
    end
    if ecgAbruptChange(end)
        inicios = inicios(1:end - 1);
    end
    %  inicios & fines in samples from ecg

    signalfiltered = signal;
    for k = 1:length(inicios)
        secondi = inicios(k) / ecgRate;
        secondf = fines(k) / ecgRate;
        i = round(secondi * signalRate) + 1;
        f = round(secondf * signalRate) + 1;
        if i < 30 || f > length(signal) - 30
            continue
        end
        if f > i
            middle = int32(i + (f - i) / 2);
            intervalSize = f - i + round((f - i) / 2);
            actualWindow = signal(middle - intervalSize:middle + intervalSize);
            prevWindow = signal(middle - 4 * intervalSize:middle - intervalSize);
            nextWindow = signal(middle + intervalSize:middle + 4 * intervalSize);
            actualAmpl = max(actualWindow) - min(actualWindow);
            prevAmpl = max(prevWindow) - min(prevWindow);
            nextAmpl = max(nextWindow) - min(nextWindow);
            
            if actualAmpl > 1.1 * prevAmpl && actualAmpl > 1.1 * nextAmpl
                interpolated = interp1([i - 1, f + 1], ...
                    [signal(i - 1), signal(f + 1)], i:f);
                artifact = interpolated' > signal(i:f);
                value = artifact(1);
                artifact = artifact(artifact == value);
                signalfiltered(i:i + length(artifact) - 1) = ...
                    interpolated(1:length(artifact));
            end
        end
    end

end

