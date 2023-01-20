if(__OPEN_BLAS_INCLUDED)
  return()
endif()
set(__OPEN_BLAS_INCLUDED TRUE)

if(NOT INTERN_BUILD_MOBILE OR NOT INTERN_USE_OPEN_BLAS)
  return()
endif()

##############################################################################
# OpenBLAS is built together with Libtorch mobile.
# By default, it builds code from third-party/OpenBLAS submodule.
##############################################################################

set(CAFFE2_THIRD_PARTY_ROOT ${PROJECT_SOURCE_DIR}/third_party)
set(OPEN_BLAS_SRC_DIR "${CAFFE2_THIRD_PARTY_ROOT}/OpenBLAS" CACHE STRING "OpenBLAS source directory")

set(OPEN_BLAS_INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install)
set(OPEN_BLAS_INCLUDE_DIR ${OPEN_BLAS_INSTALL_DIR}/include)

# TOFIX: Use variables instead of hardcoded values

# Set path to ndk-bundle
set(NDK_BUNDLE_DIR ${ANDROID_NDK})
set(ANDROID_PLATFORM "android-24")

# Export PATH to contain directories of clang and aarch64-linux-android-* utilities
set(PATH "${NDK_BUNDLE_DIR}/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin/:${NDK_BUNDLE_DIR}/toolchains/llvm/prebuilt/linux-x86_64/bin:${PATH}")

# Setup LDFLAGS so that loader can find libgcc and pass -lm for sqrt
set(LDFLAGS "-L${NDK_BUNDLE_DIR}/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/lib/gcc/aarch64-linux-android/4.9.x -lm")

# Setup the clang cross compile options
set(CLANG_FLAGS "-target aarch64-linux-android --sysroot ${NDK_BUNDLE_DIR}/platforms/${ANDROID_PLATFORM}/arch-arm64 -gcc-toolchain ${NDK_BUNDLE_DIR}/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/ -I${NDK_BUNDLE_DIR}/sysroot/usr/include -I${NDK_BUNDLE_DIR}/sysroot/usr/include/aarch64-linux-android")

include(ExternalProject)
ExternalProject_Add(openblas_external
    PREFIX "${CMAKE_CURRENT_BINARY_DIR}/third_party/OpenBLAS"
    SOURCE_DIR ${OPEN_BLAS_SRC_DIR}
    BUILD_IN_SOURCE 1
    BUILD_COMMAND
        make
        "TARGET=ARMV8"
        "NOFORTRAN=1"
        "C_LAPACK=1"
        "USE_OPENMP=1"
        "BUILD_TESTING=0"
        "CC=clang ${CLANG_FLAGS}"
        "HOSTCC=gcc"
    INSTALL_COMMAND
        make 
        "PREFIX=${OPEN_BLAS_INSTALL_DIR}"
        "install"
)

add_library(openblas STATIC IMPORTED)

# We build static versions of eigen blas but link into a shared library, so they need PIC.
set_property(TARGET openblas PROPERTY IMPORTED_LOCATION ${OPEN_BLAS_INSTALL_DIR}/lib/libopenblas.a)
set_property(TARGET openblas PROPERTY POSITION_INDEPENDENT_CODE ON)

add_dependencies(openblas openblas_external)
