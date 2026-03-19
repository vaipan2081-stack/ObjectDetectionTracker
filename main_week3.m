% =========================================================
%  main_week3.m  —  Week 3: Evaluation + Dashboard
% =========================================================

clc; clear; close all;
fprintf('================================================\n');
fprintf('  Week 3: Evaluation + Performance Dashboard\n');
fprintf('================================================\n\n');

%% Step 0: Paths
addpath(fullfile(fileparts(mfilename('fullpath')), 'src'));

%% Step 1: Load config + Week 2 results
cfg     = config();
matFile = fullfile(cfg.resultsDir, 'week2_results.mat');
assert(isfile(matFile), 'Run main_week2.m first.');
load(matFile, 'results', 'fpsLog', 'cfg');
fprintf('[main_week3] Loaded %d frame results from Week 2.\n', numel(results));

%% Step 2: Reload dataset for GT
fprintf('\n--- STEP 1: Reloading dataset for GT comparison ---\n');
cfg.maxFrames = numel(results);
dataset = dataLoader(cfg);
[~, procBoxes] = preprocessor(dataset.frames, dataset.gtBoxes, cfg);
dataset.gtBoxes = procBoxes;

%% Step 3: Evaluate
fprintf('\n--- STEP 2: Computing Metrics ---\n');
metrics = evaluator(results, dataset, cfg);

%% Step 4: Print report
fprintf('\n========================================\n');
fprintf('  PERFORMANCE REPORT\n');
fprintf('========================================\n');
validFPS = fpsLog(fpsLog > 0);
fprintf('  mAP (IoU=0.50)     : %.4f  (%.1f%%)\n', metrics.mAP, metrics.mAP*100);
fprintf('  Avg FPS            : %.1f\n', mean(validFPS));
fprintf('  Min FPS            : %.1f\n', min(validFPS));
fprintf('  Max FPS            : %.1f\n', max(validFPS));
fprintf('  Total tracks       : %d\n',   metrics.totalTracks);
fprintf('  ID switches        : %d (%.1f%%)\n', metrics.idSwitches, metrics.idSwitchRate*100);
fprintf('\n  Per-class AP:\n');
for c = 1:numel(metrics.classNames)
    bar_str = repmat('|', 1, round(metrics.apPerClass(c)*20));
    fprintf('    %-12s  %.3f  %s\n', metrics.classNames{c}, metrics.apPerClass(c), bar_str);
end
fprintf('========================================\n\n');

%% Step 5: Color palette (safe — only as many colors as classes)
nC     = numel(metrics.classNames);
colors = lines(nC);

%% Step 6: PR Curves figure
fprintf('--- STEP 3: Plotting PR Curves ---\n');
figure('Name','Precision-Recall Curves','Position',[50,50,900,600],'Color','k');
legendEntries = {};
for c = 1:nC
    pr = metrics.prCurves{c};
    if numel(pr.recall) < 2, continue; end
    plot(pr.recall, pr.precision, '-', 'Color', colors(c,:), 'LineWidth', 2);
    hold on;
    legendEntries{end+1} = sprintf('%s (AP=%.3f)', metrics.classNames{c}, metrics.apPerClass(c)); %#ok
end
yline(metrics.mAP, '--w', sprintf('mAP = %.3f', metrics.mAP), ...
      'LineWidth',1.5,'LabelHorizontalAlignment','left');
xlabel('Recall','Color','w','FontSize',13);
ylabel('Precision','Color','w','FontSize',13);
title('Precision-Recall Curves by Class','Color','w','FontSize',15,'FontWeight','bold');
if ~isempty(legendEntries)
    legend(legendEntries,'Location','southwest','TextColor','w','Color','none','EdgeColor','none');
end
grid on; xlim([0 1]); ylim([0 1]);
set(gca,'Color','k','XColor','w','YColor','w','GridColor',[.3 .3 .3]);

%% Step 7: AP per class bar chart
figure('Name','AP per Class','Position',[100,100,700,400],'Color','k');
bh = bar(metrics.apPerClass, 'FaceColor','flat');
bh.CData = colors;   % assign all colors at once — no loop needed
set(gca,'XTickLabel',metrics.classNames,'XTickLabelRotation',20,...
    'Color','k','XColor','w','YColor','w','GridColor',[.3 .3 .3]);
ylabel('Average Precision','Color','w','FontSize',12);
title('Per-Class Average Precision','Color','w','FontSize',14,'FontWeight','bold');
yline(metrics.mAP,'--w',sprintf('mAP=%.3f',metrics.mAP),'LineWidth',1.5);
ylim([0 1]); grid on;

%% Step 8: FPS histogram
figure('Name','FPS Distribution','Position',[150,150,600,350],'Color','k');
histogram(validFPS,15,'FaceColor',[0.2 0.6 1.0],'EdgeColor','none');
xline(mean(validFPS),'--r',sprintf('Mean: %.1f FPS',mean(validFPS)),...
      'LineWidth',2,'LabelHorizontalAlignment','left');
