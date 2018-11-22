function classifyAndResults(x_test, y_test, classifyInput, classifyInputLabel, svm, net, tree, mdl, bayes, rf, knne)
%CLASSIFYANDRESULT Summary of this function goes here
%   Detailed explanation goes here
    [outputFisher, ~, ~, ~, ~] = classify(x_test, classifyInput, classifyInputLabel, 'diagLinear');

    outputSVM = predict(svm, x_test);

    [outputANN, ~] = simAndNormalize(net, x_test', y_test);

    outputTree = predict(tree, x_test);

    outputKNN = predict(mdl, x_test);

    outputBay = predict(bayes, x_test);

    outputRF = predict(rf, x_test);

    outputKNNE = predict(knne, x_test);

    [sensFis, specFis, ~, tpFis, fpFis, tnFis, fnFis] = ...
        sensitivitySpecificityError(outputFisher, y_test, [-1 1]);

    [sensSVM, specSVM, ~, tpSVM, fpSVM, tnSVM, fnSVM] = ...
        sensitivitySpecificityError(outputSVM, y_test, [-1 1]);

    [sensANN, specANN, ~, tpANN, fpANN, tnANN, fnANN] = ...
        sensitivitySpecificityError(outputANN, y_test, [-1 1]);

    [sensTree, specTree, ~, tpTree, fpTree, tnTree, fnTree] = ...
        sensitivitySpecificityError(outputTree, y_test, [-1 1]);

    [sensKNN, specKNN, ~, tpKNN, fpKNN, tnKNN, fnKNN] = ...
        sensitivitySpecificityError(outputKNN, y_test, [-1 1]);

    [sensBay, specBay, ~, tpBay, fpBay, tnBay, fnBay] = ...
        sensitivitySpecificityError(outputBay, y_test, [-1 1]);     

    [sensRF, specRF, ~, tpRF, fpRF, tnRF, fnRF] = ...
        sensitivitySpecificityError(outputRF, y_test, [-1 1]);

    [sensKNNE, specKNNE, ~, tpKNNE, fpKNNE, tnKNNE, fnKNNE] = ...
        sensitivitySpecificityError(outputKNNE, y_test, [-1 1]);

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

end

