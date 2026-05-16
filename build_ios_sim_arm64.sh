#!/bin/bash
# FlatBuffers iOS Simulator (Apple Silicon - arm64) 构建脚本
# 需要: macOS with Xcode and iOS Simulator SDK

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build_ios_sim_arm64"
INSTALL_DIR="${SCRIPT_DIR}/../Cpp/flatbuffers_ios_sim_arm64"

echo "=== Building FlatBuffers for iOS Simulator (Apple Silicon arm64) ==="
echo "Build directory: ${BUILD_DIR}"
echo "Install directory: ${INSTALL_DIR}"

# 检查 Xcode
if [ ! -d "/Applications/Xcode.app" ]; then
    echo "Error: Xcode not found. Please install Xcode."
    exit 1
fi

# 获取 iOS Simulator SDK 路径
IOS_SIM_SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
echo "iOS Simulator SDK: ${IOS_SIM_SDK}"

if [ ! -d "${IOS_SIM_SDK}" ]; then
    echo "Error: iOS Simulator SDK not found."
    exit 1
fi

# 创建构建目录
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# 运行 CMake 配置 (Apple Silicon Simulator)
cmake -DCMAKE_OSX_ARCHITECTURES=arm64 \
      -DCMAKE_OSX_SYSROOT="${IOS_SIM_SDK}" \
      -DCMAKE_SYSTEM_NAME=iOS \
      -DCMAKE_SYSTEM_VERSION=13.0 \
      -DCMAKE_C_FLAGS="-target arm64-apple-ios13.0-simulator" \
      -DCMAKE_CXX_FLAGS="-target arm64-apple-ios13.0-simulator -std=c++17" \
      -DCMAKE_BUILD_TYPE=Release \
      -DFLATBUFFERS_BUILD_TESTS=OFF \
      -DFLATBUFFERS_BUILD_FLATLIB=ON \
      -DFLATBUFFERS_BUILD_FLATC=OFF \
      -DFLATBUFFERS_BUILD_SHAREDLIB=OFF \
      -DFLATBUFFERS_INSTALL=ON \
      -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
      ..

# 编译
echo "=== Compiling ==="
make -j$(sysctl -n hw.ncpu)

# 安装
echo "=== Installing ==="
make install

echo "=== Build Complete ==="
echo "Headers: ${INSTALL_DIR}/include"
echo "Library: ${INSTALL_DIR}/lib/libflatbuffers.a"
if [ -f "${INSTALL_DIR}/lib/libflatbuffers.a" ]; then
    echo "Architecture: $(lipo -info ${INSTALL_DIR}/lib/libflatbuffers.a 2>&1 || file ${INSTALL_DIR}/lib/libflatbuffers.a)"
fi
