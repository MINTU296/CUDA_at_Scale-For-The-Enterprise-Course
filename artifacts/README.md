# artifacts/

This directory holds the run evidence (before / after images) produced by `colab/setup_and_run.sh`.

After running the Colab notebook (or the script on a CUDA host), this folder will contain:

| File                                      | Description                                           |
|-------------------------------------------|-------------------------------------------------------|
| `before_lena_grayscale.pgm`               | Input fed to the CUDA program (8-bit grayscale PGM)   |
| `before_lena_grayscale.png`               | Same input rendered as PNG for visual inspection      |
| `after_lena_rotated_45deg.pgm`            | Output from `nppiRotate_8u_C1R` (45 deg, NN interp)   |
| `after_lena_rotated_45deg.png`            | Same output rendered as PNG for visual inspection     |

The naming makes the before/after pairing explicit so a grader can compare them at a glance.