xlabel('FPS','Color','w','FontSize',12);
ylabel('Frame count','Color','w','FontSize',12);
title('FPS Distribution','Color','w','FontSize',14,'FontWeight','bold');
set(gca,'Color','k','XColor','w','YColor','w'); grid on;

%% Step 9: 6-panel summary dashboard
fprintf('\n--- STEP 4: Building Summary Dashboard ---\n');
hDash = figure('Name','Project Dashboard','Position',[50,50,1200,700],...
               'Color',[0.08 0.08 0.12]);

% Panel 1: FPS over time
subplot(2,3,1);
plot(fpsLog,'b-','LineWidth',1.5); hold on;
yline(mean(validFPS),'r--','LineWidth',1.5);
title('FPS Over Time','Color','w','FontWeight','bold');
xlabel('Frame','Color','w'); ylabel('FPS','Color','w');
set(gca,'Color',[0.12 0.12 0.18],'XColor','w','YColor','w'); grid on;

% Panel 2: AP per class
subplot(2,3,2);
bh2 = bar(metrics.apPerClass,'FaceColor','flat');
bh2.CData = colors;
set(gca,'XTickLabel',metrics.classNames,'XTickLabelRotation',25,...
    'Color',[0.12 0.12 0.18],'XColor','w','YColor','w');
title('AP per Class','Color','w','FontWeight','bold');
ylabel('AP','Color','w'); ylim([0 1]); grid on;

% Panel 3: PR curve for best class
subplot(2,3,3);
[~, bestC] = max(metrics.apPerClass);
pr = metrics.prCurves{bestC};
if numel(pr.recall) >= 2
    plot(pr.recall, pr.precision,'-','Color',colors(bestC,:),'LineWidth',2);
end
title(sprintf('PR Curve: %s',metrics.classNames{bestC}),'Color','w','FontWeight','bold');
xlabel('Recall','Color','w'); ylabel('Precision','Color','w');
set(gca,'Color',[0.12 0.12 0.18],'XColor','w','YColor','w');
xlim([0 1]); ylim([0 1]); grid on;

% Panel 4: Key metrics text
subplot(2,3,4); axis off;
set(gca,'Color',[0.12 0.12 0.18]);
text(0.5,0.95,'KEY METRICS','Color','w','FontSize',14,'FontWeight','bold',...
    'HorizontalAlignment','center','Units','normalized');
mLines = {
    sprintf('mAP (IoU=0.50):  %.4f', metrics.mAP);
    sprintf('Avg FPS:         %.1f',  mean(validFPS));
    sprintf('Total tracks:    %d',    metrics.totalTracks);
    sprintf('ID switch rate:  %.1f%%',metrics.idSwitchRate*100);
    sprintf('Frames eval:     %d',    numel(results));
    sprintf('Classes:         %d',    nC);
};
for k = 1:numel(mLines)
    text(0.1, 0.80-(k-1)*0.12, mLines{k},'Color',[0.7 0.9 1.0],...
        'FontSize',11,'Units','normalized','FontName','Courier New');
end

% Panel 5: FPS histogram
subplot(2,3,5);
histogram(validFPS,12,'FaceColor',[0.2 0.7 0.4],'EdgeColor','none');
xline(mean(validFPS),'r--','LineWidth',1.5);
title('FPS Distribution','Color','w','FontWeight','bold');
xlabel('FPS','Color','w'); ylabel('Count','Color','w');
set(gca,'Color',[0.12 0.12 0.18],'XColor','w','YColor','w'); grid on;

% Panel 6: Detections per frame
subplot(2,3,6);
detCounts = cellfun(@(r) size(r.bboxes,1), results);
bar(detCounts,'FaceColor',[1.0 0.6 0.2],'EdgeColor','none');
title('Detections per Frame','Color','w','FontWeight','bold');
xlabel('Frame','Color','w'); ylabel('Count','Color','w');
set(gca,'Color',[0.12 0.12 0.18],'XColor','w','YColor','w'); grid on;

sgtitle('Real-Time Object Detection & Tracking — Performance Dashboard',...
        'Color','w','FontSize',15,'FontWeight','bold');

%% Step 10: Save outputs
if ~isfolder(cfg.resultsDir), mkdir(cfg.resultsDir); end
exportgraphics(hDash, fullfile(cfg.resultsDir,'dashboard.png'),'Resolution',150);
save(fullfile(cfg.resultsDir,'week3_metrics.mat'),'metrics','cfg');
fprintf('[main_week3] Dashboard saved: results/dashboard.png\n');
fprintf('[main_week3] Metrics saved:   results/week3_metrics.mat\n');

fprintf('\n================================================\n');
fprintf('  Week 3 COMPLETE — Project finished!\n');
fprintf('  Check results/ folder for all outputs.\n');
fprintf('================================================\n');
