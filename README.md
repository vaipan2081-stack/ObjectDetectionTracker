# Real-Time Object Detection & Tracking — MATLAB

> A production-quality computer vision portfolio project built in MATLAB.  
> Detects and tracks multiple objects in real-world video using YOLOv2 + Kalman Filter + Hungarian Algorithm.

---

## Quick Start

### 1. Check Your Environment
Open MATLAB, navigate to this folder, and run:
```matlab
checkToolboxes
```
You need: **Deep Learning Toolbox**, **Computer Vision Toolbox**, **Image Processing Toolbox**

### 2. Download the Dataset (COCO val2017 — recommended)
```
https://cocodataset.org/#download
→ 2017 Val images [5K/1GB]
→ 2017 Val/Train annotations [241MB]
```
Extract into: `data/raw/coco/`

Expected structure:
```
data/raw/coco/
  val2017/              ← image files
  annotations/
    instances_val2017.json
```

### 3. Configure the Project
Edit `config.m`:
- Set `cfg.datasetType = 'coco'`
- Verify `cfg.cocoImgDir` and `cfg.cocoAnnFile` paths

### 4. Run Week 1 (Data + Preprocessing)
```matlab
main_week1
```
Expected output: grid of 20 annotated sample frames + class distribution chart

---

## Project Structure
```
ObjectDetectionTracker/
  checkToolboxes.m        ← Run first
  config.m                ← All parameters
  main_week1.m            ← Week 1: data loading & preprocessing
  main_week2.m            ← Week 2: detection + tracking  [coming next]
  main_week3.m            ← Week 3: evaluation + dashboard [coming next]
  /src
    dataLoader.m          ← COCO / MOT17 / video / webcam ingestion
    preprocessor.m        ← Resize, normalize, clip boxes
    visualizer.m          ← Draw boxes, labels, track IDs
    detector.m            ← YOLOv2 inference + NMS       [Week 2]
    tracker.m             ← Kalman filter + Hungarian    [Week 2]
    evaluator.m           ← mAP, precision/recall        [Week 3]
  /data/raw               ← Put your dataset here
  /data/processed         ← Auto-generated preprocessed frames
  /results                ← Saved outputs, reports, videos
  /dashboard              ← MATLAB App Designer dashboard [Week 3]
```

---

## Weekly Build Plan

| Week | Focus | Entry Point |
|------|-------|-------------|
| 1 | Data loading, preprocessing, GT visualization | `main_week1.m` |
| 2 | YOLOv2 detection + Kalman tracker | `main_week2.m` |
| 3 | mAP evaluation + App Designer dashboard | `main_week3.m` |

---

## Requirements
- MATLAB R2022b or later
- Deep Learning Toolbox
- Computer Vision Toolbox
- Image Processing Toolbox
- Statistics and Machine Learning Toolbox (Week 3)

---

## Dataset Options

| Dataset | Type | Link |
|---------|------|------|
| COCO 2017 | Images + annotations | https://cocodataset.org |
| MOT17 | Tracking benchmark video | https://motchallenge.net |
| UA-DETRAC | Vehicle surveillance | https://detrac-db.rit.albany.edu |
