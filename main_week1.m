% =========================================================
%  main_week1.m  —  Week 1: Data Loading & Preprocessing
% =========================================================

clc; clear; close all;
fprintf('================================================\n');
fprintf('  Week 1: Data Loading & Preprocessing\n');
fprintf('================================================\n\n');

%% Step 0: Add src folder to path
projectRoot = fileparts(mfilename('fullpath'));
srcPath = fullfile(projectRoot, 'src');
if isfolder(srcPath)
    addpath(srcPath);
else
    % src files are in same folder — add project root
    addpath(projectRoot);
end

%% Step 1: Load configuration
cfg = config();

%% Step 2: Load dataset
fprintf('--- STEP 1: Loading Dataset ---\n');
dataset = dataLoader(cfg);

fprintf('\nDataset Summary:\n');
fprintf('  Source     : %s\n', dataset.source);
fprintf('  Frames     : %d\n', dataset.numFrames);
fprintf('  Image Size : %dx%d\n', dataset.imageSize(2), dataset.imageSize(1));
totalBoxes = sum(cellfun(@(x) size(x,1), dataset.gtBoxes));
fprintf('  GT Boxes   : %d total across all frames\n', totalBoxes);

%% Step 3: Preprocess
fprintf('\n--- STEP 2: Preprocessing ---\n');
[procFrames, procBoxes] = preprocessor(dataset.frames, dataset.gtBoxes, cfg);

sampleFrame = procFrames{1};
fprintf('  Pixel range after normalization: [%.3f, %.3f]\n', min(sampleFrame(:)), max(sampleFrame(:)));
fprintf('  Frame dtype: %s\n', class(sampleFrame));

%% Step 4: Visualize 20 sample annotated frames
fprintf('\n--- STEP 3: Visualizing Sample Frames ---\n');
nPreview = min(20, dataset.numFrames);

hasBoxes   = cellfun(@(x) size(x,1) > 0, dataset.gtBoxes);
previewIdx = find(hasBoxes, nPreview);
if numel(previewIdx) < nPreview
    extra = find(~hasBoxes, nPreview - numel(previewIdx));
    previewIdx = [previewIdx, extra];
end
previewIdx = previewIdx(1:min(nPreview, numel(previewIdx)));

figure('Name','Week 1: Ground Truth Annotations', ...
       'NumberTitle','off','Position',[50,50,1400,900]);
cols = 5; rows = ceil(numel(previewIdx)/cols);

for k = 1:numel(previewIdx)
    i = previewIdx(k);
    annotated = visualizer(procFrames{i}, procBoxes{i}, dataset.gtLabels{i}, cfg, ...
                           'frameNum', i);
    subplot(rows, cols, k);
    imshow(annotated);
    title(sprintf('Frame %d | %d boxes', i, size(procBoxes{i},1)), ...
          'FontSize', 8, 'Interpreter', 'none');
end
sgtitle('Ground Truth Annotations (preprocessed frames)', ...
        'FontSize', 14, 'FontWeight', 'bold');
fprintf('  Displayed %d annotated frames.\n', numel(previewIdx));

%% Step 5: Class distribution chart
fprintf('\n--- STEP 4: Class Distribution ---\n');
allLabels = vertcat(dataset.gtLabels{:});
if ~isempty(allLabels)
    figure('Name','Class Distribution','Position',[100,100,700,400]);
    histogram(allLabels,'FaceColor',[0.2,0.5,0.9]);
    title('GT Box Count per Class','FontSize',13);
    xlabel('Class'); ylabel('Count');
    grid on; box on; set(gca,'FontSize',11);
    fprintf('  Class distribution chart displayed.\n');
end

%% Step 6: Save sample frame
if ~isfolder(cfg.resultsDir), mkdir(cfg.resultsDir); end
sampleOut = fullfile(cfg.resultsDir, 'week1_sample_frame.png');
imwrite(uint8(procFrames{previewIdx(1)} * 255), sampleOut);
fprintf('\n[main_week1] Sample frame saved to:\n  %s\n', sampleOut);

fprintf('\n================================================\n');
fprintf('  Week 1 COMPLETE\n');
fprintf('  500 frames loaded, preprocessed, visualized.\n');
fprintf('  Next step: run main_week2.m\n');
fprintf('================================================\n');
