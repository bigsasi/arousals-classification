function arousalsDataToFile(arousalsData, algName, fileName)

load('lastArousalDetection.mat')

startName = [algName 'Start'];
durationName = [algName 'Duration'];

realIndex = 0;
fileId = fopen(fileName, 'w');

for i = 1:length(arousalsData)
    arousal = arousalsData(i);
    if arousal.(startName) ~= 0
        realIndex = realIndex + 1;
    else 
        fprintf(fileId, 'Not detected (index = %d)\n', i);
        
        startWindow = round(arousal.expertStart / 0.2);
        endWindow = round((arousal.expertStart + arousal.expertDuration) / 0.2);
        
        fprintf(fileId, '[Start, duration] = [%d, %d] (seconds)\n', arousal.expertStart, arousal.expertDuration);
        fprintf(fileId, 'Window: [%d, %d]\n', startWindow, endWindow);
        epochNum = round(arousal.expertStart / 30);
        if epochNum == 0, continue; end
        fprintf(fileId, 'Epoch: %d (Sleep Stage: %d)\n', epochNum, sleepStages.Signal(epochNum));
%         startWindow = startWindow - 5;
%         endWindow = endWindow + 5;
        
        fprintf(fileId, 'Emg events:\n');
        fprintf(fileId, '%d ', arousalEvents1(startWindow:endWindow)); fprintf(fileId, '\n');
        tmp = emgPower1(startWindow:endWindow) ./ emgBaseline1(startWindow:endWindow);
        fprintf(fileId, 'Over threshold: %f\n', sum(tmp(tmp > 1.5) - 1.5));
        fprintf(fileId, 'Below threshold: %f\n', sum(1.5 - tmp(tmp < 1.5)));
        fprintf(fileId, 'Ratio: %f\n', sum(tmp(tmp > 1.5) - 1.5) / sum(1.5 - tmp(tmp < 1.5)));
        fprintf(fileId, 'Emg threshold (against emg baseline):\n');
        fprintf(fileId, '%f ', tmp); fprintf(fileId, '\n');
        fprintf(fileId, 'Emg threshold (against arousals baseline):\n');
        tmp = emgPower1(startWindow:endWindow) ./ arousalBaseline1(startWindow:endWindow);
        fprintf(fileId, '%f ', tmp); fprintf(fileId, '\n');      
        
        fprintf(fileId, 'Alpha events:\n');
        fprintf(fileId, '%d ', alphaEvents1(startWindow:endWindow)); fprintf(fileId, '\n');
        tmp = alphaPower1(startWindow:endWindow) ./ alphaBaseline1(startWindow:endWindow);
        fprintf(fileId, 'Over threshold: %f\n', sum(tmp(tmp > 2) - 2));
        fprintf(fileId, 'Below threshold: %f\n', sum(2 - tmp(tmp < 2)));
        fprintf(fileId, 'Ratio: %f\n', sum(tmp(tmp > 2) - 2) / sum(2 - tmp(tmp < 2)));
        fprintf(fileId, 'Alpha threshold:\n');
        fprintf(fileId, '%f ', tmp); fprintf(fileId, '\n');
        
        fprintf(fileId, 'Theta events:\n');
        fprintf(fileId, '%d ', thetaEvents1(startWindow:endWindow)); fprintf(fileId, '\n');
        fprintf(fileId, 'Theta threshold:\n');
        fprintf(fileId, '%f ', thetaPower1(startWindow:endWindow) ./ thetaBaseline1(startWindow:endWindow)); fprintf(fileId, '\n');
        
        fprintf(fileId, 'Emg events:\n');
        fprintf(fileId, '%d ', arousalEvents2(startWindow:endWindow)); fprintf(fileId, '\n');
        tmp = emgPower2(startWindow:endWindow) ./ emgBaseline2(startWindow:endWindow);
        fprintf(fileId, 'Over threshold: %f\n', sum(tmp(tmp > 1.5) - 1.5));
        fprintf(fileId, 'Below threshold: %f\n', sum(1.5 - tmp(tmp < 1.5)));
        fprintf(fileId, 'Ratio: %f\n', sum(tmp(tmp > 1.5) - 1.5) / sum(1.5 - tmp(tmp < 1.5)));
        fprintf(fileId, 'Emg threshold:\n');
        fprintf(fileId, '%f ', tmp); fprintf(fileId, '\n');
        fprintf(fileId, 'Emg threshold (against arousals baseline):\n');
        tmp = emgPower2(startWindow:endWindow) ./ arousalBaseline2(startWindow:endWindow);
        fprintf(fileId, '%f ', tmp); fprintf(fileId, '\n');     
        
        fprintf(fileId, 'Alpha events:\n');
        fprintf(fileId, '%d ', alphaEvents2(startWindow:endWindow)); fprintf(fileId, '\n');
        tmp = alphaPower2(startWindow:endWindow) ./ alphaBaseline2(startWindow:endWindow);
        fprintf(fileId, 'Over threshold: %f\n', sum(tmp(tmp > 2) - 2));
        fprintf(fileId, 'Below threshold: %f\n', sum(2 - tmp(tmp < 2)));
        fprintf(fileId, 'Ratio: %f\n', sum(tmp(tmp > 2) - 2) / sum(2 - tmp(tmp < 2)));
        fprintf(fileId, 'Alpha threshold:\n');
        fprintf(fileId, '%f ', tmp); fprintf(fileId, '\n');
        
        fprintf(fileId, 'Theta events:\n');
        fprintf(fileId, '%d ', thetaEvents2(startWindow:endWindow)); fprintf(fileId, '\n');
        fprintf(fileId, 'Theta threshold:\n');
        fprintf(fileId, '%f ', thetaPower2(startWindow:endWindow) ./ thetaBaseline2(startWindow:endWindow)); fprintf(fileId, '\n');
        fprintf(fileId, '\n');
        
        continue;
    end
    
    if arousal.expertStart == 0
        fprintf(fileId, 'Detected FP (index = %d (%d))\n', i, realIndex);
    else
        fprintf(fileId, 'Detected TP (index = %d (%d))\n', i, realIndex);
    end
    
    if arousal.(durationName) <= 5
        fprintf(fileId, '\n');
        continue; 
    end
    
    fprintf(fileId, 'Detected [Start, duration] = [%d, %d] (seconds)\n', arousal.(startName), arousal.(durationName));
    fprintf(fileId, 'Expert [Start, duration] = [%d, %d] (seconds)\n', arousal.expertStart, arousal.expertDuration);
    epochNum = arousalsOutput(realIndex).epochNum;
    fprintf(fileId, 'Epoch: %d (Sleep Stage: %d)\n', epochNum, sleepStages.Signal(epochNum));

    indexEMG = arousalsOutput(realIndex).indexEventEMG;
    if indexEMG > 0
        fprintf(fileId, 'Index EMG: %d --> [%d, %d] (samples)\n', indexEMG, arousalsEMG(indexEMG).start, arousalsEMG(indexEMG).end);
    end

    indexEeg1 = arousalsOutput(realIndex).indexEventEEG1;
    if indexEeg1 > 0
        startWindow = arousalsDef1(indexEeg1, 3);
        endWindow = arousalsDef1(indexEeg1, 4);
        fprintf(fileId, 'Index EEG1: %d --> [%d, %d] (samples) [%d, %d] (window)\n', indexEeg1, arousalsDef1(indexEeg1, 1), arousalsDef1(indexEeg1, 2), startWindow, endWindow);
