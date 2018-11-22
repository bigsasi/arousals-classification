function classifyFile(edfNames, edfPath, edfPlusPath)
    w1 = 0.7;
    config = Configuration.getInstance;
    configPath = ['storedResults/' DataHash(config.getConfCell) '/'];
    
    %% Load classification objects
    features = Features.getInstance;
    load([configPath 'classifiersObjects.mat']);

    inputDataIndex = features.getInputRange;

    %% Load file
    total = struct;
    
    for i = -9:9
        if i < 0
            name = ['Asocm' num2str(-i)];
        else
            name = ['Asoc' num2str(i)];
        end
        total = initializeStats(name, total);
    end
    
    for i = -9:9
        if i < 0
            name = ['Linearm' num2str(-i)];
        else
            name = ['Linear' num2str(i)];
        end
        total = initializeStats(name, total);
    end

    total = initializeStats('FIS', total);
    total = initializeStats('ANN', total);
    total = initializeStats('SVM', total);
    total = initializeStats('Tree', total);
    total = initializeStats('kNN', total);
    total = initializeStats('Bayes', total);
    total = initializeStats('RF', total);    
    total = initializeStats('KNNE', total);

    s = RandStream('mt19937ar','Seed',1);
    RandStream.setGlobalStream(s);
            
    for fileIndex = 1:length(edfNames)
        fileName = char(edfNames{fileIndex});

        clear stats

        FStats = [fileName '-stats.mat'];
        FArousals = [fileName '-arousalsDetection.mat'];
        FClasMatrix = [fileName '-classificationMatrix.mat'];
        
        if exist([configPath FStats], 'file')
            copyfile([configPath FArousals], 'lastArousalDetection.mat');
            load([configPath FStats], 'stats');
        else 
            if exist(['storedResults/' fileName '-sleepStages.mat'], 'file')
                copyfile(['storedResults/' fileName '-sleepStages.mat'], 'sleepStages.tmp.mat');
            else
                delete('sleepStages.tmp.mat');
            end
            
            xmlName = strcat(fileName, '.xml');

            edfPlusFile = fullfile(edfPlusPath, xmlName);
            if ~exist(edfPlusFile, 'file')
                Output.INFO('Annotations file: %s not found\n', edfPlusFile);
            end
            edfFile = fullfile(edfPath, fileName);
            
            stats = studyFile(edfFile, edfPlusFile);
            if ~exist(['storedResults/' fileName '-sleepStages.mat'], 'file')
                copyfile('sleepStages.tmp.mat', ['storedResults/' fileName '-sleepStages.mat']);
            end
        end
        
        if ~exist([configPath FStats], 'file')
            [~, ~] = copyfile('lastArousalDetection.mat', [configPath FArousals]);
            save([configPath FStats], '-v6', 'stats');
        end

        if exist([configPath FClasMatrix], 'file')
            load([configPath FClasMatrix], 'clasMatrix');
            testDataTmp = clasMatrix;
        else
            testDataTmp = classificationMatrix(stats.annotatedArousalsEpoch);
            clasMatrix = testDataTmp;
            save([configPath FClasMatrix], 'clasMatrix');
        end

        for i = features.getDataScalingRange
            testDataTmp(:, i) = (testDataTmp(:, i) - scalingData.min(i)) / (scalingData.max(i) - scalingData.min(i));
        end
        testData = testDataTmp;
        
        expertResult = testData(:, features.isArousal);

        %% Classification      
        [outputANN, rawANN] = simAndNormalize(net, testData(:, inputDataIndex)', expertResult);
 
        [outputFisher, ~, ~, ~, ~] = classify(testData(:, inputDataIndex), classifyInput, classifyInputLabel, 'diagLinear');
        outputSVM = predict(svm, testData(:, inputDataIndex));
        outputTree = predict(tree, testData(:, inputDataIndex));
        outputKNN = predict(mdl, testData(:, inputDataIndex));
        outputBay = predict(bayes, testData(:, inputDataIndex));
        outputRF = predict(rf, testData(:, inputDataIndex)); 
        outputKNNE = predict(knne, testData(:, inputDataIndex));

        oTree = outputTree;
        oKNN = outputKNN;
        oSVM = outputSVM;
        oANN = rawANN;
        
        shortComb = combineEvidences(oANN, oSVM * w1, 1, 1);
        shortComb = combineEvidences(shortComb, oTree * w1, 1, 1);
        shortComb = combineEvidences(shortComb, oKNN * w1, 1, 1);

        linearComb = 0.25 * oANN + 0.25 * oSVM + 0.25 * oTree + 0.25 * oKNN;
        
        for i = -9:9
            threshold = i / 10;
            if threshold < 0
                name = ['Asocm' num2str(-i)];
            else
                name = ['Asoc' num2str(i)];
            end
            output = applyThreshold(shortComb, threshold);
            fileStats = modelStats(output, expertResult);
            total = addToGlobalStats(name, fileStats, total);
        end
        
        for i = -9:9
            threshold = i / 10;
            if threshold < 0
                name = ['Linearm' num2str(-i)];
            else
                name = ['Linear' num2str(i)];
            end
            
            output = applyThreshold(linearComb, threshold);
            fileStats = modelStats(output, expertResult);
            total = addToGlobalStats(name, fileStats, total);
        end 

        %% Print data
        
        name = 'FIS';
        fileStats = modelStats(outputFisher, expertResult);
        total = addToGlobalStats(name, fileStats, total);

        name = 'SVM';
        fileStats = modelStats(outputSVM, expertResult);
        total = addToGlobalStats(name, fileStats, total);
        
        name = 'ANN';
        fileStats = modelStats(outputANN, expertResult);
        total = addToGlobalStats(name, fileStats, total);
        
        name = 'Tree';    
        fileStats = modelStats(outputTree, expertResult);
        total = addToGlobalStats(name, fileStats, total);
        
        name = 'kNN';
        fileStats = modelStats(outputKNN, expertResult);
        total = addToGlobalStats(name, fileStats, total);

        name = 'Bayes';
        fileStats = modelStats(outputBay, expertResult);
        total = addToGlobalStats(name, fileStats, total);
                
        name = 'RF';
        fileStats = modelStats(outputRF, expertResult);
        total = addToGlobalStats(name, fileStats, total);
        
        name = 'KNNE';
        fileStats = modelStats(outputKNNE, expertResult);
        total = addToGlobalStats(name, fileStats, total);
    end
    
    fprintf('Total files: %d\n', length(edfNames));
    printAverages(total, length(edfNames));
end

function globalStats = addToGlobalStats(name, fileStats, globalStats)
    globalStats.(name).tp = globalStats.(name).tp + fileStats.tp;
    globalStats.(name).fp = globalStats.(name).fp + fileStats.fp;
    globalStats.(name).tn = globalStats.(name).tn + fileStats.tn;
    globalStats.(name).fn = globalStats.(name).fn + fileStats.fn;
    globalStats.(name).ai = globalStats.(name).ai + fileStats.ai;
    globalStats.(name).sens = globalStats.(name).sens + fileStats.sens;
    globalStats.(name).spec = globalStats.(name).spec + fileStats.spec;
end

function stats = modelStats(modelResult, expertResult)
    [sens, spec, ~, tp, fp, tn, fn, ~] = ...
        sensitivitySpecificityError(modelResult, expertResult, [-1 1]);
    
    stats.tp = tp(2);
    stats.fp = fp(2);
    stats.tn = tn(2);
    stats.fn = fn(2);
    stats.ai = (tp(2) + tn(2)) / (tp(2) + fp(2) + tn(2) + fn(2));
    stats.sens = sens(2);
    stats.spec = spec(2);
end

function struct = initializeStats(name, struct)
    struct.(name).tp = 0;
    struct.(name).fp = 0;
    struct.(name).tn = 0;
    struct.(name).fn = 0;
    struct.(name).ai = 0;
    struct.(name).sens = 0;
    struct.(name).spec = 0;
end

function printAverages(total, n)
    for i = -9:9
        if i < 0
            name = ['Asocm' num2str(-i)];
        else
            name = ['Asoc' num2str(i)];
        end
        printResults2(name, total, n);
    end
    
    for i = -9:9
        if i < 0
            name = ['Linearm' num2str(-i)];
        else
            name = ['Linear' num2str(i)];
        end
        printResults2(name, total, n);
    end

    printResults2('FIS', total, n);
    printResults2('SVM', total, n);
    printResults2('ANN', total, n);
    printResults2('Tree', total, n);
    printResults2('kNN', total, n);
    printResults2('Bayes', total, n);
    printResults2('RF', total, n);
    printResults2('KNNE', total, n);
end

function printResults2(name, total, n) 
    ai = total.(name).ai / n;
    error = 1 - ai;
    sens = total.(name).sens / n;
    spec = total.(name).spec / n;
    auc = (sens + spec) / 2;
    
    fprintf('%s AVG: \t %.3f \t %.3f \t %.3f \t %.3f', name, error, sens, spec, auc);
    
    tp = total.(name).tp;
    fp = total.(name).fp;
    tn = total.(name).tn;
    fn = total.(name).fn;
    ia = (tp + tn) / (tp + fp + tn + fn);
    error = 1 - ia;
    sens = tp / (tp + fn);
    spec = tn / (tn + fp);
    auc = (sens + spec) / 2;
    
    fprintf('\t ALL: \t %.3f \t %.3f \t %.3f \t %.3f\n', error, sens, spec, auc);
end

function output  = applyThreshold(input, threshold)
    output = input;
    output(input > threshold) = 1;
    output(~(input > threshold)) = -1;
end

function combination = combineEvidences(evidence1, evidence2, weight1, weight2)
        combination = evidence1;
        evidence1 = evidence1 * weight1;
        evidence2 = evidence2 * weight2;
        index = evidence1 > 0 & evidence2 > 0;
        combination(index) = evidence1(index) + evidence2(index) - evidence1(index) .* evidence2(index);
        index = evidence1 < 0 & evidence2 < 0;
        combination(index) = evidence1(index) + evidence2(index) + evidence1(index) .* evidence2(index);
        index = evidence1 .* evidence2 < 0;
        combination(index) = (evidence1(index) + evidence2(index)) ./ (1 - min(abs(evidence1(index)), abs(evidence2(index))));
end