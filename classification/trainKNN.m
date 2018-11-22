function mdl = trainKNN(X, Y, searchBestConfig)

if ~searchBestConfig
    mdl = fitcknn(X, Y, 'Distance', 'spearman', 'NumNeighbors', 5);
else
    totalData = length(X);
    partition = floor(totalData / 10);

    distance = {'spearman'};
    numNeighbors = 5:10;
    
    for i = 1:length(distance);
        for j = 1:length(numNeighbors)
            error = zeros(1, 10);

            for k = 1:10
                partitionRange = (k - 1) * partition + 1:k * partition;
                trainRange = 1:totalData;
                trainRange(partitionRange) = [];

                X_train = X(trainRange, :);
                Y_train = Y(trainRange, :);
                mdl = fitcknn(X_train, Y_train, 'Distance', distance{i}, 'NumNeighbors', numNeighbors(j));

                X_test = X(partitionRange, :);
                Y_test = Y(partitionRange, :);
                predicted = predict(mdl, X_test);
                expected = Y_test;

                error(k) = sum(predicted ~= expected) / length(predicted);
            end

            meanError = mean(error);
            stdError = std(error);
            fprintf('%s %d: %.3f (std: %.3f)\n', distance{i}, numNeighbors(j), meanError, stdError);
        end
    end
end