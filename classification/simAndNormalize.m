function [ netResult2, netResult ] = simAndNormalize(net, testData, expertResult)
%TRAINANDNORMALIZE Summary of this function goes here
%   Detailed explanation goes here

    netResult = sim(net, testData)';


    % netResult = netResult + abs(min(netResult));
    % % minResult = min(netResult);
    % maxResult = max(netResult);
    % netResult = netResult / maxResult;
    % netResult = netResult * 2 - 1;
    % expertResult = testData(:, end)';


    maxAUC = 0;
    posMax = 0;
    for i = min(netResult):0.001:max(netResult)
        netResult2 = netResult;
        netResult2(netResult > i) = 1;
        netResult2(netResult <= i) = -1;

        [~, out, ~, ~, ~, ~, ~, ~] = sensitivitySpecificityError(netResult2, expertResult, [-1 1]);
        actualAUC = (out(1) + out(2)) / 2;
        if actualAUC > maxAUC
            maxAUC = actualAUC;
            posMax = i;
        end
    end

    aux = netResult + abs(posMax);
    aux(aux > 0) = aux(aux > 0) / max(aux);

    aux2 = netResult + abs(posMax);
    aux2(aux2 <= 0) = aux2(aux2 <= 0) / abs(min(aux2));

    tmp = netResult;
    tmp(netResult > posMax) = aux(netResult > posMax);
    tmp(netResult <= posMax) = aux2(netResult <= posMax);

    netResult = tmp;

    netResult2 = netResult;
    netResult2(netResult > 0) = 1;
    netResult2(netResult <= 0) = -1;
end

