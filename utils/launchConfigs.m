totalFiles = 50; % 50
trainFiles = 25; % 40
Output.MUTE;

printDataToFile = 0;

searchBestConfig = 0;

dataScaling = 1;

onlyUsePrecalculatedData = 0;

saveFiles = 1;

% If files exist, but you want new ones. If they don't exist, system is going to
% train and create clas matrix, no matter the values here. 
trainAgain = 1;
redoClasMatrix = 1;

config = Configuration.getInstance;
features = Features.getInstance;

config.setValue('arousalThreshold', 1);
config.setValue('arousalAlphaThreshold', 2);
config.setValue('arousalThetaThreshold', 2);

% configValues.arousalThreshold = 1:0.02:1.2;
clear configValues
% configValues.arousalThreshold = 1:0.1:2;
% configValues.arousalMinDuration = [3 4];
% configValues.thresholdSmoothing = [0.8];

configValues.arousalThreshold = 1.1;
configValues.arousalMinDuration = 3;
configValues.thresholdSmoothing = 1;


%% Generate configuration matrix 

tic
tmp = fieldnames(configValues);
fields{length(tmp)} = char(tmp(end));
for i = 1:length(fields) - 1;
   fields{i} = char(tmp(i)); 
end

totalConfigs = 1;
for i = 1:length(fields)
    totalConfigs = totalConfigs * length(configValues.(fields{i}));
end

configMatrix = zeros(totalConfigs, length(fields));
lastRep = 1;
for i = 1:length(fields)
    for j = 1:length(configValues.(fields{i})) * lastRep:totalConfigs
        for k = 0:length(configValues.(fields{i})) - 1
            configMatrix(j + k * lastRep:j + k * lastRep + lastRep - 1, i) = configValues.(fields{i})(k + 1);
        end
    end
    lastRep = lastRep * length(configValues.(fields{i}));
end

%% Find EDF Files

edfPath = '/home/sasi/SHHS/';
annotationsPath = '/home/sasi/SHHS/annotations/';

if (sum(edfPath) == 0), return; end
files = dir(edfPath);

clear multiF
edfNames{totalFiles} = '';
edfFiles{totalFiles} = '';
edfPlusFiles{totalFiles} = '';

i = 1;
for k = 1:length(files)
    if regexpi(files(k).name, '200\d*(.edf)$')
        edfName = files(k).name;
        
        xmlName = strcat(edfName, '.xml');
        
        edfPlusFile = fullfile(annotationsPath, xmlName);
        if ~exist(edfPlusFile, 'file')
            Output.INFO('Annotations file: %s not found\n', edfPlusFile);
            continue
        end
        edfNames{i} = edfName;
        edfFiles{i} = fullfile(edfPath, edfName);
        edfPlusFiles{i} = edfPlusFile;
        i = i + 1;
        if i > totalFiles, break; end
    end
end

%% Launch study Arousals