%         startWindow = startWindow - 5;
%         endWindow = endWindow + 5;
        
        fprintf(fileId, 'Emg events:\n');
        fprintf(fileId, '%d ', arousalEvents1(startWindow:endWindow)); fprintf(fileId, '\n');
        tmp = emgPower1(startWindow:endWindow) ./ emgBaseline1(startWindow:endWindow);
        fprintf(fileId, 'Over threshold: %f\n', sum(tmp(tmp > 1.5) - 1.5));
        fprintf(fileId, 'Below threshold: %f\n', sum(1.5 - tmp(tmp < 1.5)));
        fprintf(fileId, 'Ratio: %f\n', sum(tmp(tmp > 1.5) - 1.5) / sum(1.5 - tmp(tmp < 1.5)));
        fprintf(fileId, 'Emg threshold (against emg baseline):\n');
        fprintf(fileId, '%f ', tmp); fprintf(fileId, '\n');
        fprintf(fileId, 'Emg threshold (against arousals baseline):\n');
        tmp = emgPower1(startWindow:endWindow) ./ arousalBaseline1(startWindow:endWindow);
        fprintf(fileId, '%f ', tmp); fprintf(fileId, '\n');      
        
        fprintf(fileId, 'Alpha events:\n');
        fprintf(fileId, '%d ', alphaEvents1(startWindow:endWindow)); fprintf(fileId, '\n');
        tmp = alphaPower1(startWindow:endWindow) ./ alphaBaseline1(startWindow:endWindow);
        fprintf(fileId, 'Over threshold: %f\n', sum(tmp(tmp > 2) - 2));
        fprintf(fileId, 'Below threshold: %f\n', sum(2 - tmp(tmp < 2)));
        fprintf(fileId, 'Ratio: %f\n', sum(tmp(tmp > 2) - 2) / sum(2 - tmp(tmp < 2)));
        fprintf(fileId, 'Alpha threshold:\n');
        fprintf(fileId, '%f ', tmp); fprintf(fileId, '\n');
        if any(tmp < 1), fprintf(fileId, 'jauri\n'); end
        
        fprintf(fileId, 'Theta events:\n');
        fprintf(fileId, '%d ', thetaEvents1(startWindow:endWindow)); fprintf(fileId, '\n');
        fprintf(fileId, 'Theta threshold:\n');
        fprintf(fileId, '%f ', thetaPower1(startWindow:endWindow) ./ thetaBaseline1(startWindow:endWindow)); fprintf(fileId, '\n');
    end

    indexEeg2 = arousalsOutput(realIndex).indexEventEEG2;
    if indexEeg2 > 0
        startWindow = arousalsDef2(indexEeg2, 3);
        endWindow = arousalsDef2(indexEeg2, 4);
        fprintf(fileId, 'Index EEG2: %d --> [%d, %d] (samples) [%d, %d] (window)\n', indexEeg2, arousalsDef2(indexEeg2, 1), arousalsDef2(indexEeg2, 2), startWindow, endWindow);
