% =========================================================
%  src/preprocessor.m
%  Resizes, normalizes, and optionally augments frames.
%  Also rescales ground truth boxes to match new image size.
% =========================================================

function [procFrames, procBoxes] = preprocessor(frames, gtBoxes, cfg)
% PREPROCESSOR  Prepare raw frames for model inference.
%
%   [procFrames, procBoxes] = preprocessor(frames, gtBoxes, cfg)
%
%   Inputs:
%     frames    - cell array of uint8 RGB images (any size)
%     gtBoxes   - cell array of [x y w h] bounding boxes
%     cfg       - config struct from config.m
%
%   Outputs:
%     procFrames - cell array of preprocessed frames (cfg.inputSize)
%     procBoxes  - cell array of rescaled GT boxes

    targetH = cfg.inputSize(1);
    targetW = cfg.inputSize(2);
    N = numel(frames);

    procFrames = cell(1, N);
    procBoxes  = cell(1, N);

    fprintf('[preprocessor] Processing %d frames -> [%dx%d]...\n', N, targetH, targetW);

    for i = 1:N
        frame = frames{i};
        origH = size(frame, 1);
        origW = size(frame, 2);

        %% 1. Resize
        resized = imresize(frame, [targetH, targetW]);

        %% 2. Ensure RGB uint8
        if size(resized, 3) == 1
            resized = repmat(resized, [1 1 3]);
        end

        %% 3. Normalize to [0, 1] as single precision
        if cfg.normalize
            procFrames{i} = single(resized) / 255.0;
        else
            procFrames{i} = single(resized);
        end

        %% 4. Rescale bounding boxes to new size
        if ~isempty(gtBoxes{i})
            scaleX = targetW / origW;
            scaleY = targetH / origH;
            boxes  = gtBoxes{i};
            boxes(:,1) = boxes(:,1) * scaleX;   % x
            boxes(:,2) = boxes(:,2) * scaleY;   % y
            boxes(:,3) = boxes(:,3) * scaleX;   % width
            boxes(:,4) = boxes(:,4) * scaleY;   % height
            procBoxes{i} = clipBoxes(boxes, targetW, targetH);
        else
            procBoxes{i} = [];
        end
    end

    fprintf('[preprocessor] Done.\n');
end


% ---------------------------------------------------------
%  Clip boxes to stay within image boundaries
% ---------------------------------------------------------
function boxes = clipBoxes(boxes, W, H)
    % Ensure x >= 1
    boxes(:,1) = max(boxes(:,1), 1);
    boxes(:,2) = max(boxes(:,2), 1);
    % Ensure x + w <= W
    overflow = (boxes(:,1) + boxes(:,3)) - W;
    overflow(overflow < 0) = 0;
    boxes(:,3) = boxes(:,3) - overflow;
    % Ensure y + h <= H
    overflow = (boxes(:,2) + boxes(:,4)) - H;
    overflow(overflow < 0) = 0;
    boxes(:,4) = boxes(:,4) - overflow;
    % Remove degenerate boxes (width or height <= 0)
    valid = boxes(:,3) > 0 & boxes(:,4) > 0;
    boxes = boxes(valid, :);
end
