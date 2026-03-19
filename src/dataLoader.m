% =========================================================
%  src/dataLoader.m
%  Loads frames + ground truth from COCO, MOT17, or video.
%  Returns a unified struct that all downstream modules use.
% =========================================================

function dataset = dataLoader(cfg)
% DATALOADER  Load images/video and ground truth annotations.
%
%   dataset = dataLoader(cfg)
%
%   Returns dataset struct with fields:
%     .frames     - cell array of RGB images (H x W x 3, uint8)
%     .frameIDs   - numeric array of frame indices
%     .gtBoxes    - cell array of [x y w h] ground truth boxes per frame
%     .gtLabels   - cell array of categorical label arrays per frame
%     .numFrames  - total number of frames loaded
%     .imageSize  - [height, width] of original frames
%     .source     - string describing the data source

    fprintf('[dataLoader] Loading dataset: %s\n', cfg.datasetType);

    switch lower(cfg.datasetType)
        case 'coco'
            dataset = loadCOCO(cfg);
        case 'mot17'
            dataset = loadMOT17(cfg);
        case 'custom_video'
            dataset = loadVideo(cfg);
        case 'webcam'
            dataset = loadWebcam(cfg);
        otherwise
            error('[dataLoader] Unknown datasetType: %s', cfg.datasetType);
    end

    fprintf('[dataLoader] Loaded %d frames from %s\n', dataset.numFrames, dataset.source);
end


% ---------------------------------------------------------
%  COCO 2017 Loader
% ---------------------------------------------------------
function dataset = loadCOCO(cfg)
    % Check paths exist
    assert(isfolder(cfg.cocoImgDir), ...
        '[dataLoader] COCO image dir not found:\n  %s\nDownload from: https://cocodataset.org/#download', cfg.cocoImgDir);
    assert(isfile(cfg.cocoAnnFile), ...
        '[dataLoader] COCO annotation file not found:\n  %s', cfg.cocoAnnFile);

    fprintf('[dataLoader] Reading COCO annotations...\n');
    annData = jsondecode(fileread(cfg.cocoAnnFile));

    % Build image ID -> filename map
    imgMap = containers.Map('KeyType','int64','ValueType','any');
    for i = 1:numel(annData.images)
        img = annData.images(i);
        imgMap(img.id) = img;
    end

    % Build category ID -> name map
    catMap = containers.Map('KeyType','int64','ValueType','char');
    for i = 1:numel(annData.categories)
        catMap(annData.categories(i).id) = annData.categories(i).name;
    end

    % Group annotations by image ID
    annByImg = containers.Map('KeyType','int64','ValueType','any');
    for i = 1:numel(annData.annotations)
        ann = annData.annotations(i);
        if ~isKey(annByImg, ann.image_id)
            annByImg(ann.image_id) = {};
        end
        annByImg(ann.image_id) = [annByImg(ann.image_id), {ann}];
    end

    % Collect unique image IDs that have annotations
    imageIDs = keys(annByImg);
    maxN = min(cfg.maxFrames, numel(imageIDs));
    imageIDs = imageIDs(1:maxN);

    frames   = cell(1, maxN);
    gtBoxes  = cell(1, maxN);
    gtLabels = cell(1, maxN);
    frameIDs = zeros(1, maxN);
    imgSize  = [];

    fprintf('[dataLoader] Loading %d COCO images...\n', maxN);
    for i = 1:maxN
        imgID   = imageIDs{i};
        imgInfo = imgMap(imgID);
        imgPath = fullfile(cfg.cocoImgDir, imgInfo.file_name);

        if ~isfile(imgPath)
            warning('[dataLoader] Image not found, skipping: %s', imgPath);
            continue;
        end

        img = imread(imgPath);
        if size(img, 3) == 1
            img = repmat(img, [1 1 3]);   % grayscale -> RGB
        end

        frames{i}   = img;
        frameIDs(i) = imgID;
        if isempty(imgSize)
            imgSize = [size(img,1), size(img,2)];
        end

        % Parse annotations for this image
        boxes  = [];
        labels = {};
        if isKey(annByImg, imgID)
            anns = annByImg(imgID);
            for j = 1:numel(anns)
                ann = anns{j};
                if ~isfield(ann,'bbox') || ann.iscrowd == 1, continue; end
                catName = catMap(ann.category_id);
                % Only keep target classes
                if ismember(catName, cfg.targetClasses)
                    bbox = ann.bbox;   % [x, y, width, height] COCO format
                    boxes  = [boxes; bbox(1), bbox(2), bbox(3), bbox(4)]; %#ok
                    labels = [labels; {catName}]; %#ok
                end
            end
        end

        gtBoxes{i}  = boxes;
        gtLabels{i} = categorical(labels);

        if mod(i, 100) == 0
            fprintf('[dataLoader]   ...%d / %d images loaded\n', i, maxN);
        end
    end

    dataset.frames    = frames;
    dataset.frameIDs  = frameIDs;
    dataset.gtBoxes   = gtBoxes;
    dataset.gtLabels  = gtLabels;
    dataset.numFrames = maxN;
    dataset.imageSize = imgSize;
    dataset.source    = sprintf('COCO val2017 (%d images)', maxN);