%         startWindow = startWindow - 5;
%         endWindow = endWindow + 5;
        
        fprintf(fileId, 'Emg events:\n');
        fprintf(fileId, '%d ', arousalEvents2(startWindow:endWindow)); fprintf(fileId, '\n');
        tmp = emgPower2(startWindow:endWindow) ./ emgBaseline2(startWindow:endWindow);
        fprintf(fileId, 'Over threshold: %f\n', sum(tmp(tmp > 1.5) - 1.5));
        fprintf(fileId, 'Below threshold: %f\n', sum(1.5 - tmp(tmp < 1.5)));
        fprintf(fileId, 'Ratio: %f\n', sum(tmp(tmp > 1.5) - 1.5) / sum(1.5 - tmp(tmp < 1.5)));
        fprintf(fileId, 'Emg threshold:\n');
        fprintf(fileId, '%f ', tmp); fprintf(fileId, '\n');
        fprintf(fileId, 'Emg threshold (against arousals baseline):\n');
        tmp = emgPower2(startWindow:endWindow) ./ arousalBaseline2(startWindow:endWindow);
        fprintf(fileId, '%f ', tmp); fprintf(fileId, '\n');      
        
        fprintf(fileId, 'Alpha events:\n');
        fprintf(fileId, '%d ', alphaEvents2(startWindow:endWindow)); fprintf(fileId, '\n');
        tmp = alphaPower2(startWindow:endWindow) ./ alphaBaseline2(startWindow:endWindow);
        fprintf(fileId, 'Over threshold: %f\n', sum(tmp(tmp > 2) - 2));
        fprintf(fileId, 'Below threshold: %f\n', sum(2 - tmp(tmp < 2)));
        fprintf(fileId, 'Ratio: %f\n', sum(tmp(tmp > 2) - 2) / sum(2 - tmp(tmp < 2)));
        fprintf(fileId, 'Alpha threshold:\n');
        fprintf(fileId, '%f ', tmp); fprintf(fileId, '\n');
        if any(tmp < 1), fprintf(fileId, 'jauri\n'); end
        
        fprintf(fileId, 'Theta events:\n');
        fprintf(fileId, '%d ', thetaEvents2(startWindow:endWindow)); fprintf(fileId, '\n');
        fprintf(fileId, 'Theta threshold:\n');
        fprintf(fileId, '%f ', thetaPower2(startWindow:endWindow) ./ thetaBaseline2(startWindow:endWindow)); fprintf(fileId, '\n');
    end
    fprintf(fileId, '\n');
end

fclose(fileId);

% fprintf('Error: %f\n', stats.errorArousals);
% fprintf('[TP, FP] = [%d, %d]\n', stats.VPArousals(2), stats.FPArousals(2));
% fprintf('[Sensitivity, Specifity] = [%f, %f] (arousals)\n', stats.sensiArousals(2), stats.sensiArousals(1));
% fprintf('AUC = %f\n', sum(stats.sensiArousals) / 2);