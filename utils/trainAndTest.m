totalFiles = 2;
trainFiles = 1;
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
sens = 0; 
spec = 0;

configPath = ['storedResults/' DataHash(config.getConfCell) '/'];

if ~exist(configPath, 'dir')
    if onlyUsePrecalculatedData
        fprintf('Previous data not found, skipping\n');
        return
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

%% Normalize data
if dataScaling
    totalDataMin = min(totalData);
    totalDataMax = max(totalData);
    for i = features.getDataScalingRange
        totalData(:, i) = (totalData(:, i) - totalDataMin(i)) / (totalDataMax(i) - totalDataMin(i));
    end
end

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

%% Train & test

if ~exist([configPath 'classifiersObjects.mat'], 'file')
    trainAgain = 1;
end
if searchBestConfig || trainAgain
    [classifyInput, classifyInputLabel] = trainDiscriminant(trainData);

    svm = trainSVM(trainData, searchBestConfig);

    net = trainANN(trainData, searchBestConfig);

    tree = trainClassificationTree(trainData, searchBestConfig);

    mdl = trainKNN(trainData, searchBestConfig);

    bayes = trainBayes(trainData, searchBestConfig);

    rf = trainRandomForest(trainData, searchBestConfig);

    knne = trainKNNEnsemble(trainData, searchBestConfig);

    scalingData.min = totalDataMin;
    scalingData.max = totalDataMax;
    save([configPath 'classifiersObjects.mat'], 'svm', 'net', 'tree', 'mdl', 'bayes', 'rf', 'knne', 'classifyInput', 'classifyInputLabel', 'scalingData'); 
else
    features = Features.getInstance;

    load([configPath 'classifiersObjects.mat'], 'svm', 'net', 'tree', 'mdl', 'bayes', 'rf', 'knne', 'classifyInput', 'classifyInputLabel', 'scalingData');
end

inputDataIndex = features.getInputRange;

fprintf('With TR:\n');

expertResult = trainData(:, features.isArousal);

[outputFisher, ~, ~, ~, ~] = classify(trainData(:, inputDataIndex), classifyInput, classifyInputLabel, 'diagLinear');

outputSVM = predict(svm, trainData(:, inputDataIndex));