end


% ---------------------------------------------------------
%  MOT17 Loader (image sequence format)
% ---------------------------------------------------------
function dataset = loadMOT17(cfg)
    imgDir = fullfile(cfg.mot17SeqDir, 'img1');
    gtFile = fullfile(cfg.mot17SeqDir, 'gt', 'gt.txt');

    assert(isfolder(imgDir), '[dataLoader] MOT17 img dir not found: %s', imgDir);

    imgFiles = dir(fullfile(imgDir, '*.jpg'));
    maxN     = min(cfg.maxFrames, numel(imgFiles));

    % Load ground truth: [frame, id, x, y, w, h, conf, class, visibility]
    gtData = [];
    if isfile(gtFile)
        gtData = load(gtFile);   % works for space-delimited numeric
    end

    frames   = cell(1, maxN);
    gtBoxes  = cell(1, maxN);
    gtLabels = cell(1, maxN);
    frameIDs = (1:maxN);
    imgSize  = [];

    fprintf('[dataLoader] Loading %d MOT17 frames from %s...\n', maxN, cfg.mot17SeqDir);
    for i = 1:maxN
        img = imread(fullfile(imgDir, imgFiles(i).name));
        if size(img,3) == 1, img = repmat(img,[1 1 3]); end
        frames{i} = img;
        if isempty(imgSize), imgSize = [size(img,1), size(img,2)]; end

        if ~isempty(gtData)
            rows = gtData(gtData(:,1)==i & gtData(:,7)==1, :);
            gtBoxes{i}  = rows(:, 3:6);   % [x y w h]
            gtLabels{i} = repmat(categorical({'person'}), size(rows,1), 1);
        else
            gtBoxes{i}  = [];
            gtLabels{i} = categorical({});
        end
    end

    dataset.frames    = frames;
    dataset.frameIDs  = frameIDs;
    dataset.gtBoxes   = gtBoxes;
    dataset.gtLabels  = gtLabels;
    dataset.numFrames = maxN;
    dataset.imageSize = imgSize;
    dataset.source    = sprintf('MOT17 sequence: %s', cfg.mot17SeqDir);
end


% ---------------------------------------------------------
%  Video File Loader
% ---------------------------------------------------------
function dataset = loadVideo(cfg)
    assert(isfile(cfg.videoFile), '[dataLoader] Video file not found: %s', cfg.videoFile);

    v    = VideoReader(cfg.videoFile);
    maxN = min(cfg.maxFrames, floor(v.Duration * v.FrameRate));

    frames   = cell(1, maxN);
    gtBoxes  = cell(1, maxN);
    gtLabels = cell(1, maxN);
    frameIDs = (1:maxN);
    imgSize  = [];

    fprintf('[dataLoader] Reading %d frames from video: %s\n', maxN, cfg.videoFile);
    i = 0;
    while hasFrame(v) && i < maxN
        i = i + 1;
        frame = readFrame(v);
        frames{i} = frame;
        if isempty(imgSize), imgSize = [size(frame,1), size(frame,2)]; end
        gtBoxes{i}  = [];   % No GT for raw video
        gtLabels{i} = categorical({});
    end

    dataset.frames    = frames(1:i);
    dataset.frameIDs  = frameIDs(1:i);
    dataset.gtBoxes   = gtBoxes(1:i);
    dataset.gtLabels  = gtLabels(1:i);
    dataset.numFrames = i;
    dataset.imageSize = imgSize;
    dataset.source    = sprintf('Video: %s', cfg.videoFile);
end


% ---------------------------------------------------------
%  Webcam Live Loader (returns a live capture handle)
% ---------------------------------------------------------
function dataset = loadWebcam(cfg)
    fprintf('[dataLoader] Initializing webcam...\n');
    cam = webcam();   % requires MATLAB Support Package for USB Webcams

    % Capture a preview to get size
    preview_frame = snapshot(cam);
    imgSize = [size(preview_frame,1), size(preview_frame,2)];

    dataset.frames    = {};           % empty — frames read live in main loop
    dataset.frameIDs  = [];
    dataset.gtBoxes   = {};
    dataset.gtLabels  = {};
    dataset.numFrames = Inf;          % live stream = infinite
    dataset.imageSize = imgSize;
    dataset.source    = 'Webcam (live)';
    dataset.camHandle = cam;          % caller uses this to grab frames

    fprintf('[dataLoader] Webcam ready. Resolution: %dx%d\n', imgSize(2), imgSize(1));
end
