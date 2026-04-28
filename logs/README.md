# logs/

This directory holds the build / run / system logs produced by `colab/setup_and_run.sh`.

| File           | Description                                                              |
|----------------|--------------------------------------------------------------------------|
| `build.log`    | Output of `make clean && make all` (nvcc compile + link)                 |
| `run.log`      | Stdout/stderr of `./bin/imageRotationNPP --input ... --output ...`       |
| `system.log`   | `uname -a`, `nvidia-smi`, `nvcc --version`, NPP libs present on the host |

Together these show: the toolchain version, the GPU the program ran on, the build succeeding, and the rotation reporting `Saved image: data/Lena_rotated.pgm`.
