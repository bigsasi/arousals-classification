function [svm, net, tree, mdl, bayes, rf, knne] = trainClassifiers(x, y, searchBestConfig)
%TRAINCLASSIFIERS Summary of this function goes here
%   Detailed explanation goes here
    svm = trainSVM(x, y, searchBestConfig);

    net = trainANN(x, y, searchBestConfig);

    tree = trainClassificationTree(x, y, searchBestConfig);

    mdl = trainKNN(x, y, searchBestConfig);

    bayes = trainBayes(x, y, searchBestConfig);

    rf = trainRandomForest(x, y, searchBestConfig);

    knne = trainKNNEnsemble(x, y, searchBestConfig);
end

