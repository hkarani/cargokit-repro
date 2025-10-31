#!/bin/bash

# Configuration
export ANDROID_SDK_ROOT=/opt/android-sdk
export NDK_VERSION=25.1.8937393
export MIN_SDK_VERSION=21
export TARGET=aarch64-linux-android
export TARGET_TEMP_DIR=/app/build
export HOST_ARCH=linux-x86_64
export NDK_PATH=$ANDROID_SDK_ROOT/ndk/$NDK_VERSION
export TOOLCHAIN_PATH=$NDK_PATH/toolchains/llvm/prebuilt/$HOST_ARCH/bin

# Environment variables for Rust compilation
export AR_${TARGET}=$TOOLCHAIN_PATH/${TARGET}-ar
export CC_${TARGET}=$TOOLCHAIN_PATH/clang
export CFLAGS_${TARGET}=--target=${TARGET}${MIN_SDK_VERSION}
export CXX_${TARGET}=$TOOLCHAIN_PATH/clang++
export CXXFLAGS_${TARGET}=--target=${TARGET}${MIN_SDK_VERSION}
export RANLIB_${TARGET}=$TOOLCHAIN_PATH/llvm-ranlib
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER=$TOOLCHAIN_PATH/clang
export _CARGOKIT_NDK_LINK_TARGET=--target=${TARGET}${MIN_SDK_VERSION}
export _CARGOKIT_NDK_LINK_CLANG=$TOOLCHAIN_PATH/clang
export CARGOKIT_TOOL_TEMP_DIR=$TARGET_TEMP_DIR

# libgcc workaround
export WORKAROUND_DIR=$TARGET_TEMP_DIR/cargokit/libgcc_workaround/${NDK_VERSION%%.*}
mkdir -p $WORKAROUND_DIR
if [ ${NDK_VERSION%%.*} -ge 23 ]; then
    echo "INPUT(-lunwind)" > $WORKAROUND_DIR/libgcc.a
else
    echo "INPUT(-lgcc)" > $WORKAROUND_DIR/libunwind.a
fi

# CARGO_ENCODED_RUSTFLAGS fix: Append -L with \x1f separator if existing flags present
if [ -n "$CARGO_ENCODED_RUSTFLAGS" ]; then
    export CARGO_ENCODED_RUSTFLAGS="${CARGO_ENCODED_RUSTFLAGS}\x1f-L\x1f${WORKAROUND_DIR}"
else    
    export CARGO_ENCODED_RUSTFLAGS="-L\x1f${WORKAROUND_DIR}"
fi

# Verify environment
echo "Environment variables set:"
env | grep -E "AR_|CC_|CFLAGS_|CXX_|CXXFLAGS_|RANLIB_|CARGO_|_CARGOKIT"