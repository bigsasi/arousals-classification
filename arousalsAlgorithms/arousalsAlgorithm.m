function [detectedArousals] = arousalsAlgorithm(eeg, eegSec, ecg, emg, eogl, eogr)

config = Configuration.getInstance;

sleepStages = [];

eogRate = eogl.header.sample_rate;
emgRate = emg.header.sample_rate;
eegRate = eeg.header.sample_rate;
ecgRate = ecg.header.sample_rate;

eogPhysMax = min(eogl.header.physical_max, 125);
emgPhysMax = min(emg.header.physical_max, 50);

ecgSmooth = fastsmooth(ecg.raw, 5, 1, 1);

eeg.raw = ecgConditioning(ecgSmooth, ecgRate, eeg.raw, eegRate);

eegSec.raw = ecgConditioning(ecgSmooth, ecgRate, eegSec.raw, eegRate);

if config.usePreviousHypnogram
    if exist('sleepStages.tmp.mat', 'file')
        load('sleepStages.tmp.mat', 'sleepStages');
    else
        sleepStages = [];
    end
end

if isempty(sleepStages)
    
    eoglNormalized = eogl.raw/ eogPhysMax;
    eoglNormalized(eoglNormalized > 1) = 1;
    eoglNormalized(eoglNormalized < -1) = -1;

    eogrNormalized = eogr.raw/ eogPhysMax;
    eogrNormalized(eogrNormalized > 1) = 1;
    eogrNormalized(eogrNormalized < -1) = -1;

    emgNormalized = abs(emg.raw) / emgPhysMax;
    emgNormalized(emgNormalized > 1) = 1;

    t = tic;
    [spindles1, spindles2] = ...
        sleepSpindlesDetection(eeg.raw, eegSec.raw, eegRate, emgRate);

    elapsed = toc(t);
    Output.DEBUG('Sleep Spindles analysis: %f s\n', elapsed);


    t = tic;
    [kcomplex1, kcomplex2] = ...
        kComplexDetection(eeg.raw, eegSec.raw, eegRate, emg.raw, emgRate);

    elapsed = toc(t);
    Output.DEBUG('KComplex analysis: %f s\n', elapsed);

    t = tic;

    sleepStages.Signal = buildHypnogram(eeg.raw, eegSec.raw, eegRate, ...
        emgNormalized, emgRate, eoglNormalized, eogrNormalized, ...
        eogRate, spindles1, spindles2, kcomplex1, kcomplex2);

    
    elapsed = toc(t);
    Output.DEBUG('build hypnogram: %f s\n', elapsed);

end

save('sleepStages.tmp.mat', 'sleepStages');

t = tic;

arousals = arousalsDetection(eeg.raw, eegSec.raw, eegRate, ...
    emg.raw, emgRate, sleepStages);

if ~isempty(arousals)
    detectedArousals(length(arousals)).start = 0;
else
    detectedArousals = [];
end
for i = 1:length(arousals)
    detectedArousals(i).start = arousals(i).startSecond;
    endt = arousals(i).endSecond; 
    detectedArousals(i).duration = endt - detectedArousals(i).start;
end

elapsed = toc(t);
Output.DEBUG('arousals analysis: %f\n', elapsed);