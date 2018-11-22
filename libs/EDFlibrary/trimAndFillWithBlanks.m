function result = trimAndFillWithBlanks(str, maxLength, justify)

if (nargin == 2)
    justify = 'left';
end

if length(str) > maxLength
    result = str(1:maxLength);
else
    if strcmp(justify, 'right')
        result = [blanks(maxLength - length(str)), str];
    else 
        % default is left
        result = [str, blanks(maxLength - length(str))];
    end
end