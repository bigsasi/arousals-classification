function bayes = trainBayes(X, Y, searchBestConfig)

if ~searchBestConfig
    bayes = fitcnb(X, Y, 'DistributionNames', 'kernel', 'Kernel', 'normal');
else
    possibleKernel = {'box', 'epanechnikov', 'normal', 'triangle'};
    
    totalData = length(X);
    partition = floor(totalData / 10);
    
    for j = 1:length(possibleKernel)
            
        error = zeros(1, 10);
    
        for k = 1:10
            partitionRange = (k - 1) * partition + 1:k * partition;
            trainRange = 1:totalData;
            trainRange(partitionRange) = [];
            
            X_train = X(trainRange, :);
            Y_train = Y(trainRange, :);
            bayes = fitcnb(X_train, Y_train, 'DistributionNames', 'kernel', 'Kernel', possibleKernel{j});
            
            X_test = X(partitionRange, :);
            Y_test = Y(partitionRange, :);
            predicted = predict(bayes, X_test);
            expected = Y_test;

            error(k) = sum(predicted ~= expected) / length(predicted);
        end
        
        meanError = mean(error);
        stdError = std(error);
        fprintf('%s: %.3f (std: %.3f)\n', possibleKernel{j}, meanError, stdError);
        
   end
end