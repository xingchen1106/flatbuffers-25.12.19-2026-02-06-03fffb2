#!/bin/bash
# FlatBuffers Windows x86 (Win32) 交叉编译脚本
# 需要在 macOS 上安装: brew install mingw-w64

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build_win32"
INSTALL_DIR="${SCRIPT_DIR}/../Cpp/flatbuffers_win32"

echo "=== Building FlatBuffers for Windows x86 (Win32) ==="
echo "Build directory: ${BUILD_DIR}"
echo "Install directory: ${INSTALL_DIR}"

# 检查交叉编译工具 (32-bit)
if ! command -v i686-w64-mingw32-g++ &> /dev/null; then
    echo "Error: MinGW-w64 (32-bit) not found. Please install it first:"
    echo "  brew install mingw-w64"
    exit 1
fi

# 创建构建目录
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# 运行 CMake 配置 (32-bit)
cmake -DCMAKE_TOOLCHAIN_FILE="${SCRIPT_DIR}/../Cpp/cmake/MinGW-w32-toolchain.cmake" \
      -DCMAKE_BUILD_TYPE=Release \
      -DFLATBUFFERS_BUILD_TESTS=OFF \
      -DFLATBUFFERS_BUILD_FLATLIB=ON \
      -DFLATBUFFERS_BUILD_FLATC=ON \
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
echo "FlatC: ${INSTALL_DIR}/bin/flatc.exe"