[outputANN, ~] = simAndNormalize(net, trainData(:, inputDataIndex)', expertResult);

outputTree = predict(tree, trainData(:, inputDataIndex));

outputKNN = predict(mdl, trainData(:, inputDataIndex));

outputBay = predict(bayes, trainData(:, inputDataIndex));

outputRF = predict(rf, trainData(:, inputDataIndex));

outputKNNE = predict(knne, trainData(:, inputDataIndex));

[sensFis, specFis, ~, tpFis, fpFis, tnFis, fnFis] = ...
    sensitivitySpecificityError(outputFisher, expertResult, [-1 1]);

[sensSVM, specSVM, ~, tpSVM, fpSVM, tnSVM, fnSVM] = ...
    sensitivitySpecificityError(outputSVM, expertResult, [-1 1]);

[sensANN, specANN, ~, tpANN, fpANN, tnANN, fnANN] = ...
    sensitivitySpecificityError(outputANN, expertResult, [-1 1]);

[sensTree, specTree, ~, tpTree, fpTree, tnTree, fnTree] = ...
    sensitivitySpecificityError(outputTree, expertResult, [-1 1]);

[sensKNN, specKNN, ~, tpKNN, fpKNN, tnKNN, fnKNN] = ...
    sensitivitySpecificityError(outputKNN, expertResult, [-1 1]);

[sensBay, specBay, ~, tpBay, fpBay, tnBay, fnBay] = ...
    sensitivitySpecificityError(outputBay, expertResult, [-1 1]);     

[sensRF, specRF, ~, tpRF, fpRF, tnRF, fnRF] = ...
    sensitivitySpecificityError(outputRF, expertResult, [-1 1]);

[sensKNNE, specKNNE, ~, tpKNNE, fpKNNE, tnKNNE, fnKNNE] = ...
    sensitivitySpecificityError(outputKNNE, expertResult, [-1 1]);

fprintf('Fisher\n');
printMeasures(sensFis(2), specFis(2), tpFis(2), fpFis(2), tnFis(2), fnFis(2));

fprintf('SVM\n');
printMeasures(sensSVM(2), specSVM(2), tpSVM(2), fpSVM(2), tnSVM(2), fnSVM(2));

fprintf('ANN\n');
printMeasures(sensANN(2), specANN(2), tpANN(2), fpANN(2), tnANN(2), fnANN(2));

fprintf('Tree\n');
printMeasures(sensTree(2), specTree(2), tpTree(2), fpTree(2), tnTree(2), fnTree(2));

fprintf('KNN\n');
printMeasures(sensKNN(2), specKNN(2), tpKNN(2), fpKNN(2), tnKNN(2), fnKNN(2));

fprintf('Bayes\n');
printMeasures(sensBay(2), specBay(2), tpBay(2), fpBay(2), tnBay(2), fnBay(2));

fprintf('RF\n');
printMeasures(sensRF(2), specRF(2), tpRF(2), fpRF(2), tnRF(2), fnRF(2));

fprintf('KNNE\n');
printMeasures(sensKNNE(2), specKNNE(2), tpKNNE(2), fpKNNE(2), tnKNNE(2), fnKNNE(2));

fprintf('With TS:\n');

expertResult = testData(:, features.isArousal);

[outputFisher, ~, ~, ~, ~] = classify(testData(:, inputDataIndex), classifyInput, classifyInputLabel, 'diagLinear');

outputSVM = predict(svm, testData(:, inputDataIndex));

[outputANN, ~] = simAndNormalize(net, testData(:, inputDataIndex)', expertResult);

outputTree = predict(tree, testData(:, inputDataIndex));

outputKNN = predict(mdl, testData(:, inputDataIndex));

outputBay = predict(bayes, testData(:, inputDataIndex));

outputRF = predict(rf, testData(:, inputDataIndex));

outputKNNE = predict(knne, testData(:, inputDataIndex));

[sensFis, specFis, ~, tpFis, fpFis, tnFis, fnFis] = ...
    sensitivitySpecificityError(outputFisher, expertResult, [-1 1]);

[sensSVM, specSVM, ~, tpSVM, fpSVM, tnSVM, fnSVM] = ...
    sensitivitySpecificityError(outputSVM, expertResult, [-1 1]);

[sensANN, specANN, ~, tpANN, fpANN, tnANN, fnANN] = ...
    sensitivitySpecificityError(outputANN, expertResult, [-1 1]);

[sensTree, specTree, ~, tpTree, fpTree, tnTree, fnTree] = ...
    sensitivitySpecificityError(outputTree, expertResult, [-1 1]);

[sensKNN, specKNN, ~, tpKNN, fpKNN, tnKNN, fnKNN] = ...
    sensitivitySpecificityError(outputKNN, expertResult, [-1 1]);

[sensBay, specBay, ~, tpBay, fpBay, tnBay, fnBay] = ...
    sensitivitySpecificityError(outputBay, expertResult, [-1 1]);   

[sensRF, specRF, ~, tpRF, fpRF, tnRF, fnRF] = ...
    sensitivitySpecificityError(outputRF, expertResult, [-1 1]);

[sensKNNE, specKNNE, ~, tpKNNE, fpKNNE, tnKNNE, fnKNNE] = ...
    sensitivitySpecificityError(outputKNNE, expertResult, [-1 1]);        

fprintf('Fisher\n');
printMeasures(sensFis(2), specFis(2), tpFis(2), fpFis(2), tnFis(2), fnFis(2));

fprintf('SVM\n');
printMeasures(sensSVM(2), specSVM(2), tpSVM(2), fpSVM(2), tnSVM(2), fnSVM(2));

fprintf('ANN\n');
printMeasures(sensANN(2), specANN(2), tpANN(2), fpANN(2), tnANN(2), fnANN(2));

fprintf('Tree\n');
printMeasures(sensTree(2), specTree(2), tpTree(2), fpTree(2), tnTree(2), fnTree(2));

fprintf('KNN\n');
printMeasures(sensKNN(2), specKNN(2), tpKNN(2), fpKNN(2), tnKNN(2), fnKNN(2));

fprintf('Bayes\n');
printMeasures(sensBay(2), specBay(2), tpBay(2), fpBay(2), tnBay(2), fnBay(2));      

fprintf('RF\n');
printMeasures(sensRF(2), specRF(2), tpRF(2), fpRF(2), tnRF(2), fnRF(2));

fprintf('KNNE\n');
printMeasures(sensKNNE(2), specKNNE(2), tpKNNE(2), fpKNNE(2), tnKNNE(2), fnKNNE(2));