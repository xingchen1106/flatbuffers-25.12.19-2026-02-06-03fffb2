#!/bin/bash
# FlatBuffers iOS arm64 交叉编译脚本
# 需要: macOS with Xcode and iOS SDK

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build_ios"
INSTALL_DIR="${SCRIPT_DIR}/../Cpp/flatbuffers_ios"

echo "=== Building FlatBuffers for iOS arm64 ==="
echo "Build directory: ${BUILD_DIR}"
echo "Install directory: ${INSTALL_DIR}"

# 检查 Xcode
if [ ! -d "/Applications/Xcode.app" ]; then
    echo "Error: Xcode not found. Please install Xcode."
    exit 1
fi

# 获取 iOS SDK 路径
IOS_SDK=$(xcrun --show-sdk-path --sdk iphoneos)
echo "iOS SDK: ${IOS_SDK}"

if [ ! -d "${IOS_SDK}" ]; then
    echo "Error: iOS SDK not found."
    exit 1
fi

# 创建构建目录
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# 运行 CMake 配置
cmake -DCMAKE_TOOLCHAIN_FILE="${SCRIPT_DIR}/../Cpp/cmake/ios-toolchain.cmake" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_OSX_ARCHITECTURES=arm64 \
      -DCMAKE_OSX_SYSROOT="${IOS_SDK}" \
      -DCMAKE_IOS_INSTALL_COMBINED=OFF \
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
echo "Architecture: $(lipo -info ${INSTALL_DIR}/lib/libflatbuffers.a)"
