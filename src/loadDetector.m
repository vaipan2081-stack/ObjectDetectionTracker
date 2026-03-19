% =========================================================
%  src/loadDetector.m
%  Loads YOLOv2 pre-trained detector (R2025b compatible)
% =========================================================

function detector = loadDetector(cfg)

    fprintf('[loadDetector] Loading model for R2025b...\n');

    % R2025b valid names: 'darknet19-coco' | 'tiny-yolov2-coco'
    modelNames = {'darknet19-coco', 'tiny-yolov2-coco'};

    detector = [];
    for i = 1:numel(modelNames)
        try
            fprintf('[loadDetector] Trying: %s\n', modelNames{i});
            detector = yolov2ObjectDetector(modelNames{i});
            fprintf('[loadDetector] Loaded: %s\n', modelNames{i});
            fprintf('[loadDetector] Classes: %d\n', numel(detector.ClassNames));
            return;
        catch e
            fprintf('[loadDetector] Failed: %s\n', e.message);
        end
    end

    % Nothing worked
    error(['Could not load any YOLOv2 model.\n' ...
           'In MATLAB: Home > Add-Ons > search "YOLO v2" > install\n' ...
           'Then re-run main_week2.']);
end
