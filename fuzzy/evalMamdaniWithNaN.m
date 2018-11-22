% Equivalente a evalfis de Fuzzy Toolbox, pero si la entrada contiene
% valores NaN se desactivan las reglas que no son válidas para el
% subconjunto de datos de la entrada libre de valores NaN
%
% Es decir, si por ejemplo la entrada se compone de 4 variables y cierto
% patrón contiene dos variables de entrada con valores NaN, el fis
% correspondiente sería un fis con 2 entradas, donde se conservan todas las
% reglas que afectan como máximo a esas dos entradas
%
% Si la entrada no contiene NaN, el resultado es exactamente igual al
% evalfis del Fuzzy Toolbox (y casi igual de rápido!)
%
% Por otro lado si una entrada no activa ninguna regla,
% o existe una variable de salida cuya agregación es cero
% el valor de salida por defecto es "defaultOutput", que 
% en el caso del FuzzyLogic Toolbox es 0.5
function output = evalMamdaniWithNaN(input, fis, defaultOutput)

if (nargin == 2)
    defaultOutput = 0; % To mimic FuzzyLogic Toobox behaviour set to 0.5
end
output = ones(length(input(:, 1)), length(fis.output)) * defaultOutput;

maskInput = isnan(input);
processNaN = sum(maskInput, 2) > 0;

output(not(processNaN), :) = evalfis(input(not(processNaN), :), fis);

% Here patterns "suspicious" of causing no aggregation at the output
% are checked and assigned defaultOutput if it corresponds
indexEvalfis = find(not(processNaN));
indexToCheck = find(sum(output(not(processNaN), :) - 0.5*ones(length(indexEvalfis), length(fis.output)), 2) == 0);
for k = 1:length(indexToCheck)
    [output(indexEvalfis(indexToCheck(k)), :), ~, ~, ARR] = evalfis(input(indexEvalfis(indexToCheck(k)), :), fis);
    output(indexEvalfis(indexToCheck(k)), not(sum(ARR))) = defaultOutput;
end

% Here input patterns containing NaN values are re-processed
processNaN = find(processNaN);
if not(isempty(processNaN))
    tempInput = input(processNaN, :);
    tempFIS = fis;
    %tempRule = zeros(length(fis.rule), length(fis.rule(1).antecedent));
    tempRule = zeros(length(fis.rule), length(fis.input));
    for k = 1:length(fis.rule)
        tempRule(k, :) = fis.rule(k).antecedent;
    end
    
    for k = 1:length(tempInput(:, 1))
        %indx = sum(tempRule(:, maskInput(processNaN(k), :)), 2) == 0;
        indx = not(any(tempRule(:, maskInput(processNaN(k), :)), 2));
        tempFIS.rule = fis.rule(indx);
        
        if not(isempty(tempFIS.rule))
            [output(processNaN(k), :), ~, ~, ARR] = evalfis(tempInput(k, :), tempFIS);
            % La salida para cierta variable no tiene área entonces se deja
            % a defaultOutput
            output(processNaN(k), not(sum(ARR))) = defaultOutput;
        end
        % Si una entrada no activa ninguna regla, el valor de salida por
        % defecto es "defaultOutput"
                
    end
end