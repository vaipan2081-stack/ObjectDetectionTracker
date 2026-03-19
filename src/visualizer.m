% =========================================================
%  src/visualizer.m
%  Draw bounding boxes, labels, and track IDs on frames.
%  Used for both GT preview (Week 1) and live tracking (Week 2).
% =========================================================

function outFrame = visualizer(frame, boxes, labels, cfg, varargin)
% VISUALIZER  Render bounding boxes and labels onto a frame.
%
%   outFrame = visualizer(frame, boxes, labels, cfg)
%   outFrame = visualizer(frame, boxes, labels, cfg, 'trackIDs', ids, 'fps', fps)
%
%   Inputs:
%     frame  - uint8 or single RGB image
%     boxes  - Nx4 [x y w h] bounding boxes (can be empty)
%     labels - Nx1 categorical or cell array of strings
%     cfg    - config struct
%
%   Optional name-value pairs:
%     'trackIDs'  - Nx1 numeric track IDs
%     'scores'    - Nx1 confidence scores
%     'fps'       - scalar FPS value to display
%     'frameNum'  - frame number to display
%
%   Output:
%     outFrame - uint8 annotated RGB image

    % Parse optional args
    p = inputParser;
    addParameter(p, 'trackIDs', []);
    addParameter(p, 'scores',   []);
    addParameter(p, 'fps',      []);
    addParameter(p, 'frameNum', []);
    parse(p, varargin{:});
    trackIDs = p.Results.trackIDs;
    scores   = p.Results.scores;
    fps      = p.Results.fps;
    frameNum = p.Results.frameNum;

    % Ensure uint8
    if isa(frame, 'single') || isa(frame, 'double')
        frame = uint8(frame * 255);
    end

    outFrame = frame;

    if isempty(boxes)
        outFrame = overlayHUD(outFrame, fps, frameNum, 0);
        return;
    end

    % Convert labels to cell of strings
    if iscategorical(labels)
        labelStrs = cellstr(labels);
    elseif ischar(labels)
        labelStrs = repmat({labels}, size(boxes,1), 1);
    else
        labelStrs = labels;
    end

    %% Draw each box
    for i = 1:size(boxes, 1)
        bbox     = round(boxes(i,:));
        labelStr = labelStrs{i};
        color    = getClassColor(labelStr, cfg);

        % Build display string
        if ~isempty(trackIDs) && numel(trackIDs) >= i
            dispStr = sprintf('ID:%d %s', trackIDs(i), labelStr);
        else
            dispStr = labelStr;
        end
        if ~isempty(scores) && numel(scores) >= i
            dispStr = sprintf('%s %.2f', dispStr, scores(i));
        end

        % Draw rectangle
        outFrame = drawBoundingBox(outFrame, bbox, color, cfg.viz.bboxLineWidth);

        % Draw label background + text
        outFrame = drawLabel(outFrame, bbox, dispStr, color, cfg.viz.fontSize);
    end

    %% Overlay HUD (FPS, frame number, detection count)
    outFrame = overlayHUD(outFrame, fps, frameNum, size(boxes,1));
end


% ---------------------------------------------------------
%  Draw a single bounding box rectangle
% ---------------------------------------------------------
function img = drawBoundingBox(img, bbox, color, lineWidth)
    x = max(1, bbox(1));
    y = max(1, bbox(2));
    w = bbox(3);
    h = bbox(4);
    H = size(img,1); W = size(img,2);

    x2 = min(W, x+w);
    y2 = min(H, y+h);

    colorU8 = uint8(color * 255);

    for k = 1:lineWidth
        % Top line
        if y-1+k >= 1 && y-1+k <= H
            img(y-1+k, x:x2, :) = repmat(reshape(colorU8,[1,1,3]), 1, x2-x+1, 1);
        end
        % Bottom line
        if y2-1+k >= 1 && y2-1+k <= H
            img(y2-1+k, x:x2, :) = repmat(reshape(colorU8,[1,1,3]), 1, x2-x+1, 1);
        end
        % Left line
        if x-1+k >= 1 && x-1+k <= W
            img(y:y2, x-1+k, :) = repmat(reshape(colorU8,[1,1,3]), y2-y+1, 1, 1);
        end
        % Right line
        if x2-1+k >= 1 && x2-1+k <= W
            img(y:y2, x2-1+k, :) = repmat(reshape(colorU8,[1,1,3]), y2-y+1, 1, 1);
        end
    end
end


% ---------------------------------------------------------
%  Draw label text above bounding box
% ---------------------------------------------------------
function img = drawLabel(img, bbox, labelStr, color, fontSize)
    % Insert text using MATLAB's insertText (Computer Vision Toolbox)
    try
        bgColor = uint8(color * 255);
        img = insertText(img, [bbox(1), max(1, bbox(2)-fontSize-4)], ...
            labelStr, ...
            'FontSize', fontSize, ...
            'BoxColor', bgColor, ...
            'BoxOpacity', 0.7, ...
            'TextColor', 'white');
    catch
        % Fallback: no text if toolbox unavailable
    end
end


% ---------------------------------------------------------
%  Overlay HUD: FPS, frame number, detection count
% ---------------------------------------------------------
function img = overlayHUD(img, fps, frameNum, numDets)
    try
        hudStr = '';
        if ~isempty(fps),      hudStr = [hudStr, sprintf('FPS: %.1f  ', fps)]; end
        if ~isempty(frameNum), hudStr = [hudStr, sprintf('Frame: %d  ', frameNum)]; end
        hudStr = [hudStr, sprintf('Dets: %d', numDets)];

        img = insertText(img, [10, 10], hudStr, ...
            'FontSize', 14, ...
            'BoxColor', [0 0 0], ...
            'BoxOpacity', 0.6, ...
            'TextColor', 'yellow');
    catch
        % Silently skip if insertText unavailable
    end
end


% ---------------------------------------------------------
%  Get color for a class label
% ---------------------------------------------------------
function color = getClassColor(labelStr, cfg)
    defaultColors = [
        1.0, 0.2, 0.2;   % red
        0.2, 0.6, 1.0;   % blue
        0.2, 1.0, 0.2;   % green
        1.0, 0.8, 0.0;   % yellow
        1.0, 0.4, 0.0;   % orange
        0.6, 0.2, 1.0;   % purple
        0.0, 0.8, 0.8;   % cyan
        1.0, 0.0, 0.6;   % pink
    ];

    try
        if isfield(cfg, 'viz') && isfield(cfg.viz, 'classColors') && ...
           isKey(cfg.viz.classColors, labelStr)
            color = cfg.viz.classColors(labelStr);
            return;
        end
    catch
    end

    % Hash label to a consistent color
    idx = mod(sum(double(labelStr)), size(defaultColors,1)) + 1;
    color = defaultColors(idx, :);
end