for configIndex = 1:totalConfigs
    fprintf('Configuration: \n');
    for i = 1:length(fields)
        config.setValue(fields{i}, configMatrix(configIndex, i));
        fprintf('    %s: %f\n', fields{i}, configMatrix(configIndex, i));
    end
    fprintf('\n');
    
    sens = 0; 
    spec = 0;
    
    configPath = ['storedResults/' DataHash(config.getConfCell) '/'];
    
    if ~exist(configPath, 'dir')
        if onlyUsePrecalculatedData
            fprintf('Previous data not found, skipping\n');
            continue
        else
            mkdir(configPath);
        end
    end
    
    fprintf ('Without classification\n');
    allStats = cell(totalFiles, 1);
    for k = 1:totalFiles
        edfName = char(edfNames(k));
      
        FStats = [edfName '-stats.mat'];
        FArousals = [edfName '-arousalsDetection.mat'];
        FClasMatrix = [edfName '-classificationMatrix.mat'];
        
        if exist([configPath FStats], 'file')
            copyfile([configPath FArousals], 'lastArousalDetection.mat');
            load([configPath FStats], 'stats');
        else 
            if exist(['storedResults/' edfName '-sleepStages.mat'], 'file')
                copyfile(['storedResults/' edfName '-sleepStages.mat'], 'sleepStages.tmp.mat');
            else
                delete('sleepStages.tmp.mat');
            end
            stats = studyFile(edfFiles{k}, edfPlusFiles{k});
            if ~exist(['storedResults/' edfName '-sleepStages.mat'], 'file')
                copyfile('sleepStages.tmp.mat', ['storedResults/' edfName '-sleepStages.mat']);
            end
        end
        
        if saveFiles && ~exist([configPath FStats], 'file')
            [status, message] = copyfile('lastArousalDetection.mat', [configPath FArousals]);
            save([configPath FStats], '-v6', 'stats');
        end
        
        sens = sens + stats.sens(2);
        spec = spec + stats.spec(2);
               
        if redoClasMatrix
            delete([configPath FClasMatrix]);
        end

        if exist([configPath FClasMatrix], 'file')
            load([configPath FClasMatrix], 'clasMatrix');
        else
            clasMatrix = classificationMatrix(stats.annotatedArousalsEpoch);
            save([configPath FClasMatrix], 'clasMatrix');
        end
        stats.clasMatrix = clasMatrix;
        allStats{k} = stats;
    end
    
    fprintf('\n[Sensitivity, Specifity] = [%f, %f]\n\n', sens / totalFiles, spec / totalFiles);
    
    
    totalDataSize = 0;
    trainDataSize = 0;
    for i = 1:totalFiles
        totalDataSize = totalDataSize + length(allStats{i}.clasMatrix);
        if i == trainFiles, trainDataSize = totalDataSize; end
    end
    testDataSize = totalDataSize - trainDataSize;
    
    totalData = zeros(totalDataSize, size(allStats{1}.clasMatrix, 2));
    position = 1;
    for i = 1:totalFiles
        last = position + length(allStats{i}.clasMatrix) - 1;
        totalData(position:last, :) = allStats{i}.clasMatrix;
        position = last + 1;
    end
    trainDataRange = 1:trainDataSize;
    testDataRange = trainDataSize + 1:totalDataSize;
    
    %% Max possible sensitivity && min specifity
    trainData = totalData(trainDataRange, :);
    positiveArousal = find(trainData(:, features.isArousal) == 1);
    negativeArousal = find(trainData(:, features.isArousal) == -1);

    possibleArousal = find(trainData(:, features.duration) ~= 0);
    sureNonArousal = find(trainData(:, features.duration) == 0);

    maxSens = sum(ismember(possibleArousal, positiveArousal)) / length(positiveArousal);
    minSpec = sum(ismember(sureNonArousal, negativeArousal)) / length(negativeArousal);

    fprintf('Max Sensitivity: %f\n', maxSens);
    fprintf('Min Specificity: %f\n\n', minSpec);

    %% Equilibrate positive & negative 
    s = RandStream('mt19937ar','Seed',1);
    RandStream.setGlobalStream(s);
    
    newNegativeIndex = negativeArousal(randperm(length(negativeArousal)));
    newNegativeIndex = newNegativeIndex(1:length(positiveArousal));
    negativeData = trainData(newNegativeIndex, :);
    positiveData = trainData(positiveArousal, :);

    trainData = [negativeData; positiveData];
    trainData = trainData(randperm(length(trainData)), :);
    testData = totalData(testDataRange, :);

    %% Normalize data
    if dataScaling
        trainDataMin = min(totalData);
        trainDataMax = max(totalData);
        for i = features.getDataScalingRange
            totalData(:, i) = (totalData(:, i) - trainDataMin(i)) / (trainDataMax(i) - trainDataMin(i));
        end
    end

    %% Train & test
    if ~exist([configPath 'classifiersObjects.mat'], 'file') || trainAgain
        [classifyInput, classifyInputLabel] = trainDiscriminant(trainData);

        [svm, net, tree, mdl, bayes, rf, knne] = trainClassifiers(trainData(:, features.getInputRange), trainData(:, features.isArousal), searchBestConfig);

        scalingData.min = trainDataMin;
        scalingData.max = trainDataMax;
        save([configPath 'classifiersObjects.mat'], 'svm', 'net', 'tree', 'mdl', 'bayes', 'rf', 'knne', 'classifyInput', 'classifyInputLabel', 'scalingData'); 
    else
        features = Features.getInstance;

        load([configPath 'classifiersObjects.mat'], 'svm', 'net', 'tree', 'mdl', 'bayes', 'rf', 'knne', 'classifyInput', 'classifyInputLabel', 'scalingData');
    end

    inputDataIndex = features.getInputRange;

    fprintf('With Training set:\n');

    expertResult = trainData(:, features.isArousal);

    classifyAndResults(trainData(:, inputDataIndex), expertResult, classifyInput, classifyInputLabel, svm, net, tree, mdl, bayes, rf, knne);

    fprintf('With Test set:\n');

    expertResult = testData(:, features.isArousal);

    classifyAndResults(testData(:, inputDataIndex), expertResult, classifyInput, classifyInputLabel, svm, net, tree, mdl, bayes, rf, knne);

    fprintf('SHHS-26 test\n');
        
    allfiles = {'200088.edf', '200259.edf', '200386.edf', '200532.edf',...
        '200568.edf', '200929.edf', '201249.edf', '201294.edf', '201394.edf', ...
        '201824.edf', '202275.edf', '202666.edf', '202733.edf', '202956.edf', ...
        '203249.edf', '203294.edf', '203494.edf', '203645.edf', '203798.edf', ...
        '204135.edf', '204452.edf', '204480.edf', '205813.edf', '205948.edf', ...
        '206040.edf', '206181.edf'}; 

    classifyFile(allfiles, edfPath, annotationsPath);
end
toc
