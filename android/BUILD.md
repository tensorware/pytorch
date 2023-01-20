# Requirements
Build a pytorch android aar file with LAPACK support to fix:
```
Terminating with uncaught exception of type c10::Error: Calling torch.linalg.lu_factor on a CPU tensor requires compiling PyTorch with LAPACK. Please use PyTorch built with LAPACK support.
```

## Environment
- Build system: linux x86_64.
- Target system: arm64-v8a.

## Versions
- Python Version 3.9.12.
- CMake Version 3.18.4 (pytorch), 3.10.2.4988404 (fbjni).
- Vulkan SDK Version 1.3.204.1.
- Android NDK Version 21.1.6352462
  - System Settings > Android SDK > NDK (Side by side): Check **only one** version.

## Setup
See [prerequisites](https://github.com/pytorch/pytorch#prerequisites).

```bash
# Deactivate conda because of issues with $CFLAGS presets 
conda deactivate

# Python path used in build script
export PYTHON="/opt/conda/miniconda3/bin/python3"
```

```bash
# Base directory of android sdk
export ANDROID_HOME="/home/user/.android/sdk"
export ANDROID_SDK_PATH="${ANDROID_HOME}"
```

## Third Party
EigenBLAS with LAPACK doesn't work.
```bash
# Checkout third_party submodules
git submodule update --init --recursive
```

### OpenBLAS
See [OpenBLAS for Android](https://github.com/xianyi/OpenBLAS/wiki/How-to-build-OpenBLAS-for-Android).

```bash
# Add OpenBLAS to third_party folder
git submodule add https://github.com/xianyi/OpenBLAS.git third_party/OpenBLAS

# Use OpenBlas as root folder
cd ./third_party/OpenBLAS

# Checkout specific OpenBLAS version
git checkout 06d1dd6ba88d58ca588f8bed36dfc1a4cd78eabf
```

See `pytorch/cmake/External/OpenBLAS.cmake`.

```bash
# Base directory of android ndk bundle
export NDK_BUNDLE_VERSION="21.4.7075529"
export NDK_BUNDLE_DIR="${ANDROID_SDK_PATH}/ndk/${NDK_BUNDLE_VERSION}"

# Export PATH to contain directories of clang and aarch64-linux-android-* utilities
export PATH="${NDK_BUNDLE_DIR}/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin/:${NDK_BUNDLE_DIR}/toolchains/llvm/prebuilt/linux-x86_64/bin:${PATH}"

# Setup LDFLAGS so that loader can find libgcc and pass -lm for sqrt
export LDFLAGS="-L${NDK_BUNDLE_DIR}/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/lib/gcc/aarch64-linux-android/4.9.x -lm"

# Setup the clang cross compile options
export CLANG_FLAGS="-target aarch64-linux-android --sysroot ${NDK_BUNDLE_DIR}/platforms/android-24/arch-arm64 -gcc-toolchain ${NDK_BUNDLE_DIR}/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/ -I${NDK_BUNDLE_DIR}/sysroot/usr/include -I${NDK_BUNDLE_DIR}/sysroot/usr/include/aarch64-linux-android"

# Build OpenBlas with CLAPACK and OPENMP
make clean
make TARGET=ARMV8 NOFORTRAN=1 C_LAPACK=1 USE_OPENMP=1 BUILD_TESTING=0 CC="clang ${CLANG_FLAGS}" HOSTCC=gcc
make PREFIX=./install install
```

## PyTorch
See `pytorch/android/pytorch_android/build/outputs/aar/`.

```bash
# Base directory of android ndk bundle
export ANDROID_NDK_VERSION="21.4.7075529"
export ANDROID_NDK="${ANDROID_SDK_PATH}/ndk/${ANDROID_NDK_VERSION}"

# Android platform
export ANDROID_ABI="arm64-v8a"

# OpenBLAS settings
export BUILD_LITE_INTERPRETER=1
export BLAS="OpenBLAS"

# Vulkan settings
export USE_VULKAN=1
export VULKAN_SDK="/opt/vulkan-sdk"
export VULKAN_SDK_ENV="${VULKAN_SDK}/1.3.204.1/setup-env.sh"

# Build pytorch android aar
make clean
PYTHON=$PYTHON ANDROID_HOME=$ANDROID_HOME ANDROID_NDK=$ANDROID_NDK BUILD_LITE_INTERPRETER=$BUILD_LITE_INTERPRETER BLAS=$BLAS USE_VULKAN=$USE_VULKAN bash ./scripts/build_pytorch_android.sh $ANDROID_ABI
```
