# CUDA Image Rotation with NPP

A **GPU-accelerated** image rotation utility built on top of the **NVIDIA Performance Primitives (NPP)** library. It loads a grayscale image, rotates it by **45°** on the GPU using `nppiRotate_8u_C1R`, and writes the rotated result back to disk. Use it as a starting template for any NPP-based image processing pipeline.

---

## Repository Layout

```text
.
├── bin/                       # Compiled `imageRotationNPP` binary (after `make`)
├── data/
│   └── Lena.png               # Sample input image
├── lib/                       # Bundled NPP/CUDA helper headers
├── src/
│   └── imageRotationNPP.cpp   # Host code: argument parsing + NPP rotation
├── Makefile                   # Build & run rules (nvcc + NPP)
├── run.sh                     # Convenience wrapper for `make run`
├── INSTALL                    # Install notes
├── LICENSE                    # NVIDIA-derived license
└── README.md                  # You are here
```

## Prerequisites

- NVIDIA GPU with CUDA support
- CUDA Toolkit installed at `/usr/local/cuda` (the Makefile points `nvcc` to `/usr/local/cuda/bin/nvcc`)
- The CUDA NPP libraries (`nppc`, `nppial`, `nppicc`, `nppidei`, `nppif`, `nppig`, `nppim`, `nppist`, `nppisu`, `nppitc`) — these ship with the CUDA Toolkit
- A C++11-capable host compiler
- Linux (or WSL2 on Windows). macOS is not supported because the Makefile links against `lib64` and the Linux NPP runtime.

## Build

```bash
make clean && make all
```

This invokes:

```bash
nvcc -std=c++11 -I/usr/local/cuda/include -Iinclude \
     src/imageRotationNPP.cpp \
     -o bin/imageRotationNPP \
     -L/usr/local/cuda/lib64 \
     -lcudart -lnppc -lnppial -lnppicc -lnppidei \
     -lnppif -lnppig -lnppim -lnppist -lnppisu -lnppitc
```

## Run

The simplest way:

```bash
make run
```

Which is equivalent to:

```bash
./bin/imageRotationNPP --input data/Lena.png --output data/Lena_rotated.png
```

You can pass any 8-bit single-channel image you like:

```bash
./bin/imageRotationNPP --input path/to/your_image.pgm --output path/to/your_image_rotated.pgm
```

If `--output` is omitted, the program derives the output path by replacing the input extension with `_rotate.pgm`.

Sample console output:

```text
./bin/imageRotationNPP Starting...

GPU Device 0: "Tesla T4"
NPP Library Version 11.x.x
  CUDA Driver Version: 12.x
  CUDA Runtime Version: 12.x
Saved image: data/Lena_rotated.png
```

## Before & After Rotation

| Sample    | Original                                                                                                                                             | Rotated                                                                                                                                               |
|-----------|------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------|
| **dice**  | <img src="https://raw.githubusercontent.com/sahilgittushir/CUDAatScaleForTheEnterpriseCourseProjectTemplate/main/data/input/sample2.png" width="200"/> | <img src="https://raw.githubusercontent.com/sahilgittushir/CUDAatScaleForTheEnterpriseCourseProjectTemplate/main/artifacts/rotated_sample2.png" width="200"/> |
| **smiley**| <img src="https://raw.githubusercontent.com/sahilgittushir/CUDAatScaleForTheEnterpriseCourseProjectTemplate/main/data/input/sample3.png" width="200"/> | <img src="https://raw.githubusercontent.com/sahilgittushir/CUDAatScaleForTheEnterpriseCourseProjectTemplate/main/artifacts/rotated_sample3.png" width="200"/> |
| **logo**  | <img src="https://raw.githubusercontent.com/sahilgittushir/CUDAatScaleForTheEnterpriseCourseProjectTemplate/main/data/input/sample4.png" width="200"/> | <img src="https://raw.githubusercontent.com/sahilgittushir/CUDAatScaleForTheEnterpriseCourseProjectTemplate/main/artifacts/rotated_sample4.png" width="200"/> |
| **svg**   | <img src="https://raw.githubusercontent.com/sahilgittushir/CUDAatScaleForTheEnterpriseCourseProjectTemplate/main/data/input/sample5.png" width="200"/> | <img src="https://raw.githubusercontent.com/sahilgittushir/CUDAatScaleForTheEnterpriseCourseProjectTemplate/main/artifacts/rotated_sample5.png" width="200"/> |

## How It Works

1. **CUDA discovery** — `findCudaDevice` selects a GPU and `printNppInfo` prints the NPP / driver / runtime versions.
2. **Host load** — `npp::loadImage` reads the input as an `ImageCPU_8u_C1` (8-bit grayscale).
3. **Upload to device** — the host image is wrapped in an `ImageNPP_8u_C1`, copying the pixel buffer to GPU memory.
4. **Bounding box** — `nppiGetRotateBound` computes the size of the canvas needed to contain the rotated image.
5. **Rotate on GPU** — `nppiRotate_8u_C1R` performs the rotation around the source center using nearest-neighbour interpolation (`NPPI_INTER_NN`).
6. **Download & save** — the result is copied back to host memory and written via `npp::saveImage`.

The rotation angle is hard-coded to `45.0` degrees in `src/imageRotationNPP.cpp` (`rotateImage(inputPath, outputPath, 45.0)`). Change that value to rotate by a different angle.

## Make Targets

| Target          | Description                                  |
|-----------------|----------------------------------------------|
| `make` / `make all` | Build `bin/imageRotationNPP`              |
| `make run`      | Build (if needed) and run on `data/Lena.png` |
| `make clean`    | Remove the contents of `bin/`                |
| `make install`  | No-op (kept for completeness)                |
| `make help`     | Print the list of targets                    |

## License & Credits

Licensed under the NVIDIA-derived BSD-style terms in [LICENSE](LICENSE). Original boilerplate and helper headers (`Exceptions.h`, `ImageIO.h`, `ImagesCPU.h`, `ImagesNPP.h`, `helper_cuda.h`, `helper_string.h`) are from the NVIDIA CUDA Samples and the Coursera *CUDA at Scale for the Enterprise* course template.

> Tip: To rotate by a different angle, edit the `45.0` literal in `main()` of `src/imageRotationNPP.cpp` and rebuild.
