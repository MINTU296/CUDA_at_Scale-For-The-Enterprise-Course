#!/usr/bin/env bash
# Build + run + capture artifacts for the imageRotationNPP project on a
# CUDA-capable Linux host (e.g. Google Colab GPU runtime, Coursera lab,
# any Linux box with the CUDA Toolkit at /usr/local/cuda).
#
# Run from the repo root:  bash colab/setup_and_run.sh
#
# Outputs:
#   logs/build.log
#   logs/run.log
#   logs/system.log
#   artifacts/before_lena_grayscale.pgm
#   artifacts/before_lena_grayscale.png
#   artifacts/after_lena_rotated_45deg.pgm
#   artifacts/after_lena_rotated_45deg.png

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

mkdir -p logs artifacts include

ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
log() { echo "[$(ts)] $*"; }

# ---------------------------------------------------------------------------
# 0. System info
# ---------------------------------------------------------------------------
{
  echo "=== uname ==="; uname -a
  echo "=== nvidia-smi ==="; nvidia-smi || echo "nvidia-smi not available"
  echo "=== nvcc --version ==="; /usr/local/cuda/bin/nvcc --version || echo "nvcc not found"
  echo "=== NPP libs present ==="
  ls /usr/local/cuda/lib64/libnpp* 2>&1 || true
} | tee logs/system.log

# ---------------------------------------------------------------------------
# 1. Fetch NVIDIA helper headers if not already present
# ---------------------------------------------------------------------------
need_headers=0
for h in Exceptions.h ImageIO.h ImagesCPU.h ImagesNPP.h helper_cuda.h helper_string.h; do
  if [[ ! -f "include/$h" ]]; then need_headers=1; break; fi
done

if [[ $need_headers -eq 1 ]]; then
  log "Fetching NPP helper headers from NVIDIA cuda-samples (v11.8 tag, last release with the UtilNPP helpers)"
  tmp="$(mktemp -d)"
  git clone --depth 1 --branch v11.8 https://github.com/NVIDIA/cuda-samples.git "$tmp/cuda-samples" >/dev/null 2>&1 \
    || git clone --depth 1 https://github.com/NVIDIA/cuda-samples.git "$tmp/cuda-samples"

  cp "$tmp/cuda-samples/Common/UtilNPP/Exceptions.h" include/
  cp "$tmp/cuda-samples/Common/UtilNPP/ImageIO.h"    include/
  cp "$tmp/cuda-samples/Common/UtilNPP/ImagesCPU.h"  include/
  cp "$tmp/cuda-samples/Common/UtilNPP/ImagesNPP.h"  include/
  cp "$tmp/cuda-samples/Common/UtilNPP/Image.h"      include/ 2>/dev/null || true
  cp "$tmp/cuda-samples/Common/UtilNPP/ImagePacked.h" include/ 2>/dev/null || true
  cp "$tmp/cuda-samples/Common/helper_cuda.h"        include/
  cp "$tmp/cuda-samples/Common/helper_string.h"      include/
  rm -rf "$tmp"
fi

# FreeImage is required by ImageIO.h (npp::loadImage / saveImage).
log "Ensuring FreeImage headers/libs are installed"
if ! dpkg -s libfreeimage-dev >/dev/null 2>&1; then
  apt-get update -y >/dev/null && apt-get install -y libfreeimage-dev imagemagick >/dev/null
fi

# ---------------------------------------------------------------------------
# 2. Convert Lena.png to PGM (the helper IO only supports PGM)
# ---------------------------------------------------------------------------
log "Preparing Lena.pgm input (8-bit grayscale)"
convert data/Lena.png -colorspace Gray -depth 8 data/Lena.pgm
cp data/Lena.pgm artifacts/before_lena_grayscale.pgm
convert data/Lena.pgm artifacts/before_lena_grayscale.png

# ---------------------------------------------------------------------------
# 3. Build
# ---------------------------------------------------------------------------
log "Building"
make clean 2>&1 | tee -a logs/build.log
make all -lfreeimage 2>&1 | tee -a logs/build.log || {
  # Makefile doesn't include -lfreeimage; retry by appending to LDFLAGS via override
  log "Retrying build with -lfreeimage appended"
  make clean >/dev/null
  make all LDFLAGS="-L/usr/local/cuda/lib64 -lcudart -lnppc -lnppial -lnppicc -lnppidei -lnppif -lnppig -lnppim -lnppist -lnppisu -lnppitc -lfreeimage" 2>&1 | tee -a logs/build.log
}

# ---------------------------------------------------------------------------
# 4. Run
# ---------------------------------------------------------------------------
log "Running imageRotationNPP on data/Lena.pgm"
./bin/imageRotationNPP --input data/Lena.pgm --output data/Lena_rotated.pgm 2>&1 | tee logs/run.log

# ---------------------------------------------------------------------------
# 5. Stage artifacts with clear before/after names
# ---------------------------------------------------------------------------
log "Staging artifacts"
cp data/Lena_rotated.pgm artifacts/after_lena_rotated_45deg.pgm
convert data/Lena_rotated.pgm artifacts/after_lena_rotated_45deg.png

ls -la artifacts logs | tee -a logs/system.log

log "Done. Inspect artifacts/ and logs/."
