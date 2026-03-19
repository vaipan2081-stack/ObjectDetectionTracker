% =========================================================
%  diagnosisToolboxes.m
%  Run this to find exactly why toolboxes aren't detected.
% =========================================================

clc;
fprintf('========================================\n');
fprintf('  Deep Toolbox Diagnosis\n');
fprintf('========================================\n\n');

%% Method 1: license() check (original method)
fprintf('--- Method 1: license() check ---\n');
toolboxes = {
    'Deep Learning Toolbox',                  'deeplearning';
    'Computer Vision Toolbox',                'vision';
    'Statistics and Machine Learning Toolbox','stats';
    'Image Processing Toolbox',               'image_toolbox';
};
for i = 1:size(toolboxes,1)
    if license('test', toolboxes{i,2})
        fprintf('  [OK]  %s\n', toolboxes{i,1});
    else
        fprintf('  [FAIL] %s\n', toolboxes{i,1});
    end
end

%% Method 2: ver() check (more reliable)
fprintf('\n--- Method 2: ver() installed products ---\n');
v = ver;
names = {v.Name};
targets = {'Deep Learning Toolbox', 'Computer Vision Toolbox', ...
           'Statistics and Machine Learning Toolbox', 'Image Processing Toolbox'};
for i = 1:numel(targets)
    if any(strcmpi(names, targets{i}))
        idx = find(strcmpi(names, targets{i}), 1);
        fprintf('  [FOUND] %s  v%s\n', targets{i}, v(idx).Version);
    else
        fprintf('  [NOT FOUND] %s\n', targets{i});
    end
end

%% Method 3: Try actually calling a function from each toolbox
fprintf('\n--- Method 3: Function availability test ---\n');

% Computer Vision Toolbox
try
    pts = detectHarrisFeatures(zeros(10,10));
    fprintf('  [OK]  Computer Vision Toolbox - detectHarrisFeatures works\n');
catch e
    fprintf('  [FAIL] Computer Vision Toolbox - %s\n', e.message);
end

% Deep Learning Toolbox
try
    net = alexnet;
    fprintf('  [OK]  Deep Learning Toolbox - alexnet loaded\n');
catch e
    try
        x = dlarray([1 2 3]);
        fprintf('  [OK]  Deep Learning Toolbox - dlarray works\n');
    catch e2
        fprintf('  [FAIL] Deep Learning Toolbox - %s\n', e2.message);
    end
end

% Statistics Toolbox
try
    x = fitlm([1;2;3],[1;2;3]);
    fprintf('  [OK]  Statistics Toolbox - fitlm works\n');
catch e
    fprintf('  [FAIL] Statistics Toolbox - %s\n', e.message);
end

%% Method 4: Full installed product list
fprintf('\n--- Method 4: ALL installed products ---\n');
for i = 1:numel(v)
    fprintf('  %s  v%s\n', v(i).Name, v(i).Version);
end

fprintf('\n========================================\n');
fprintf('  Copy and paste ALL of the above output\n');
fprintf('  back to Claude for diagnosis.\n');
fprintf('========================================\n');
