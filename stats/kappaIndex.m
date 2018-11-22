function [kappaIndex] = kappaIndex(matrix)
%KAPPAINDEX returns the kappa index using the given confusion matrix
[fil, col] = size(matrix);
if (fil == col)
    sumDiagonal = 0;
    pc = 0;
    totalCasos = sum(sum(matrix));
    for k = 1:fil
        sumDiagonal = sumDiagonal + matrix(k, k);
        pc = pc + (sum(matrix(k,:))/totalCasos)*(sum(matrix(:,k))/totalCasos);
    end
    p0 = sumDiagonal / totalCasos;
    kappaIndex = (p0 - pc) / (1 - pc);
else
    disp('Error: input matrix is not a square matrix');
end
