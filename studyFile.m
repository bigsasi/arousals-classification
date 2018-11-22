function [stats] = studyFile(edfFileName, edfPlusFileName)
%STUDYFILE Detect arousals in edf file and compare them against the expert
% annotations. 
%   Read an edf file and detect possible arousals using our automatic 
%   algorithm. Then compare our possible events against the events scored
%   by the expert and return the stats. 

    config = Configuration.getInstance;

    epoch = config.epochDuration;

    edfFile = loadFile(edfFileName);

    numEpochs = edfFile.header.num_data_records / epoch;

    annotationsFile = loadAnnotations(edfPlusFileName);
    
    annotatedArousalsEpoch = zeros(numEpochs, 1, 'int8');
    if ~isfield(annotationsFile, 'Arousal')
        annotationsFile.Arousal = [];
    end
    for i = 1:length(annotationsFile.Arousal)
        middle = annotationsFile.Arousal(i).start;
        middle = middle + annotationsFile.Arousal(i).duration / 2;

        epochNum = ceil(middle / epoch);
        if epochNum ~= 0
            annotatedArousalsEpoch(epochNum) = 1;
        end
    end
%     Output.INFO('Starting algorithm for file %s\n', fullfile(P,F));


    % edfFile must be a shhs edf (because of the signals order)
    eeg = edfFile.signal{8};
    eegSec = edfFile.signal{3};
    ecg = edfFile.signal{4};
    emg = edfFile.signal{5};
    eogl = edfFile.signal{6};
    eogr = edfFile.signal{7};

    if eogl.header.sample_rate ~= eogr.header.sample_rate
        disp('Left and right EOG sample rate does not match, the analysis could be wrong');
    elseif eeg.header.sample_rate ~= eegSec.header.sample_rate
        disp('Both EEG sample rates do not match, the analysis could be wrong');
    elseif length(eogl.raw) ~= length(eogr.raw)
        disp('The lengths of the right and left EOG are different, the analysis could be wrong');
    elseif length(eeg.raw) ~= length(eegSec.raw)
        disp('The lengths of both EEG signals are different, the analysis could be wrong');
    end

    detectedArousals = arousalsAlgorithm(eeg, eegSec, ecg, emg, eogl, eogr);

    if isempty(detectedArousals), return; end;

    detectedArousals = removeInvalidArousals(detectedArousals);

    if isempty(detectedArousals), return; end;

    detectedArousals = removeDuplicates(detectedArousals);

    detectedArousalsEpoch = zeros(numEpochs, 1, 'int8');
    for i = 1:length(detectedArousals)
        middle = detectedArousals(i).start;
        middle = middle + detectedArousals(i).duration / 2;

        epochNum = ceil(middle / epoch);
        if epochNum ~= 0
            detectedArousalsEpoch(epochNum) = 1;
        end
    end

    stats.name = edfFileName;
    stats.detectedArousals = detectedArousals;
    stats.expertArousals = annotationsFile.Arousal;
    
    stats.annotatedArousalsEpoch = annotatedArousalsEpoch;

    [stats.sens, stats.spec, stats.error] = ...
        sensitivitySpecificityError(detectedArousalsEpoch, ...
        annotatedArousalsEpoch, [0, 1]);

    
    stats.confMatrix = buildConfusionMatrix(detectedArousalsEpoch, ...
        annotatedArousalsEpoch, [0,1]);

    stats.totalExpert = sum(annotatedArousalsEpoch);

    stats.kappa = kappaIndex(stats.confMatrix);
    stats.AUC = (stats.sens(1) + stats.spec(1)) / 2;

end

function newArousals = removeDuplicates(arousals)
    size = length(arousals);

    newArousals(size).start = 0;
    newArousals(size).duration = 0;

    newArousals(1) = arousals(1);
    i = 2;
    for k = 2:length(arousals);
        prev = arousals(k - 1);
        actual = arousals(k);
        if actual.start > prev.start + prev.duration
            newArousals(i) = actual;
            i = i + 1;
        elseif actual.start + actual.duration > prev.start + prev.duration
            newArousals(i - 1).duration = actual.start - prev.start + actual.duration;
        end
    end
    newArousals(i:end) = [];
end

function newArousals = removeInvalidArousals(arousals)
    size = nnz([arousals(:).start] > 0);

    newArousals(size).start = 0;
    newArousals(size).duration = 0;

    i = 1;
    for k = 1:length(arousals)
        if arousals(k).start > 0
            newArousals(i).start = arousals(k).start;
            newArousals(i).duration = arousals(k).duration;
            i = i + 1;
        end
    end
end
