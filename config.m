% =========================================================
%  config.m
%  Central configuration — all parameters in one place.
% =========================================================

function cfg = config()

%% ---- PATHS -----------------------------------------------
cfg.rootDir      = fileparts(mfilename('fullpath'));
cfg.dataRaw      = fullfile(cfg.rootDir, 'data', 'raw');
cfg.dataProc     = fullfile(cfg.rootDir, 'data', 'processed');
cfg.resultsDir   = fullfile(cfg.rootDir, 'results');

%% ---- DATASET ---------------------------------------------
cfg.datasetType  = 'coco';
cfg.cocoImgDir   = fullfile(cfg.dataRaw, 'coco', 'val2017');
cfg.cocoAnnFile  = fullfile(cfg.dataRaw, 'coco', 'annotations', 'instances_val2017.json');
cfg.mot17SeqDir  = fullfile(cfg.dataRaw, 'MOT17', 'MOT17-04-DPM');
cfg.videoFile    = fullfile(cfg.dataRaw, 'my_video.mp4');

%% ---- PREPROCESSING ---------------------------------------
cfg.inputSize    = [416, 416];
cfg.normalize    = true;
cfg.maxFrames    = 500;
cfg.batchSize    = 8;

%% ---- DETECTION -------------------------------------------
cfg.modelName    = 'darknet19-coco';
cfg.confThresh   = 0.40;
cfg.iouThresh    = 0.45;
cfg.maxDets      = 100;
cfg.useGPU       = true;   % Set to false to force CPU
cfg.targetClasses = {'person', 'car', 'bicycle', 'motorbike', 'bus', 'truck'};

%% ---- TRACKING (Kalman Filter) ----------------------------
cfg.kalman.motionNoise      = [25, 25, 10, 10];
cfg.kalman.measurementNoise = [25, 25];
cfg.kalman.initError        = [200, 50];
cfg.track.costThresh        = 0.5;
cfg.track.maxMissedFrames   = 10;
cfg.track.minHitStreak      = 3;

%% ---- EVALUATION ------------------------------------------
cfg.eval.iouThresholds = 0.5:0.05:0.95;
cfg.eval.maxDets       = [1, 10, 100];
cfg.eval.saveReport    = true;

%% ---- VISUALIZATION ---------------------------------------
cfg.viz.showConfidence  = true;
cfg.viz.showTrackID     = true;
cfg.viz.showFPS         = true;
cfg.viz.bboxLineWidth   = 2;
cfg.viz.fontSize        = 12;
cfg.viz.saveVideo       = true;
cfg.viz.outputVideoFile = fullfile(cfg.resultsDir, 'tracked_output.mp4');
cfg.viz.classColors = containers.Map(...
    {'person','car','bicycle','motorbike','bus','truck'}, ...
    {[1.0 0.2 0.2], [0.2 0.6 1.0], [0.2 1.0 0.2], ...
     [1.0 0.8 0.0], [1.0 0.4 0.0], [0.6 0.2 1.0]});

fprintf('[config.m] Loaded. Dataset: %s | Model: %s\n', cfg.datasetType, cfg.modelName);

end
