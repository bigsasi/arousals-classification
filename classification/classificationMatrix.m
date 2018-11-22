function matrix = classificationMatrix(anotatedArousals)
%NEWCLASSIFICATIONMATRIX Summary of this function goes here
%   Detailed explanation goes here
   
    config = Configuration.getInstance;
    features = Features.getInstance; 
    
    load('lastArousalDetection.mat');
    indexes = zeros(length(arousalsEeg1) + length(arousalsEeg2), 4);
    indexesIndex = 1;
        
    midEeg1 = [arousalsEeg1.midSecond];
    midEeg2 = [arousalsEeg2.midSecond];
    midEMG = [arousalsEMG.midSecond];
    
    [deltaPower1, sigmaPower1] = signalPower(eeg1, 3, 125, 0.2, [.5 12], [4 15]);
    [deltaPower2, sigmaPower2] = signalPower(eeg2, 3, 125, 0.2, [.5 12], [4 15]);
    
    for index1 = 1:length(arousalsEeg1)
        delta = midEeg2 - midEeg1(index1);
        delta = abs(delta);
        
        [value, index2] = min(delta);
        if value <= 30
            indexes(indexesIndex, :) = [index1 index2 0 0];
            indexesIndex = indexesIndex + 1;
        end
    end
    
    for index2 = 1:length(arousalsEeg2)
        delta = midEeg1 - midEeg2(index2);
        delta = abs(delta);
        
        [value, index1] = min(delta);
        if value <= 30
            if ~ismember([index1 index2 0 0], indexes, 'rows')
                indexes(indexesIndex, :) = [index1 index2 0 0];
                indexesIndex = indexesIndex + 1;
            end
        end
    end
    
