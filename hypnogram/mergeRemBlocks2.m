
% POSPROCESADO N�2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A continuacion construimos la matriz remList que incluye informacion
% sobre los bloques y picos REM. De este modo tendremos informaci�n de lo
% cerca o lejos que est�n todos los picos REM los unos de los otros.
% Aquellos picos REM que est�n cerca de un bloque grande pueden unirse, 
% mientras que los picos aislados o peque�os ser�n descartados. Una vez 
% construida, la utilizamos para agrupar zonas REM para formar bloques.
function entrada = mergeRemBlocks2(entrada, remList, mediaF0, mediaF1, ...
    mediaF2, mediaFSP)
% entrada       El vector resultado inicial
% remList       La lista de bloques REM
% salida        El vector resultado final

% Consideramos 1 solo bloque aquellos picos que est�n cerca de 
% bloques REM grandes (10 epochs de distancia como m�ximo).
for j=1:size(remList, 1) - 1
    if remList(j, 2) + 10 >= remList(j + 1, 1)
        remList(j + 1, 1) = remList(j, 1);
        remList(j + 1, 3) = remList(j, 3) + remList(j + 1, 3) + 1;
        remList(j, 1) = -1;
        remList(j, 2) = -1;
    end
end
% Todos los bloques de tama�o 1 aislados se borran
entrada(remList(remList(:, 3) == 0 & remList(:, 1) ~= -1, 1)) = -1;
% Convertimos todos esos bloques identificados como REM
remList = remList(remList(:, 1) ~= -1 & remList(:, 3) > 0, :);
for j=1:size(remList, 1)
    entrada(remList(j, 1):remList(j, 2)) = 5;
end

for j = find(entrada == -1)'
    [~, pos] = max([mediaF0(j) mediaF1(j) mediaF2(j) mediaFSP(j)]);     % Calculamos el maximo   
    entrada(j) = pos - 1;
end