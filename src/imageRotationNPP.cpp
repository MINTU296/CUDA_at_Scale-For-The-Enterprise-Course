/* Copyright (c) 2019, NVIDIA CORPORATION. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of NVIDIA CORPORATION nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#if defined(WIN32) || defined(_WIN32) || defined(WIN64) || defined(_WIN64)
#define WINDOWS_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#pragma warning(disable : 4819)
#endif

#include <Exceptions.h>
#include <ImageIO.h>
#include <ImagesCPU.h>
#include <ImagesNPP.h>

#include <cuda_runtime.h>
#include <npp.h>

#include <helper_cuda.h>
#include <helper_string.h>

#include <fstream>
#include <iostream>
#include <string>

namespace
{

bool printNppInfo()
{
    const NppLibraryVersion* libraryVersion = nppGetLibVersion();
    std::cout << "NPP Library Version " << libraryVersion->major << "." << libraryVersion->minor
              << "." << libraryVersion->build << "\n";

    int driverVersion = 0;
    int runtimeVersion = 0;
    cudaDriverGetVersion(&driverVersion);
    cudaRuntimeGetVersion(&runtimeVersion);

    std::cout << "  CUDA Driver Version: " << (driverVersion / 1000) << "." << ((driverVersion % 100) / 10)
              << "\n";
    std::cout << "  CUDA Runtime Version: " << (runtimeVersion / 1000) << "." << ((runtimeVersion % 100) / 10)
              << "\n";

    return checkCudaCapabilities(1, 0);
}

std::string getCommandLineArgument(int argc, char* argv[], const char* option)
{
    char* value = nullptr;
    if (checkCmdLineFlag(argc, (const char**)argv, option))
    {
        getCmdLineArgumentString(argc, (const char**)argv, option, &value);
    }
    return value ? std::string(value) : std::string();
}

std::string resolveInputPath(int argc, char* argv[])
{
    const std::string inputPath = getCommandLineArgument(argc, argv, "input");
    if (!inputPath.empty())
    {
        return inputPath;
    }

    const char* defaultPath = sdkFindFilePath("Lena.pgm", argv[0]);
    if (defaultPath)
    {
        return defaultPath;
    }

    return "Lena.pgm";
}

std::string resolveOutputPath(int argc, char* argv[], const std::string& inputPath)
{
    const std::string outputPath = getCommandLineArgument(argc, argv, "output");
    if (!outputPath.empty())
    {
        return outputPath;
    }

    std::string resultPath = inputPath;
    const auto extensionPosition = resultPath.rfind('.');
    if (extensionPosition != std::string::npos)
    {
        resultPath.replace(extensionPosition, std::string::npos, "_rotate.pgm");
    }
    else
    {
        resultPath += "_rotate.pgm";
    }

    return resultPath;
}

bool fileExists(const std::string& path)
{
    std::ifstream input(path);
    return input.good();
}

int rotateImage(const std::string& inputPath, const std::string& outputPath, double angleDegrees)
{
    npp::ImageCPU_8u_C1 hostSrc;
    npp::loadImage(inputPath, hostSrc);

    npp::ImageNPP_8u_C1 deviceSrc(hostSrc);

    const NppiSize srcSize = {static_cast<int>(deviceSrc.width()), static_cast<int>(deviceSrc.height())};
    const NppiPoint srcOffset = {0, 0};
    const NppiSize roiSize = srcSize;

    NppiRect boundingBox;
    NPP_CHECK_NPP(nppiGetRotateBound(roiSize, angleDegrees, &boundingBox));

    npp::ImageNPP_8u_C1 deviceDst(boundingBox.width, boundingBox.height);

    const NppiPoint rotationCenter = {srcSize.width / 2, srcSize.height / 2};

    NPP_CHECK_NPP(nppiRotate_8u_C1R(
        deviceSrc.data(), srcSize, deviceSrc.pitch(), srcOffset,
        deviceDst.data(), deviceDst.pitch(), boundingBox, angleDegrees,
        rotationCenter, NPPI_INTER_NN));

    npp::ImageCPU_8u_C1 hostDst(deviceDst.size());
    deviceDst.copyTo(hostDst.data(), hostDst.pitch());

    saveImage(outputPath, hostDst);
    return EXIT_SUCCESS;
}

} // namespace

int main(int argc, char* argv[])
{
    std::cout << (argc > 0 ? argv[0] : "imageRotationNPP") << " Starting...\n\n";

    try
    {
        findCudaDevice(argc, (const char**)argv);
        if (!printNppInfo())
        {
            std::cerr << "CUDA capability check failed.\n";
            return EXIT_FAILURE;
        }

        const std::string inputPath = resolveInputPath(argc, argv);
        if (inputPath.empty())
        {
            std::cerr << "Unable to resolve input file path.\n";
            return EXIT_FAILURE;
        }

        if (!fileExists(inputPath))
        {
            std::cerr << "Input file not found: " << inputPath << "\n";
            return EXIT_FAILURE;
        }

        const std::string outputPath = resolveOutputPath(argc, argv, inputPath);
        const int result = rotateImage(inputPath, outputPath, 45.0);

        if (result == EXIT_SUCCESS)
        {
            std::cout << "Saved image: " << outputPath << "\n";
        }

        return result;
    }
    catch (const npp::Exception& e)
    {
        std::cerr << "Program error! The following exception occurred:\n" << e << "\nAborting.\n";
        return EXIT_FAILURE;
    }
    catch (const std::exception& e)
    {
        std::cerr << "Program error! " << e.what() << "\nAborting.\n";
        return EXIT_FAILURE;
    }
    catch (...)
    {
        std::cerr << "Program error! An unknown exception occurred.\nAborting.\n";
        return EXIT_FAILURE;
    }
}
