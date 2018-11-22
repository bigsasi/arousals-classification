function net = trainANN(X, Y, searchBestConfig)

if ~searchBestConfig
    firstLayerConf = 40;
    
    myRNAnet = newff(X', Y', firstLayerConf);
    myRNAnet.trainFcn = 'trainscg';
    myRNAnet.trainParam.epochs = 10000;
    myRNAnet.trainParam.show = NaN;
    myRNAnet.trainParam.goal = .0001;
    myRNAnet.trainParam.max_fail = 100;
    myRNAnet.divideParam.trainRatio = 0.8;
    myRNAnet.divideParam.valRatio = 0.2;
    myRNAnet.divideParam.testRatio = 0;

    [net, ~, ~, ~, ~, ~] = train(myRNAnet, X', Y');
else
    firstLayerConf = 2 .^ (1:8);
    dataLength = length(X);
    partition = round(dataLength/10);
    crossValidations = 10;
    
    for h1 = firstLayerConf
        totalSens = 0;
        totalSpec = 0;
        totalVp = 0;
        totalFp = 0;
        totalVn = 0;
        totalFn = 0;
        for k = 1:crossValidations
            trainDataRange = 1:dataLength;
            testDataRange = 1 + (k - 1) * partition: min(k * partition, dataLength);
            trainDataRange(testDataRange) = [];
            X_train = X(trainDataRange, :);
            Y_train = Y(trainDataRange, :);
            X_test = X(testDataRange, :);
            Y_test = Y(testDataRange, :);

            myRNAnet = newff(X_train', Y_train', h1);
            myRNAnet.trainFcn = 'trainscg';
            myRNAnet.trainParam.epochs = 10000;
            myRNAnet.trainParam.show = NaN;
            myRNAnet.trainParam.goal = .0001;
            myRNAnet.trainParam.max_fail = 100;
            myRNAnet.divideParam.trainRatio = 0.8;
            myRNAnet.divideParam.valRatio = 0.2;
            myRNAnet.divideParam.testRatio = 0;

            [net, ~, ~, ~, ~, ~] = train(myRNAnet, X_train', Y_train');

            netResult = simAndNormalize(net, X_test', Y_test);

            [sens, spec, ~, tp, fp, tn, fn, ~] = sensitivitySpecificityError(netResult, Y_test, [-1 1]);
            totalSpec = totalSpec + spec(2);
            totalSens = totalSens + sens(2);
            totalVp = totalVp + tp(2);
            totalFp = totalFp + fp(2);
            totalVn = totalVn + tn(2);
            totalFn = totalFn + fn(2);
        end

        fprintf('Config: %d %d \n', h1, h2);
        totalSens = totalSens / crossValidations;
        totalSpec = totalSpec / crossValidations;
        totalVp = totalVp / crossValidations;
        totalFp = totalFp / crossValidations;
        totalVn = totalVn / crossValidations;
        totalFn = totalFn / crossValidations;
        printMeasures(totalSens, totalSpec, totalVp, totalFp, totalVn, totalFn);
    end
end



