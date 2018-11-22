classdef (Sealed) Features < dynamicprops
    %CONFIGURATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant, Access = private)
        Instance = Features;
    end
    
    properties
        size = 0;
        range = [];
    end
    
    methods (Access = private)
        function obj = Features
        end
        
        function obj = updateValues(obj)
            % feature name, # signals, use it
            newprops = {
                'totalAlpha',       2, 1;
                'overAlpha',        2, 0;
                'minOverAlpha',     2, 0;
                'totalDeltaAlpha',  2, 0;
                'meanDeltaAlpha',   2, 0;
                'maxDeltaAlpha',    2, 0;
                'minDeltaAlpha',    2, 0;
                'diffAlpha',        2, 0;
                'maxAlpha',         2, 1;
                'minAlpha',         2, 1;
                'meanAlpha',        2, 0;
                'stdAlpha',         2, 0;
                'varAlpha',         2, 0;
                'geomeanAlpha',     2, 0;
                'harmmeanAlpha',    2, 0;
                
                'totalTheta',       2, 1;
                'overTheta',        2, 0;
                'minOverTheta',     2, 0;
                'totalDeltaTheta',  2, 0;
                'meanDeltaTheta',   2, 0;
                'maxDeltaTheta',    2, 0;
                'minDeltaTheta',    2, 0;
                'diffTheta',        2, 0;
                'maxTheta',         2, 1;
                'minTheta',         2, 1;
                'meanTheta',        2, 0;
                'stdTheta',         2, 0;
                'varTheta',         2, 0;
                'geomeanTheta',     2, 0;
                'harmmeanTheta',    2, 0;
                
                'totalEmg',         2, 1;
                'overEmg',          2, 0;
                'minOverEmg',       2, 0;
                'totalDeltaEmg',    2, 0;
                'meanDeltaEmg',     2, 0;
                'maxDeltaEmg',      2, 0;
                'minDeltaEmg',      2, 0;
                'diffEmg',          2, 0;
                'maxEmg',           2, 1;
                'minEmg',           2, 1;
                'meanEmg',          2, 0;
                'stdEmg',           2, 0;
                'varEmg',           2, 0;
                'geomeanEmg',       2, 0;
                'harmmeanEmg',      2, 0;

                'totalBeta',        2, 1;
                'maxBeta',          2, 1;
                'minBeta',          2, 1;
                
                'totalDelta',       2, 1;
                'maxDelta',         2, 1;
                'minDelta',         2, 1;


                'activityEeg',      2, 1;
                'mobilityEeg',      2, 1;
                'complexityEeg',    2, 1;
                
                'duration',         2, 1;
                
                'commonEegEvent',   1, 1;
                'middleDiference',  1, 1;

                'sleepStageW',      1, 1;
                'sleepStage1',      1, 1;
                'sleepStage2',      1, 1;
                'sleepStage3',      1, 1;
                'sleepStageR',      1, 1;
                'epochNum',         1, 1;
                
                'totalEmgAmplitude',1, 1;
                'maxEmgAmplitude',  1, 1;
                'minEmgAmplitude',  1, 1;
                'meanEmgAmplitude', 1, 0;
                'stdEmgAmplitude',  1, 0;
                'varEmgAmplitude',  1, 0;
                'durationEmg',      1, 1;
                
                'isArousal',        1, 1;
            };
            propIndex = 1;
            for i = 1:length(newprops)
                propName = char(newprops{i, 1});
                useit = newprops{i, 3};
                count = newprops{i, 2};
                obj.addprop(propName);
                obj.(propName) = propIndex;
                if useit
                    for j = 0:count - 1
                        obj.range = [obj.range propIndex + j];
                    end 
                    obj.size = obj.size + count;
                end
                propIndex = propIndex + count;    
            end
        end
    end
   
    methods (Static)
        function singleObj = getInstance
            singleObj = Features.Instance;
            if singleObj.size == 0, singleObj = singleObj.updateValues; end
        end
    end
    
    methods
        
        function range = getInputRange(obj)
            range = obj.range;
            removeFromInput = {'isArousal'; 'epochNum'};
            notInput = [];
            for i = 1:length(removeFromInput)
                f = removeFromInput{i};
                notInput = [notInput find(range == obj.(f))];
            end
            range(notInput) = [];
        end
        
        function range = getDataScalingRange(obj)
            range = obj.range;
            removeFromInput = {'isArousal'; 'epochNum'};
            notInput = [];
            for i = 1:length(removeFromInput)
                f = removeFromInput{i};
                notInput = [notInput find(range == obj.(f))];
            end
            range(notInput) = [];
        end
    
        function size = getSize(obj)
            size = obj.size;
        end
    end   
   
    methods
    end
end

