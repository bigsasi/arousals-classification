function tree = trainClassificationTree(X, Y, searchBestConfig)

if ~searchBestConfig
    tree = fitctree(X, Y);
    tree = prune(tree, 'Level', 15);
else
    conf(1).name = 'Prune';
    conf(1).data = 1:25;
    
    totalData = length(X);
    partition = floor(totalData / 10);
    
    for i = 1:length(conf(1).data)        
        error = zeros(1, 10);
    
        for fold = 1:10
            partitionRange = (fold - 1) * partition + 1:fold * partition;
            trainRange = 1:totalData;
            trainRange(partitionRange) = [];
            
            X_train = X(trainRange, :);
            Y_train = Y(trainRange, :);

            tree = fitctree(X_train, Y_train);
            tree = prune(tree, 'Level', conf(1).data(i));
            
            X_test = X(partitionRange, :);
            Y_test = Y(partitionRange, :);
            predicted = predict(tree, X_test);
            expected = Y_test;
            
            error(fold) = sum(predicted ~= expected) / length(predicted);
        end
        
        meanError = mean(error);
        stdError = std(error);
        fprintf(' %d: %.3f (std: %.3f)\n',conf(1).data(i), meanError, stdError);
    end
end