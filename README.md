# Real-Time Object Detection & Multi-Object Tracking
### Built in MATLAB | YOLOv2 + Kalman Filter + Hungarian Algorithm | COCO Dataset

![Dashboard](results/dashboard.png)

---

## Results

| Metric | Value |
|--------|-------|
| mAP (IoU=0.50) | **66.1%** |
| Person AP | 52.8% |
| Car AP | 45.5% |
| Bus AP | 100% |
| CPU Speed | 2.3 FPS |
| GPU Speed (GTX 1650) | **8.1 FPS** (3.5x speedup) |
| Peak GPU FPS | 10.2 FPS |

---

## What This Project Does

This system watches a set of images or video frames, automatically detects objects like people, cars, and buses in each frame, and tracks them across frames — giving every object a unique persistent ID.

**The pipeline has 4 stages:**

```
COCO Dataset → Preprocess → YOLOv2 Detect → Kalman Track → Evaluate
```

**What makes it technically interesting:**

Detecting objects is easy. The hard part is knowing whether the person in frame 5 is the same person from frame 4. Two algorithms solve this:

- **Kalman Filter** — predicts where each object will be in the *next* frame before it is even detected. Like a goalkeeper who dives before the ball is kicked.
- **Hungarian Algorithm** — mathematically solves the assignment problem of matching predictions to new detections at minimum cost. Every object gets a unique ID that survives across frames.

---

## Architecture

```
ObjectDetectionTracker/
  main_week1.m          ← Data loading & preprocessing
  main_week2.m          ← Detection + tracking pipeline
  main_week3.m          ← Evaluation + dashboard
  config.m              ← All parameters in one place
  src/
    dataLoader.m        ← COCO / MOT17 / video / webcam
    preprocessor.m      ← Resize, normalize, clip boxes
    loadDetector.m      ← YOLOv2 model loader
    detector.m          ← YOLOv2 inference + NMS (GPU-enabled)
    initTracker.m       ← Initialize Kalman tracker state
    updateTracker.m     ← Kalman predict + Hungarian assign
    evaluator.m         ← mAP, precision/recall, ID switch rate
    visualizer.m        ← Draw boxes, labels, FPS overlay
  data/
    raw/coco/           ← Put COCO dataset here
  results/
    dashboard.png       ← Auto-generated performance dashboard
    tracked_output.mp4  ← Annotated output video
```

---

## Requirements

- MATLAB R2022b or later
- Deep Learning Toolbox
- Computer Vision Toolbox
- Image Processing Toolbox
- Statistics and Machine Learning Toolbox
- GPU recommended (NVIDIA CUDA) — CPU works but slower

---

## Quick Start

### 1. Check your environment
```matlab
checkToolboxes
```

### 2. Download COCO val2017 dataset
- Images: http://images.cocodataset.org/zips/val2017.zip
- Annotations: http://images.cocodataset.org/annotations/annotations_trainval2017.zip

Extract into:
```
data/raw/coco/
  val2017/
  annotations/
    instances_val2017.json
```

### 3. Run Week 1 — Data loading & visualization
```matlab
main_week1
```

### 4. Run Week 2 — Detection + tracking
```matlab
main_week2
```

### 5. Run Week 3 — Evaluation + dashboard
```matlab
main_week3
```

---

## Performance Dashboard

The dashboard is auto-generated after Week 3 and saved to `results/dashboard.png`.

It includes:
- FPS over time (CPU vs GPU comparison)
- Per-class Average Precision bar chart
- Precision-Recall curves by class
- Key metrics panel
- FPS distribution histogram
- Detections per frame

---

## GPU Acceleration

To enable GPU (recommended):

In `config.m`, set:
```matlab
cfg.useGPU = true;
```

| Mode | Avg FPS | Per Frame |
|------|---------|-----------|
| CPU | 2.3 FPS | ~0.43s |
| GTX 1650 GPU | 8.1 FPS | ~0.12s |
| Speedup | **3.5x** | — |

---

## Dataset

This project uses the [COCO 2017](https://cocodataset.org) validation set.
Tracked classes: `person`, `car`, `bicycle`, `motorbike`, `bus`, `truck`

---

## Author

**Vaibhav** — Data Engineer & AI Developer  
Specializing in intelligent automation, LLMs, and scalable data pipelines.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue)](https://linkedin.com/in/YOUR_PROFILE)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-black)](https://github.com/YOUR_USERNAME)

---

## License

MIT License — free to use, modify, and distribute.
