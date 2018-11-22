function out = LogFloat(input, Y0, A)

if (input > Y0)
    r = (log10(input) - log10(Y0)) / A;
    out = int16(round(min(r, intmax('int16'))));
elseif (input < -Y0)
    r = (-log10((-1)*input) + log10(Y0)) / A;
    out = int16(round(max(r, -intmax('int16'))));
else
    out = 0;
end