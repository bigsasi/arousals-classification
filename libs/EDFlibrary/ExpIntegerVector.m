function out = ExpIntegerVector(vector, Y0, A)

out = zeros(size(vector));

out((vector > 0)) = Y0 * exp(A * vector(vector > 0));
out((vector < 0)) = (-1) * Y0 * exp((-1) * A * vector(vector < 0));
% Those with zero value at input remain zero at output