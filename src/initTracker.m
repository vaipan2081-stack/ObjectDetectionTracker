% =========================================================
%  src/initTracker.m
%  Create an empty tracker state.
% =========================================================

function trackerState = initTracker(cfg)
    trackerState.tracks     = [];
    trackerState.nextID     = 1;
    trackerState.cfg        = cfg;
    trackerState.frameCount = 0;
end
