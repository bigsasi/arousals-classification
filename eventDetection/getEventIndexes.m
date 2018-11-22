function [init, ends] = getEventIndexes(events)
%GETEVENTINDEXES return initial and ending positions of marked events
%
%   This functions return both the initial point and the ending point for the
%   events marked in events array. 

    init = find(diff(events) == 1) + 1;
    ends = find(diff(events) == -1);
    if not(isempty(init) || isempty(ends))
        % Arreglamos casos donde en la señal empieza o finaliza en evento
        if ends(1) < init(1)
            ends = ends(2:end);
        end
        if ends(end) < init(end)
            init = init(1:end-1);
        end
    end    
end

