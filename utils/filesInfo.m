totalFiles = 20;
trainFiles = 15;
Output.MUTE;

config = Configuration.getInstance;
features = Features.getInstance;

clear configValues

onlyUsePrecalculatedData = 1;

configValues.arousalThreshold = 1.1;
configValues.arousalMinDuration = 3;
configValues.thresholdSmoothing = 1;
configMatrix = [1.1 3 1];

%% Generate configuration matrix 

tic
tmp = fieldnames(configValues);
fields{length(tmp)} = char(tmp(end));
for i = 1:length(fields) - 1;
   fields{i} = char(tmp(i)); 
end

totalConfigs = 1;

edfPath = '/home/sasi/SHHS/';
annotationsPath = '/home/sasi/SHHS/annotations/';

if (sum(edfPath) == 0), return; end
files = dir(edfPath);

clear multiF
multiF{totalFiles} = '';
i = 1;
for k = 1:length(files)
    if regexpi(files(k).name, '200\d*(.edf)$')
        F = files(k).name;
        Fxml = strcat(F, '.xml');

        if ~exist(fullfile(annotationsPath, Fxml), 'file')
            Output.INFO('Annotations for %s not found\n', F);
            continue
        end
        multiF{i} = F;
        i = i + 1;
        if i > totalFiles, break; end
    end
end

% totalFiles = 26;
% multiF = {'200088.EDF', '200259.EDF', '200386.EDF', '200532.EDF',...
%         '200568.EDF', '200929.EDF', '201249.EDF', '201294.EDF', '201394.EDF', ...
%         '201824.EDF', '202275.EDF', '202666.EDF', '202733.EDF', '202956.EDF', ...
%         '203249.EDF', '203294.EDF', '203494.EDF', '203645.EDF', '203798.EDF', ...
%         '204135.EDF', '204452.EDF', '204480.EDF', '205813.EDF', '205948.EDF', ...
%         '206040.EDF', '206181.EDF'}; 
%% Launch study Arousals

for configIndex = 1:totalConfigs
    
    fprintf('Configuration: \n');
    for i = 1:length(fields)
        config.setValue(fields{i}, configMatrix(configIndex, i));
        fprintf('    %s: %f\n', fields{i}, configMatrix(configIndex, i));
    end
    
    configPath = ['storedResults/' DataHash(config.getConfCell) '/'];
    
    if ~exist(configPath, 'dir')
        if onlyUsePrecalculatedData
            fprintf('Previous data not found, skipping\n');
            continue
        else
            mkdir(configPath);
        end
    end
    
    allStats = cell(totalFiles, 1);
    for k = 1:totalFiles
        fileName = char(multiF(k));
      
        FStats = [fileName '-stats.mat'];
        FArousals = [fileName '-arousalsDetection.mat'];
        FClasMatrix = [fileName '-classificationMatrix.mat'];
        
        if exist([configPath FStats], 'file')
            copyfile([configPath FArousals], 'lastArousalDetection.mat');
            load([configPath FStats], 'stats');
        else
            
        end
        

        if exist([configPath FClasMatrix], 'file')
            load([configPath FClasMatrix], 'clasMatrix');
        else
        end
        stats.clasMatrix = clasMatrix;
        allStats{k} = stats;
    end
    
end
toc
