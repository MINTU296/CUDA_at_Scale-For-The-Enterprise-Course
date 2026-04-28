# Submission Guide

The course requires a compressed archive (tar.gz or zip) containing **the project plus evidence the code ran**: build/run logs and clearly-named before/after images.

This repo doesn't yet have GPU run evidence. Follow the three steps below to get it, then build the submission archive.

---

## Step 1 — Run on a CUDA host

Open `colab/run_on_colab.ipynb` in Google Colab (free Tesla T4 runtime is enough), or run `colab/setup_and_run.sh` directly on any Linux machine that has the CUDA Toolkit installed at `/usr/local/cuda`.

The script:

1. Verifies `nvidia-smi` / `nvcc` and writes `logs/system.log`.
2. Fetches the NVIDIA NPP helper headers (`Exceptions.h`, `ImageIO.h`, `ImagesCPU.h`, `ImagesNPP.h`, `helper_cuda.h`, `helper_string.h`) from the `cuda-samples` repo into `include/` — these are required by `src/imageRotationNPP.cpp` but are not bundled here.
3. Installs `libfreeimage-dev` (used by `npp::loadImage` / `saveImage`) and `imagemagick`.
4. Converts `data/Lena.png` → `data/Lena.pgm` (the program's IO helpers only support PGM).
5. Builds: `make clean && make all` → `logs/build.log`.
6. Runs: `./bin/imageRotationNPP --input data/Lena.pgm --output data/Lena_rotated.pgm` → `logs/run.log`.
7. Stages clearly-named evidence in `artifacts/`:
   - `before_lena_grayscale.png` / `.pgm`
   - `after_lena_rotated_45deg.png` / `.pgm`

## Step 2 — Pull the evidence back to your local repo

If you ran in Colab, the last cell of the notebook downloads `evidence.zip`. Unpack it at the repo root so that `logs/` and `artifacts/` end up populated:

```bash
cd /path/to/CUDA-at-Scale-For-The_Enterprise_CourseProject
unzip -o ~/Downloads/evidence.zip
```

## Step 3 — Build the submission archive

```bash
bash package_submission.sh
```

The script refuses to run unless the required evidence files are present and non-empty. It produces, in the repo's parent directory:

- `imageRotationNPP_submission_<UTC-timestamp>.tar.gz`
- `imageRotationNPP_submission_<UTC-timestamp>.zip`

Either is a valid course submission (the course allows tar.gz or zip; pick one).

---

## What's in the submission archive

- All source under `src/`
- `Makefile`, `run.sh`, `INSTALL`, `LICENSE`, `README.md`
- `colab/setup_and_run.sh` and `colab/run_on_colab.ipynb` — so the grader can re-run the experiment
- `data/Lena.png` (and `Lena.pgm` if generated)
- `logs/build.log`, `logs/run.log`, `logs/system.log`
- `artifacts/before_lena_grayscale.{png,pgm}`, `artifacts/after_lena_rotated_45deg.{png,pgm}`

Excluded: `.git/`, `.claude/`, `.DS_Store`, the compiled `bin/imageRotationNPP` binary (regenerable, large, host-specific).
