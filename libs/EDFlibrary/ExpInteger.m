function out = ExpInteger(input, Y0, A)

if (input > 0)
    out = Y0 * exp(A * input);
elseif (input < 0)
    out = (-1)*Y0 * exp((-1) * A * input);
else
    out = 0;
end