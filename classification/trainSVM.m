function model = trainSVM(X, Y, searchBestConfig)
    if ~searchBestConfig
        cost = 2 ^ 11;
        gamma = 2 ^ -3;

        X_train = X;
        Y_train = Y;
        model = fitcsvm(X_train, Y_train, 'KernelFunction', 'RBF', 'BoxConstraint', cost, 'KernelScale', gamma, 'Verbose', 0);
    else 
        costConfig = -11:2:11;
        gammaConfig = -11:2:11;
        totalData = length(X);
        partition = round(totalData/10);
        crossValidations = 10;
        
        for conf1 = costConfig
            for conf2 = gammaConfig
                totalSens = 0;
                totalSpec = 0;
                totalVp = 0;
                totalFp = 0;
                totalVn = 0;
                totalFn = 0;

                gamma = 2 ^ conf2;
                cost = 2 ^ conf1;
                for k = 1:crossValidations
                    trainDataRange = 1:totalData;
                    testDataRange = 1 + (k - 1) * partition: min(k * partition, totalData);
                    trainDataRange(testDataRange) = [];
                    X_train = X(trainDataRange, :);
                    Y_train = Y(trainDataRange, :);
                    X_test = X(testDataRange, :);
                    Y_test = Y(testDataRange, :);

                    model = fitcsvm(X_train, Y_train, 'KernelFunction', 'RBF', 'BoxConstraint', cost, 'KernelScale', gamma, 'Verbose', 0);

                    methodResult = predict(model, X_test);

                    [sens, spec, ~, tp, fp, tn, fn, ~] = sensitivitySpecificityError(methodResult, Y_test, [-1 1]);
                    totalSpec = totalSpec + spec(2);
                    totalSens = totalSens + sens(2);
                    totalVp = totalVp + tp(2);
                    totalFp = totalFp + fp(2);
                    totalVn = totalVn + tn(2);
                    totalFn = totalFn + fn(2);
                end
                fprintf('Config: gamma: %s (%f) cost: %s (%f)\n', num2str(gamma), conf2, num2str(cost), conf1);
                totalSens = totalSens / crossValidations;
                totalSpec = totalSpec / crossValidations;
                totalVp = totalVp / crossValidations;
                totalFp = totalFp / crossValidations;
                totalVn = totalVn / crossValidations;
                totalFn = totalFn / crossValidations;
                printMeasures(totalSens, totalSpec, totalVp, totalFp, totalVn, totalFn);
            end
        end
    end  
end
