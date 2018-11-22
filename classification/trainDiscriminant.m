function [classifyInput, classifyInputLabel] = trainDiscriminant(trainData)

    features = Features.getInstance;

    inputDataIndex = features.getInputRange;

    classifyInput = trainData(:, inputDataIndex);
    classifyInputLabel = trainData(:, features.isArousal);
end
