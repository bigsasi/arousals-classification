function [varargout] = signalPower(signal, windowSize, signalRate, ...
    windowStep, lcutoff, hcutoff)
%SIGNALPOWER This function obtains the power for each window of the input
%signal, given a window size and window step. Can obtain the power in multiple
%bands at once

    windowStepSamples = signalRate * windowStep;
    windowSizeSamples = windowSize * signalRate;
    signalLength = length(signal);
    longitudLowFrecs = length(lcutoff);
    hammingWindow = hamming(windowSizeSamples);

    if (any(hcutoff > (signalRate / 2)) || any(lcutoff > (signalRate / 2)))
        fprintf(1, '\nError: La frecuencia de muestreo es %.2f Hz. => intervalo aplicable [0 - %.2f ]Hz', sample_rate, sample_rate/2);
        return;
    end

    if ne(longitudLowFrecs, length(hcutoff))
        fprintf(1, '\nError al aplicar filtro paso banda: El número de puntos de corte inferior no coincide con el número de cortes superiores');
        return;
    end
    
    numWindows = length(1:windowStepSamples:signalLength);
    
    % Calculate the number of unique points (depending on nfft odd or even)
    NumUniquePts = ceil((windowSizeSamples+1)/2);
    % We construct the evenly spaced frequency vector with NumUniquePts to
    % represent x-axis
    step = signalRate / windowSizeSamples;
    f = 0:step:(NumUniquePts - 1) * step;
    % Index values that are equal or higher to corresponding frequency limits
    f1 = ceil(lcutoff / step) + 1;
    f2 = ceil(hcutoff / step) + 1;
    f2(f2 > length(f)) = length(f);

    varargout{nargout} = 0; 
    
    currentWindow = 0;
    windows = zeros(windowSizeSamples, numWindows);    
    for currentSample = 1:windowStepSamples:signalLength - windowSizeSamples
        currentWindow = currentWindow + 1;
        
        sample = floor(currentSample);
        limit = sample + windowSizeSamples - 1;
        windows(:, currentWindow) = signal(sample:limit) .* hammingWindow;
    end
    
    fftx = fft(windows, windowSizeSamples);
    
    % Since FFT is symmetric, throw away second half
    mx = abs(fftx(1:NumUniquePts, :));
    % Take the square magnitude, thus to obtain the power (without scaling)
    mx = mx .^ 2;
    
    % Since we dropped half the FFT, we multiply mx by 2 to keep the same energy. 
    % The DC component (fftx(1)) and Nyquist component (fftx(1+nfft/2), if it
    % exists) are unique and should not be multiplied by 2.
    limit = NumUniquePts - 1;
    % odd nfft excludes Nyquist point
    if rem(windowSizeSamples, 2), limit = NumUniquePts; end
    
    mx = mx / windowSizeSamples;
    
    for k = 1:nargout
        if f1(k) > 1 && f2(k) <= limit
            varargout{k} = sum(mx(f1(k):f2(k), :), 1)' * 2;     
        elseif f1(k) > 1 && f2(k) > limit
            varargout{k} = sum(mx(f1(k):limit, :), 1)' * 2 + sum(mx(limit + 1:f2(k), :), 1)';
        elseif f2(k) < limit
            varargout{k} = sum(mx(1, :), 1)' + sum(mx(2:f2(k), :), 1)' * 2;
        else
            varargout{k} = sum(mx(1, :), 1)' + sum(mx(2:limit, :), 1)' * 2 + sum(mx(limit + 1:f2(k), :), 1)';
        end
        varargout{k} = varargout{k} / windowSizeSamples;
        varargout{k}(currentWindow + 1:numWindows) = varargout{k}(currentWindow);
    end
end