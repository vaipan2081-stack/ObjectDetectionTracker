% =========================================================
%  src/tracker.m
%  Multi-object tracker: Kalman Filter + Hungarian Algorithm.
%  Usage:
%    state = initTracker(cfg)
%    [state, active] = updateTracker(state, bboxes, scores, labels)
% =========================================================

function trackerState = initTracker(cfg)
    trackerState.tracks     = [];
    trackerState.nextID     = 1;
    trackerState.cfg        = cfg;
    trackerState.frameCount = 0;
end


function [trackerState, activeTracks] = updateTracker(trackerState, bboxes, scores, labels)
    cfg = trackerState.cfg;
    trackerState.frameCount = trackerState.frameCount + 1;

    %% 1. Predict next position for each track
    for i = 1:numel(trackerState.tracks)
        trackerState.tracks(i) = predictTrack(trackerState.tracks(i));
    end

    %% 2. Match detections to tracks via Hungarian algorithm
    nTracks = numel(trackerState.tracks);
    nDets   = size(bboxes, 1);
    unassignedDets = (1:nDets)';
    assignedTracks = [];
    assignedDets   = [];

    if nTracks > 0 && nDets > 0
        costMatrix = ones(nTracks, nDets);
        for i = 1:nTracks
            for j = 1:nDets
                iou = bboxOverlapRatio(trackerState.tracks(i).bbox, bboxes(j,:));
                costMatrix(i,j) = 1 - iou;
            end
        end
        [assignments, ~, unassignedDets] = ...
            assignDetectionsToTracks(costMatrix, cfg.track.costThresh);
        if ~isempty(assignments)
            assignedTracks = assignments(:,1);
            assignedDets   = assignments(:,2);
        end
    end

    %% 3. Update matched tracks
    for k = 1:numel(assignedTracks)
        i = assignedTracks(k);
        j = assignedDets(k);
        trackerState.tracks(i) = updateTrackWithDetection( ...
            trackerState.tracks(i), bboxes(j,:), scores(j), labels(j));
    end

    %% 4. Mark unmatched tracks as missed
    for i = 1:nTracks
        if ~ismember(i, assignedTracks)
            trackerState.tracks(i).missedFrames = ...
                trackerState.tracks(i).missedFrames + 1;
            trackerState.tracks(i).hitStreak = 0;
        end
    end

    %% 5. Create new tracks for unmatched detections
    for jj = 1:numel(unassignedDets)
        j = unassignedDets(jj);
        trackerState = createTrack(trackerState, bboxes(j,:), scores(j), labels(j));
    end

    %% 6. Remove stale tracks
    if ~isempty(trackerState.tracks)
        keep = arrayfun(@(t) t.missedFrames <= cfg.track.maxMissedFrames, ...
                        trackerState.tracks);
        trackerState.tracks = trackerState.tracks(keep);
    end

    %% 7. Return confirmed active tracks only
    activeTracks = [];
    for i = 1:numel(trackerState.tracks)
        t = trackerState.tracks(i);
        if t.hitStreak >= cfg.track.minHitStreak && t.missedFrames == 0
            if isempty(activeTracks)
                activeTracks = t;
            else
                activeTracks(end+1) = t; %#ok
            end
        end
    end
end


function trackerState = createTrack(trackerState, bbox, score, label)
    cfg = trackerState.cfg;
    t.id           = trackerState.nextID;
    t.bbox         = bbox;
    t.score        = double(score);
    t.label        = label;
    t.age          = 1;
    t.hitStreak    = 1;
    t.missedFrames = 0;
    centroid = [bbox(1)+bbox(3)/2, bbox(2)+bbox(4)/2];
    try
        t.kalman = configureKalmanFilter('ConstantVelocity', ...
            centroid, cfg.kalman.initError, ...
            cfg.kalman.motionNoise(1:2), ...
            cfg.kalman.measurementNoise(1));
    catch
        t.kalman = [];
    end
    trackerState.nextID = trackerState.nextID + 1;
    if isempty(trackerState.tracks)
        trackerState.tracks = t;
    else
        trackerState.tracks(end+1) = t;
    end
end


function track = predictTrack(track)
    if ~isempty(track.kalman)
        try
            pred = predict(track.kalman);
            w = track.bbox(3); h = track.bbox(4);
            track.bbox(1) = pred(1) - w/2;
            track.bbox(2) = pred(2) - h/2;
        catch; end
    end
    track.age = track.age + 1;
end


function track = updateTrackWithDetection(track, bbox, score, label)
    track.bbox         = bbox;
    track.score        = double(score);
    track.label        = label;
    track.missedFrames = 0;
    track.hitStreak    = track.hitStreak + 1;
    if ~isempty(track.kalman)
        try
            centroid = [bbox(1)+bbox(3)/2, bbox(2)+bbox(4)/2];
            correct(track.kalman, centroid);
        catch; end
    end
end
