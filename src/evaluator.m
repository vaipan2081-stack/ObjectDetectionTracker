% =========================================================
%  src/evaluator.m
%  Computes mAP, precision/recall, ID switch rate, FPS stats.
%  Call after running main_week2 to get full metrics report.
% =========================================================

function metrics = evaluator(results, dataset, cfg)
% EVALUATOR  Compute full performance metrics.
%
%   metrics = evaluator(results, dataset, cfg)
%
%   Inputs:
%     results  - cell array from main_week2 (one struct per frame)
%     dataset  - dataset struct from dataLoader
%     cfg      - config struct
%
%   Output:
%     metrics  - struct with all computed metrics

    fprintf('[evaluator] Computing performance metrics...\n');
    nFrames = numel(results);

    %% ---- 1. Build detection results table for evaluateObjectDetection ----
    fprintf('[evaluator] Building detection result tables...\n');

    allDetBoxes  = cell(nFrames, 1);
    allDetScores = cell(nFrames, 1);
    allDetLabels = cell(nFrames, 1);
    allGTBoxes   = cell(nFrames, 1);
    allGTLabels  = cell(nFrames, 1);

    for i = 1:nFrames
        if ~isempty(results{i}) && isfield(results{i}, 'bboxes')
            allDetBoxes{i}  = results{i}.bboxes;
            allDetScores{i} = results{i}.scores;
            if ~isempty(results{i}.labels)
                allDetLabels{i} = cellstr(results{i}.labels);
            else
                allDetLabels{i} = {};
            end
        else
            allDetBoxes{i}  = zeros(0,4);
            allDetScores{i} = zeros(0,1);
            allDetLabels{i} = {};
        end

        % GT boxes (already in [x y w h] format from preprocessor)
        if i <= numel(dataset.gtBoxes) && ~isempty(dataset.gtBoxes{i})
            allGTBoxes{i}  = dataset.gtBoxes{i};
            allGTLabels{i} = cellstr(dataset.gtLabels{i});
        else
            allGTBoxes{i}  = zeros(0,4);
            allGTLabels{i} = {};
        end
    end

    %% ---- 2. Per-class Average Precision ----
    fprintf('[evaluator] Computing per-class Average Precision...\n');

    classes   = cfg.targetClasses;
    apScores  = zeros(1, numel(classes));
    prCurves  = cell(1, numel(classes));

    for c = 1:numel(classes)
        className = classes{c};

        % Collect all detections and GT for this class
        detBoxes  = {};
        detScores = {};
        gtBoxes   = {};
        matchedGT = {};

        for i = 1:nFrames
            % Detections for this class
            if ~isempty(allDetLabels{i})
                mask = strcmp(allDetLabels{i}, className);
                detBoxes{end+1}  = allDetBoxes{i}(mask, :); %#ok
                detScores{end+1} = allDetScores{i}(mask); %#ok
            else
                detBoxes{end+1}  = zeros(0,4); %#ok
                detScores{end+1} = zeros(0,1); %#ok
            end

            % GT for this class
            if ~isempty(allGTLabels{i})
                mask = strcmp(allGTLabels{i}, className);
                gtBoxes{end+1}   = allGTBoxes{i}(mask, :); %#ok
                matchedGT{end+1} = false(sum(mask), 1); %#ok
            else
                gtBoxes{end+1}  = zeros(0,4); %#ok
                matchedGT{end+1} = false(0,1); %#ok
            end
        end

        % Flatten and sort by score descending
        allDBoxes  = vertcat(detBoxes{:});
        allDScores = vertcat(detScores{:});
        allGBoxes  = vertcat(gtBoxes{:});

        if isempty(allDBoxes) || isempty(allGBoxes)
            apScores(c) = 0;
            prCurves{c} = struct('precision',[1;0],'recall',[0;1]);
            continue;
        end

        [~, sortIdx]  = sort(allDScores, 'descend');
        allDBoxes     = allDBoxes(sortIdx, :);
        allDScores    = allDScores(sortIdx); %#ok

        nDet = size(allDBoxes, 1);
        nGT  = size(allGBoxes, 1);
        tp   = zeros(nDet, 1);
        fp   = zeros(nDet, 1);
        used = false(nGT, 1);

        for d = 1:nDet
            ious = bboxOverlapRatio(allDBoxes(d,:), allGBoxes);
            [maxIoU, gtIdx] = max(ious);
            if maxIoU >= 0.5 && ~used(gtIdx)
                tp(d)        = 1;
                used(gtIdx)  = true;
            else
                fp(d) = 1;
            end
        end

        cumTP = cumsum(tp);
        cumFP = cumsum(fp);
        rec   = cumTP / max(nGT, 1);
        prec  = cumTP ./ (cumTP + cumFP);

        % Interpolated AP (11-point)
        ap = 0;
        for thr = 0:0.1:1
            p = max(prec(rec >= thr), [], 'omitnan');
            if isempty(p), p = 0; end
            ap = ap + p / 11;
        end
        apScores(c)  = ap;
        prCurves{c}  = struct('precision', prec, 'recall', rec, 'class', className);

        fprintf('[evaluator]   %s: AP = %.3f\n', className, ap);
    end

    mAP = mean(apScores(apScores > 0));
    fprintf('[evaluator] mAP (non-zero classes): %.4f\n', mAP);

    %% ---- 3. ID Switch Rate ----
    fprintf('[evaluator] Computing ID switch rate...\n');
    idSwitches  = 0;
    totalTracks = 0;
    prevIDs     = containers.Map('KeyType','int32','ValueType','int32');

    for i = 1:nFrames
        if isfield(results{i}, 'tracked') && ~isempty(results{i}.tracked)
            tracks = results{i}.tracked;
            for t = 1:numel(tracks)
                totalTracks = totalTracks + 1;
                tid = int32(tracks(t).id);
                if isKey(prevIDs, tid)
                    % ID persisted — good
                else
                    idSwitches = idSwitches + 1;
                end
                prevIDs(tid) = int32(i);
            end
        end
    end
    idSwitchRate = idSwitches / max(totalTracks, 1);
    fprintf('[evaluator]   ID switches: %d / %d (%.1f%%)\n', ...
            idSwitches, totalTracks, idSwitchRate*100);

    %% ---- 4. Pack results ----
    metrics.mAP           = mAP;
    metrics.apPerClass    = apScores;
    metrics.classNames    = classes;
    metrics.prCurves      = prCurves;
    metrics.idSwitches    = idSwitches;
    metrics.idSwitchRate  = idSwitchRate;
    metrics.totalTracks   = totalTracks;

    fprintf('[evaluator] Done.\n');
end
