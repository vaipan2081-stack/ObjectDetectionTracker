% =========================================================
%  src/detector.m
%  Runs YOLOv2 inference on a single frame.
%  GPU-enabled when cfg.useGPU = true.
% =========================================================

function [bboxes, scores, labels] = detector(frame, net, cfg)

    % Convert to uint8 if normalized
    if isa(frame, 'single') || isa(frame, 'double')
        frameIn = uint8(frame * 255);
    else
        frameIn = frame;
    end

    % Choose execution environment
    if isfield(cfg, 'useGPU') && cfg.useGPU
        execEnv = 'gpu';
    else
        execEnv = 'cpu';
    end

    % Run YOLOv2 inference
    [bboxes, scores, labels] = detect(net, frameIn, ...
        'Threshold',            cfg.confThresh, ...
        'SelectStrongest',      true, ...
        'ExecutionEnvironment', execEnv);

    % Filter to target classes only
    if ~isempty(bboxes) && ~isempty(cfg.targetClasses)
        keep   = ismember(cellstr(labels), cfg.targetClasses);
        bboxes = bboxes(keep, :);
        scores = scores(keep);
        labels = labels(keep);
    end

    % Cap at maxDets
    if size(bboxes, 1) > cfg.maxDets
        [scores, idx] = sort(scores, 'descend');
        idx    = idx(1:cfg.maxDets);
        bboxes = bboxes(idx, :);
        scores = scores(1:cfg.maxDets);
        labels = labels(idx);
    end
end
