function out = LogFloatVector(vector, Y0, A)

out = zeros(size(vector));

r = (log10(vector(vector > Y0)) - log10(Y0)) / A;
out(vector > Y0) = int16(round(min(r, intmax('int16'))));

r = (-log10((-1)*vector(vector < Y0)) + log10(Y0)) / A;
out(vector < Y0) = int16(round(max(r, -intmax('int16'))));

% Those with zero value at input remain zero at output