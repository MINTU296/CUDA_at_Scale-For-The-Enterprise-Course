#!/usr/bin/env bash
# Build the final submission archive.
#
# Run this ONLY after artifacts/ and logs/ have been populated by a real
# CUDA run (see colab/run_on_colab.ipynb). The script will refuse to
# package an empty submission.
#
# Produces (in the repo's parent directory):
#   imageRotationNPP_submission_<UTC-timestamp>.tar.gz
#   imageRotationNPP_submission_<UTC-timestamp>.zip

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

required=(
  "logs/build.log"
  "logs/run.log"
  "logs/system.log"
  "artifacts/before_lena_grayscale.png"
  "artifacts/after_lena_rotated_45deg.png"
)

missing=0
for f in "${required[@]}"; do
  if [[ ! -s "$f" ]]; then
    echo "MISSING (or empty): $f" >&2
    missing=1
  fi
done

if [[ $missing -eq 1 ]]; then
  cat >&2 <<EOF

Refusing to package: at least one required evidence file is missing or empty.
Run colab/run_on_colab.ipynb on a Colab GPU runtime first, download the
resulting evidence.zip, and unpack it at the repo root so that logs/ and
artifacts/ are populated.
EOF
  exit 1
fi

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
base="imageRotationNPP_submission_${stamp}"
parent="$(cd .. && pwd)"
staging="$(mktemp -d)"
target="$staging/$base"
mkdir -p "$target"

# Copy everything except VCS / build / OS junk.
rsync -a \
  --exclude '.git' \
  --exclude '.gitignore' \
  --exclude '.claude' \
  --exclude '.DS_Store' \
  --exclude 'bin/imageRotationNPP' \
  --exclude 'artifacts.zip' \
  --exclude '*.o' \
  ./ "$target/"

# Belt-and-braces .DS_Store removal (rsync exclude only catches root-level).
find "$target" -name '.DS_Store' -delete

cd "$staging"
tar -czf "$parent/${base}.tar.gz" "$base"
zip -qr "$parent/${base}.zip"   "$base"
cd "$REPO_ROOT"
rm -rf "$staging"

echo
echo "Wrote:"
ls -lh "$parent/${base}.tar.gz" "$parent/${base}.zip"
echo
echo "Contents summary:"
tar -tzf "$parent/${base}.tar.gz" | head -40
echo "..."
echo "(total $(tar -tzf "$parent/${base}.tar.gz" | wc -l | tr -d ' ') entries)"