%     indexes(indexesIndex:end, :) = [];
    
    for i = 1:indexesIndex - 1
        i1 = indexes(i, 1);
        i2 = indexes(i, 2);
        midPoint = (midEeg1(i1) + midEeg2(i2)) / 2;
        
        delta = midEMG - midPoint;
        delta = abs(delta);
        
        [value, indexEMG] = min(delta);
        if value <= 30
            indexes(i, 3) = indexEMG;
        end
        
        epochNum = floor(midPoint / config.epochDuration) + 1;
        indexes(i, 4) = epochNum;
    end
    
    indexes = sortrows(indexes(1:indexesIndex - 1, :), 4);
    
    epochsWithPattern = unique(indexes(:, 4))';
    for epoch = epochsWithPattern
        idx = find(indexes(:, 4) == epoch);
        if length(idx) > 1
            uniqueId1 = unique(indexes(idx, 1))';
            for index1 = uniqueId1
                id1 = find(indexes(idx, 1) == index1);
                if length(id1) > 1
                    deltas = midEeg1(indexes(idx(id1), 1)) - midEeg2(indexes(idx(id1), 2));
                    deltas = abs(deltas);
                    
                    [~, index] = min(deltas);
                    id1(index) = [];
                    indexes(idx(id1), :) = zeros(length(idx(id1)), 4);
                end
            end
            uniqueId2 = unique(indexes(idx, 2))';
            for index2 = uniqueId2
                if index2 == 0, continue; end
                id2 = find(indexes(idx, 2) == index2);
                if length(id2) > 1
                    deltas = midEeg1(indexes(idx(id2), 1)) - midEeg2(indexes(idx(id2), 2));
                    deltas = abs(deltas);
                    
                    [~, index] = min(deltas);
                    id2(index) = [];
                    indexes(idx(id2), :) = zeros(length(idx(id2)), 4);
                end
            end
        end
    end
    
    indexes(~any(indexes, 2), :) = [];
        
    featuresSize = features.getSize;
    
    numEpochs = length(sleepStages.Signal);
    missingEpochs = 1:numEpochs;
    missingEpochs(epochsWithPattern) = [];

    matrix = zeros(length(indexes) + length(missingEpochs), featuresSize);

    for i = 1:length(indexes)

        arousal1 = arousalsEeg1(indexes(i, 1));
        
        start1 = arousal1.startSecond;
        end1 = arousal1.endSecond;
        middle1 = arousal1.midSecond;
        
        arousal2 = arousalsEeg2(indexes(i, 2));
        start2 = arousal2.startSecond;
        end2 = arousal2.endSecond;
        middle2 = arousal2.midSecond;
        
        indexEmg = indexes(i, 3);
            
        epochNum = indexes(i, 4);

        matrix(i, features.duration) = arousal1.duration;
        matrix(i, features.duration + 1) = arousal2.duration;

        sw1 = round(arousal1.startSecond / config.arousalWindowStep);
        ew1 = round(arousal1.endSecond / config.arousalWindowStep);
        
        sw2 = round(arousal2.startSecond / config.arousalWindowStep);
        ew2 = round(arousal2.endSecond / config.arousalWindowStep);

        data1 = alphaPower1(sw1:ew1); % ./ alphaBaseline1(sw1:ew1);
        data2 = alphaPower2(sw2:ew2); % ./ alphaBaseline2(sw2:ew2);
        
        if features.totalAlpha
            matrix(i, features.totalAlpha) = sum(data1);
            matrix(i, features.totalAlpha + 1) = sum(data2);
        end
        if features.totalDeltaAlpha
            matrix(i, features.totalDeltaAlpha) = sum(abs(diff(data1)));
            matrix(i, features.totalDeltaAlpha + 1) = sum(abs(diff(data2)));
        end
        if features.meanDeltaAlpha
            matrix(i, features.meanDeltaAlpha) = mean(abs(diff(data1)));
            matrix(i, features.meanDeltaAlpha + 1) = mean(abs(diff(data2)));
        end
        if features.maxDeltaAlpha
            matrix(i, features.maxDeltaAlpha) = max(abs(diff(data1)));
            matrix(i, features.maxDeltaAlpha + 1) = max(abs(diff(data2)));
        end
        if features.minDeltaAlpha
            matrix(i, features.minDeltaAlpha) = min(abs(diff(data1)));
            matrix(i, features.minDeltaAlpha + 1) = min(abs(diff(data2)));
        end
        if features.diffAlpha
            matrix(i, features.diffAlpha) = max(data1) - min(data1);
            matrix(i, features.diffAlpha + 1) = max(data2) - min(data2);
        end
        if features.maxAlpha
            matrix(i, features.maxAlpha) = max(data1);
            matrix(i, features.maxAlpha + 1) = max(data2);
        end
        if features.minAlpha
            matrix(i, features.minAlpha) = min(data1);
            matrix(i, features.minAlpha + 1) = min(data2);
        end
        if features.meanAlpha
            matrix(i, features.meanAlpha) = mean(data1);
            matrix(i, features.meanAlpha + 1) = mean(data2);
        end
        if features.stdAlpha
            matrix(i, features.stdAlpha) = std(data1);
            matrix(i, features.stdAlpha + 1) = std(data2);
        end
        if features.varAlpha
            matrix(i, features.varAlpha) = var(data1);
            matrix(i, features.varAlpha + 1) = var(data2);
        end
        if features.geomeanAlpha
            matrix(i, features.geomeanAlpha) = geomean(data1);
            matrix(i, features.geomeanAlpha + 1) = geomean(data2);
        end
        if features.harmmeanAlpha
            matrix(i, features.harmmeanAlpha) = harmmean(data1);
            matrix(i, features.harmmeanAlpha + 1) = harmmean(data2);
        end

        data1 = thetaPower1(sw1:ew1); % ./ thetaBaseline1(sw1:ew1);
        data2 = thetaPower2(sw2:ew2); % ./ thetaBaseline2(sw2:ew2);
        
        if features.totalTheta
            matrix(i, features.totalTheta) = sum(data1);
            matrix(i, features.totalTheta + 1) = sum(data2);
        end
        if features.totalDeltaTheta
            matrix(i, features.totalDeltaTheta) = sum(abs(diff(data1)));
            matrix(i, features.totalDeltaTheta + 1) = sum(abs(diff(data2)));
        end
        if features.meanDeltaTheta
            matrix(i, features.meanDeltaTheta) = mean(abs(diff(data1)));
            matrix(i, features.meanDeltaTheta + 1) = mean(abs(diff(data2)));
        end
        if features.maxDeltaTheta
            matrix(i, features.maxDeltaTheta) = max(abs(diff(data1)));
            matrix(i, features.maxDeltaTheta + 1) = max(abs(diff(data2)));
        end
        if features.minDeltaTheta
            matrix(i, features.minDeltaTheta) = min(abs(diff(data1)));
            matrix(i, features.minDeltaTheta + 1) = min(abs(diff(data2)));
        end
        if features.diffTheta
            matrix(i, features.diffTheta) = max(data1) - min(data1);
            matrix(i, features.diffTheta + 1) = max(data2) - min(data2);
        end
        if features.maxTheta
            matrix(i, features.maxTheta) = max(data1);
            matrix(i, features.maxTheta + 1) = max(data2);
        end
        if features.minTheta
            matrix(i, features.minTheta) = min(data1);
            matrix(i, features.minTheta + 1) = min(data2);
        end
        if features.meanTheta
            matrix(i, features.meanTheta) = mean(data1);
            matrix(i, features.meanTheta + 1) = mean(data2);
        end
        if features.stdTheta
            matrix(i, features.stdTheta) = std(data1);
            matrix(i, features.stdTheta + 1) = std(data2);
        end
        if features.varTheta
            matrix(i, features.varTheta) = var(data1);
            matrix(i, features.varTheta + 1) = var(data2);
        end
        if features.geomeanTheta
            matrix(i, features.geomeanTheta) = geomean(data1);
            matrix(i, features.geomeanTheta + 1) = geomean(data2);
        end
        if features.harmmeanTheta
            matrix(i, features.harmmeanTheta) = harmmean(data1);
            matrix(i, features.harmmeanTheta + 1) = harmmean(data2);
        end
        
        data1 = emgPower1(sw1:ew1); % ./ emgBaseline1(sw1:ew1);
        data2 = emgPower2(sw2:ew2); % ./ emgBaseline2(sw2:ew2);
        
        if features.totalEmg
            matrix(i, features.totalEmg) = sum(data1);
            matrix(i, features.totalEmg + 1) = sum(data2);
        end
        if features.totalDeltaEmg
            matrix(i, features.totalDeltaEmg) = sum(abs(diff(data1)));
            matrix(i, features.totalDeltaEmg + 1) = sum(abs(diff(data2)));
        end
        if features.meanDeltaEmg
            matrix(i, features.meanDeltaEmg) = mean(abs(diff(data1)));
            matrix(i, features.meanDeltaEmg + 1) = mean(abs(diff(data2)));
        end
        if features.maxDeltaEmg
            matrix(i, features.maxDeltaEmg) = max(abs(diff(data1)));
            matrix(i, features.maxDeltaEmg + 1) = max(abs(diff(data2)));
        end
        if features.minDeltaEmg
            matrix(i, features.minDeltaEmg) = min(abs(diff(data1)));
            matrix(i, features.minDeltaEmg + 1) = min(abs(diff(data2)));
        end
        if features.diffEmg
            matrix(i, features.diffEmg) = max(data1) - min(data1);
            matrix(i, features.diffEmg + 1) = max(data2) - min(data2);
        end
        if features.maxEmg
            matrix(i, features.maxEmg) = max(data1);
            matrix(i, features.maxEmg + 1) = max(data2);
        end
        if features.minEmg
            matrix(i, features.minEmg) = min(data1);
            matrix(i, features.minEmg + 1) = min(data2);
        end
        if features.meanEmg
            matrix(i, features.meanEmg) = mean(data1);
            matrix(i, features.meanEmg + 1) = mean(data2);
        end
        if features.stdEmg
            matrix(i, features.stdEmg) = std(data1);
            matrix(i, features.stdEmg + 1) = std(data2);
        end
        if features.varEmg
            matrix(i, features.varEmg) = var(data1);
            matrix(i, features.varEmg + 1) = var(data2);
        end
        if features.geomeanEmg
            matrix(i, features.geomeanEmg) = geomean(data1);
            matrix(i, features.geomeanEmg + 1) = geomean(data2);
        end
        if features.harmmeanEmg
            matrix(i, features.harmmeanEmg) = harmmean(data1);
            matrix(i, features.harmmeanEmg + 1) = harmmean(data2);
        end

        data1 = sigmaPower1(sw1:ew1); % ./ alphaBaseline1(sw1:ew1);
        data2 = sigmaPower2(sw2:ew2); % ./ alphaBaseline2(sw2:ew2);
        
        if features.totalBeta
            matrix(i, features.totalBeta) = sum(data1);
            matrix(i, features.totalBeta + 1) = sum(data2);
        end
        
        if features.maxBeta
            matrix(i, features.maxBeta) = max(data1);
            matrix(i, features.maxBeta + 1) = max(data2);
        end
        if features.minBeta
            matrix(i, features.minBeta) = min(data1);
            matrix(i, features.minBeta + 1) = min(data2);
        end
        
        data1 = deltaPower1(sw1:ew1); % ./ alphaBaseline1(sw1:ew1);
        data2 = deltaPower2(sw2:ew2); % ./ alphaBaseline2(sw2:ew2);
        
        if features.totalDelta
            matrix(i, features.totalDelta) = sum(data1);
            matrix(i, features.totalDelta + 1) = sum(data2);
        end
        
        if features.maxDelta
            matrix(i, features.maxDelta) = max(data1);
            matrix(i, features.maxDelta + 1) = max(data2);
        end
        if features.minDelta
            matrix(i, features.minDelta) = min(data1);
            matrix(i, features.minDelta + 1) = min(data2);
        end
        
        [activity1, mobility1, complexity1] = hjorth(eeg1(round(start1 * 125):round(end1 * 125)), 0);
        [activity2, mobility2, complexity2] = hjorth(eeg2(round(start2 * 125):round(end2 * 125)), 0);
        
        if features.activityEeg
            matrix(i, features.activityEeg) = activity1;
            matrix(i, features.activityEeg + 1) = activity2;
        end
        if features.mobilityEeg
            matrix(i, features.mobilityEeg) = mobility1;
            matrix(i, features.mobilityEeg + 1) = mobility2;
        end
        if features.complexityEeg
            matrix(i, features.complexityEeg) = complexity1;
            matrix(i, features.complexityEeg + 1) = complexity2;
        end

            
        if indexEmg ~= 0
            arousal = arousalsEMG(indexEmg);
            sw = round(arousal.startSecond / config.arousalWindowStep / 2);
            ew = round(arousal.endSecond / config.arousalWindowStep / 2);
            
            data = emgAmplitude(sw:ew); %./ emgAmplitudeBaseline(startWindow:endWindow);

            if features.totalEmgAmplitude
                matrix(i, features.totalEmgAmplitude) = sum(data);
            end
            if features.maxEmgAmplitude
                matrix(i, features.maxEmgAmplitude) = max(data);
            end
            if features.minEmgAmplitude
                matrix(i, features.minEmgAmplitude) = min(data);
            end
            if features.meanEmgAmplitude
                matrix(i, features.meanEmgAmplitude) = mean(data);
            end
            if features.stdEmgAmplitude
                matrix(i, features.stdEmgAmplitude) = std(data);
            end
            if features.varEmgAmplitude
                matrix(i, features.varEmgAmplitude) = var(data);
            end
            if features.durationEmg
                matrix(i, features.durationEmg) = arousal.duration;
            end
        end
        
        if features.commonEegEvent
            commonStart = max(start1, start2);
            commonEnd = min(end1, end2);
            if commonStart < commonEnd
                matrix(i, features.commonEegEvent) = commonEnd - commonStart;
            end
        end
        
        if features.middleDiference    
            matrix(i, features.middleDiference) = abs(middle1 - middle2);
        end
        
        matrix(i, features.epochNum) = epochNum;
    end

    matrix(length(indexes) + 1:length(indexes) + length(missingEpochs), features.epochNum) = missingEpochs;
    matrix = sortrows(matrix, features.epochNum);    
    
    for pos = 1:size(matrix, 1)
        epochNum = matrix(pos, features.epochNum);
        
        if features.sleepStageW  && sleepStages.Signal(epochNum) == 0
            matrix(pos, features.sleepStageW) = 1;
        end
        if features.sleepStage1 && sleepStages.Signal(epochNum) == 1
            matrix(pos, features.sleepStage1) = 1;
        end
        if features.sleepStage2 && sleepStages.Signal(epochNum) == 2
            matrix(pos, features.sleepStage2) = 1; 
        end
        if features.sleepStage3 && sleepStages.Signal(epochNum) == 3
            matrix(pos, features.sleepStage3) = 1; 
        end
        if features.sleepStageR && sleepStages.Signal(epochNum) == 5
            matrix(pos, features.sleepStageR) = 1;
        end
        
        matrix(pos, features.isArousal) = anotatedArousals(epochNum) * 2 - 1;
    end   
    
    for i = 1:numEpochs
        idx = find(matrix(:, features.epochNum) == i);
        if length(idx) > 1
            [~, index] = max(matrix(idx, features.totalEmg) + matrix(idx, features.totalEmg + 1));
            
            idx(index) = [];
            matrix(idx, :) = zeros(size(matrix(idx, :)));
        end
    end
    
    matrix(~any(matrix, 2), :) = [];
end
