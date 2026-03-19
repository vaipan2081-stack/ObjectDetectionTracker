% =========================================================
%  main_week2.m  —  Week 2: YOLOv2 Detection + Kalman Tracker
% =========================================================

clc; clear; close all;
fprintf('================================================\n');
fprintf('  Week 2: YOLOv2 Detection + Kalman Tracker\n');
fprintf('================================================\n\n');

%% Step 0: Paths
addpath(fullfile(fileparts(mfilename('fullpath')), 'src'));

%% Step 1: Config — use only 50 frames for fast testing
cfg = config();
cfg.maxFrames = 50;
cfg.useGPU    = true;   % Force GPU

%% Step 2: Load & preprocess data
fprintf('--- STEP 1: Loading dataset (first %d frames) ---\n', cfg.maxFrames);
dataset = dataLoader(cfg);
[procFrames, ~] = preprocessor(dataset.frames, dataset.gtBoxes, cfg);
fprintf('Loaded %d frames.\n', dataset.numFrames);

%% Step 3: Load YOLOv2 model
fprintf('\n--- STEP 2: Loading YOLOv2 model ---\n');
fprintf('If this is your first time, download will take a few minutes...\n');
net = loadDetector(cfg);

%% Step 4: Run detection + tracking on all frames
fprintf('\n--- STEP 3: Running Detection + Tracking ---\n');
trackerState = initTracker(cfg);
results      = cell(1, dataset.numFrames);  % store per-frame results
fpsLog       = zeros(1, dataset.numFrames);

% Setup video writer
if cfg.viz.saveVideo
    if ~isfolder(cfg.resultsDir), mkdir(cfg.resultsDir); end
    vWriter = VideoWriter(cfg.viz.outputVideoFile, 'MPEG-4');
    vWriter.FrameRate = 10;
    open(vWriter);
end

hFig = figure('Name','Week 2: Live Detection + Tracking', ...
              'NumberTitle','off', 'Position',[50,50,900,600]);

for i = 1:dataset.numFrames
    tStart = tic;

    %% Detect
    [bboxes, scores, labels] = detector(procFrames{i}, net, cfg);

    %% Track
    [trackerState, activeTracks] = updateTracker(trackerState, bboxes, scores, labels);

    %% Build display boxes/labels from active tracks
    if ~isempty(activeTracks)
        trackBoxes  = vertcat(activeTracks.bbox);
        trackIDs    = [activeTracks.id];
        trackLabels = {activeTracks.label};
        trackScores = [activeTracks.score];
        % Convert cell of categoricals to categorical array
        trackLabelCat = categorical(cellfun(@char, trackLabels, 'UniformOutput', false));
    else
        trackBoxes    = bboxes;   % fallback: show raw detections
        trackIDs      = [];
        trackLabelCat = labels;
        trackScores   = scores;
    end

    fps = 1 / toc(tStart);
    fpsLog(i) = fps;

    %% Visualize
    annotated = visualizer(procFrames{i}, trackBoxes, trackLabelCat, cfg, ...
                           'trackIDs', trackIDs, ...
                           'scores',   trackScores, ...
                           'fps',      fps, ...
                           'frameNum', i);

    % Store result
    results{i}.bboxes  = bboxes;
    results{i}.scores  = scores;
    results{i}.labels  = labels;
    results{i}.tracked = activeTracks;

    % Display live
    figure(hFig);
    imshow(annotated); drawnow;

    % Write to video
    if cfg.viz.saveVideo
        writeVideo(vWriter, annotated);
    end

    if mod(i,10) == 0
        fprintf('  Frame %d/%d  |  Detections: %d  |  Tracks: %d  |  FPS: %.1f\n', ...
            i, dataset.numFrames, size(bboxes,1), numel(activeTracks), fps);
    end
end

if cfg.viz.saveVideo
    close(vWriter);
    fprintf('\n[main_week2] Video saved: %s\n', cfg.viz.outputVideoFile);
end

%% Step 5: Performance summary
fprintf('\n--- STEP 4: Performance Summary ---\n');
avgFPS    = mean(fpsLog(fpsLog > 0));
totalDets = sum(cellfun(@(r) size(r.bboxes,1), results));
fprintf('  Avg FPS          : %.1f\n', avgFPS);
fprintf('  Total detections : %d across %d frames\n', totalDets, dataset.numFrames);
fprintf('  Total tracks created: %d\n', trackerState.nextID - 1);

%% Step 6: FPS plot
figure('Name','FPS Over Time','Position',[100,100,700,300]);
plot(fpsLog, 'b-', 'LineWidth', 1.5); hold on;
yline(avgFPS, 'r--', sprintf('Avg: %.1f FPS', avgFPS), 'LineWidth', 1.5);
xlabel('Frame'); ylabel('FPS');
title('Detection + Tracking Speed per Frame');
grid on; ylim([0, max(fpsLog)*1.2]);

%% Step 7: Save results for Week 3 evaluation
save(fullfile(cfg.resultsDir, 'week2_results.mat'), 'results', 'fpsLog', 'cfg');
fprintf('[main_week2] Results saved for Week 3 evaluation.\n');

fprintf('\n================================================\n');
fprintf('  Week 2 COMPLETE — next: main_week3.m\n');
fprintf('================================================\n');
