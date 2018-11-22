function [sens, spec, error, tp, fp, tn, fn, where] = sensitivitySpecificityError(x, y, classLabels)
%SENSITIVITYSPECIFICITYERROR returns sensitivity, specificity, error, true
%positives, false positives, true negatives, false negatives and where
%errors ocurr for two different scores.

num = length(x);
where = find(x ~= y);
error = length(where) / num;
 
indexes = [];
for clas = 1:length(classLabels)
    indexes{clas} = find(y == classLabels(clas));
    
    if not(isempty(indexes{clas}))
        tp(clas) = sum(x(indexes{clas}) == y(indexes{clas}));
        fn(clas) = sum(x(indexes{clas}) ~= y(indexes{clas}));
    else
        % There are no examples of that class in vector y 
        tp(clas) = 0;
        fn(clas) = 0;
    end

    sens(clas) = tp(clas)/(tp(clas) + fn(clas));
end

indexes = [];
for clas = 1:length(classLabels)
    indexes{clas} = (y == classLabels(clas));
    
    if (sum(indexes{clas}) > 0)
        tn(clas) = sum(x(not(indexes{clas})) ~= classLabels(clas));
        fp(clas)     = sum(x(not(indexes{clas})) == classLabels(clas));
    else
        % There are no examples in y of that class 
        tn(clas) = sum(x ~= classLabels(clas));
        fp(clas)     = sum(x == classLabels(clas));
    end

    spec(clas) = tn(clas)/(tn(clas) + fp(clas));
end