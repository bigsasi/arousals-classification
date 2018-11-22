function matrix = buildConfusionMatrix(scoring1, scoring2, categories)
%BUILDCONFUSIONMATRIX returns the confusion matrix for two different
%scorings using the classes in categories as the default classes. 
    if ne(length(scoring1), length(scoring2))
        disp('Error, length of the first two input vectors should be the same');
        return
    end

    matrix = zeros(length(categories));

    for k = 1:length(scoring1)
        indx1 = find(categories == scoring1(k));
        indx2 = find(categories == scoring2(k));
        matrix(indx1, indx2) = matrix(indx1, indx2) + 1;
    end
end