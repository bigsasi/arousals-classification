function printMeasures(sens, spec, vp, fp, vn, fn)
%PRINTSTATISTICS Summary of this function goes here
%   Detailed explanation goes here
    auc = (sens + spec) / 2;
    ia = (vp + vn) / (vp + fp + vn + fn);
    error = 1 - ia;

    fprintf('error: %f\n', error);
    fprintf('sens, spec: [%f %f] (AUC = %f)\n', sens, spec, auc);
    fprintf('vp, fp, vn, fn: [%d, %d, %d, %d]\n', vp, fp, vn, fn); 
    fprintf('vpp: %f\n', vp/(fp + vp));
    fprintf('vpn: %f\n', vn/(fn + vn)); 
    fprintf('ia: %f\n', ia);
    fprintf('jaccard: %f\n', vp / (vp + fp + fn));
    fprintf('\n');
end

