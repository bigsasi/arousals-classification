function ensemble = trainKNNEnsemble(X, Y, searchBestConfig)

if ~searchBestConfig
    t = templateKNN('NumNeighbors', 4);
    ensemble = fitensemble(X, Y, 'subspace', 20, t);
else    
    totalData = length(X);
    partition = floor(totalData / 10);
    
    for size = 4:2:30
        for neighbors = 4
        error = zeros(1, 10);
        for k = 1:10
            partitionRange = (k - 1) * partition + 1:k * partition;
            trainRange = 1:totalData;
            trainRange(partitionRange) = [];

            X_train = X(trainRange, :);
            Y_train = Y(trainRange, :);
            
            t = templateKNN('NumNeighbors', neighbors);
            ensemble = fitensemble(X_train, Y_train, 'subspace', size, t);
            
            X_test = X(partitionRange, :);
            Y_test = Y(partitionRange, :);
            
            predicted = predict(ensemble, X_test);
            expected = Y_test;

            
            error(k) = sum(predicted ~= expected) / length(predicted);
        end
        
        meanError = mean(error);
        stdError = std(error);
        fprintf('%d - %d: %.3f (std: %.3f)\n', size, neighbors, meanError, stdError);
        end  
    end
end