% =========================================================
%  checkToolboxes.m
%  Run this FIRST to verify your MATLAB environment is ready
%  for the Object Detection & Tracking project.
% =========================================================

clc; clear;
fprintf('==============================================\n');
fprintf('  MATLAB Environment Check\n');
fprintf('  Object Detection & Tracking Project\n');
fprintf('==============================================\n\n');

required = {
    'Deep Learning Toolbox',        'deeplearning';
    'Computer Vision Toolbox',      'vision';
    'Statistics and Machine Learning Toolbox', 'stats';
    'Image Processing Toolbox',     'image_toolbox';
};

allGood = true;

for i = 1:size(required, 1)
    name = required{i, 1};
    tag  = required{i, 2};
    if license('test', tag)
        fprintf('  [OK]  %s\n', name);
    else
        fprintf('  [MISSING]  %s\n', name);
        allGood = false;
    end
end

fprintf('\n--- MATLAB Version ---\n');
fprintf('  %s\n', version);

fprintf('\n--- GPU Status ---\n');
try
    g = gpuDevice();
    fprintf('  GPU found: %s (%.1f GB)\n', g.Name, g.AvailableMemory/1e9);
    fprintf('  Tip: GPU will speed up detection ~10x\n');
catch
    fprintf('  No GPU detected — CPU mode will be used (slower but works fine)\n');
end

fprintf('\n');
if allGood
    fprintf('  All toolboxes ready! Proceed to config.m\n');
else
    fprintf('  Install missing toolboxes via:\n');
    fprintf('  Home > Add-Ons > Get Add-Ons\n');
end
fprintf('==============================================\n');
