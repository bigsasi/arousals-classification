function ensemble = trainRandomForest(X, Y, searchBestConfig)

if ~searchBestConfig
    ensemble = fitensemble(X, Y, 'AdaBoostM1', 100, 'tree');
else
    totalData = length(X);
    partition = floor(totalData / 10);
    
    for size = 100:10:150
        error = zeros(1, 10);
        for k = 1:10
            partitionRange = (k - 1) * partition + 1:k * partition;
            trainRange = 1:totalData;
            trainRange(partitionRange) = [];
            
            X_train = X(trainRange, :);
            Y_train = Y(trainRange, :);

            ensemble = fitensemble(X_train, Y_train, 'AdaBoostM1', size, 'tree');
            
            X_test = X(partitionRange, :);
            Y_test = Y(partitionRange, :);
            
            predicted = predict(ensemble, X_test);
            expected = Y_test;
            
            error(k) = sum(predicted ~= expected) / length(predicted);
        end
        
        meanError = mean(error);
        stdError = std(error);
        fprintf('%d: %.3f (std: %.3f)\n', size, meanError, stdError);
    end
end