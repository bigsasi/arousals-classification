classdef (Sealed) Configuration < handle
    %CONFIGURATION Configuration class with all the relevant parameters
    %used in the algorithm.
    
    properties (Constant)
        Instance = Configuration;
    end
    
    properties
    % Common configuration
        epochDuration = 30;
        usePreviousHypnogram = 0;
        
    % Arousals detection configuration
        arousalWindowSize = 3;
        arousalWindowStep = 0.2;
        arousalBackground = 10;
        arousalThreshold = 1.1;
        arousalAlphaThreshold = 2;
        arousalThetaThreshold = 2;
        arousalGradientLimit = 0.2;
        arousalLcutoff = [16, 8 4];
        arousalHcutoff = [62.5, 12 7];

        arousalMinDuration = 3;
        arousalEventDuration = 0;
        
    % Hypnogram construction configuration
        hypnogramWindowSize = 3;
        hypnogramWindowStep = 1;
        hypnogramLcutoff = [8, .5, 4, 13];
        hypnogramHcutoff = [12, 3, 7, 30];
        
    % K-Complex detection configuration
        kcomplexWindowSize = 2;
        kcomplexWindowStep = 0.4;
        kcomplexLcutoff = [16, 8, .5, 4, 16];
        kcomplexHcutoff = [62.5, 12, 4, 8, 30];
        kcomplexBackground = 30;
        kcomplexDeltaThreshold = 5;
        kcomplexEmgThreshold = 2;
    
    % Sleep Spindles detection configuration
        spindlesWindowSize = 2;
        spindlesWindowStep = 0.2;
        spindlesBackground = 10;
        spindlesLcutoff = [12, 16, 8, .5, 4, 16];
        spindlesHcutoff = [15, 62.5, 12, 4, 8, 30];
        spindlesThreshold = 2;
        spindlesEmgThreshold = 2;
        spindlesAlphaThreshold = 2;
        
    % Other
        thresholdSmoothing = 1;
        eventSurrounding = 3;
    end
    
    methods (Access = private)
        function obj = Configuration
        end
    end
   
    methods (Static)
        function singleObj = getInstance
            singleObj = Configuration.Instance;
        end
        
        function confCell = getConfCell
            obj = Configuration.getInstance;
            props = properties(obj);
            pos = 1;
            for k = 1:length(props)
                prop = char(props(k));
                if ~isequal(prop, 'Instance');
                    confCell{pos} = obj.(prop);
                    pos = pos + 1;
                end
            end
        end
    end   
   
    methods
        function obj = setValue(obj, property, value)
            config = Configuration.Instance;
            config.(property) = value;
        end
    end
end

