#!/bin/bash
# FlatBuffers Android 静态库交叉编译脚本
# 支持架构: arm64-v8a, armeabi-v7a, x86, x86_64
# 输出: .a 静态库

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_ROOT_DIR="${SCRIPT_DIR}/build_android"
OUTPUT_DIR="${SCRIPT_DIR}/Cpp/flatbuffers_android"

# Android 配置
ANDROID_API_LEVEL=26  # minSdkVersion
ANDROID_ABIS=("arm64-v8a" "armeabi-v7a" "x86" "x86_64")

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== FlatBuffers Android 静态库构建脚本 ==="
echo "构建目录: ${BUILD_ROOT_DIR}"
echo "输出目录: ${OUTPUT_DIR}"
echo "Android API Level: ${ANDROID_API_LEVEL}"
echo "目标架构: ${ANDROID_ABIS[*]}"
echo ""

# 检查 ANDROID_NDK 环境变量
if [ -z "${ANDROID_NDK}" ]; then
    echo -e "${RED}错误: 未设置 ANDROID_NDK 环境变量${NC}"
    echo "请设置 ANDROID_NDK 环境变量，例如："
    echo "  export ANDROID_NDK=/path/to/android-ndk"
    echo "或修改此脚本中的 ANDROID_NDK 变量"
    exit 1
fi

# 检查 NDK 路径是否存在
if [ ! -d "${ANDROID_NDK}" ]; then
    echo -e "${RED}错误: Android NDK 路径不存在: ${ANDROID_NDK}${NC}"
    exit 1
fi

# 检查 NDK 中的 CMake toolchain 文件
TOOLCHAIN_FILE="${ANDROID_NDK}/build/cmake/android.toolchain.cmake"
if [ ! -f "${TOOLCHAIN_FILE}" ]; then
    echo -e "${RED}错误: 找不到 CMake toolchain 文件: ${TOOLCHAIN_FILE}${NC}"
    exit 1
fi

echo -e "${GREEN}使用 Android NDK: ${ANDROID_NDK}${NC}"
echo -e "${GREEN}Toolchain 文件: ${TOOLCHAIN_FILE}${NC}"
echo ""

# 创建输出目录
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${BUILD_ROOT_DIR}"

# 构建函数
build_arch() {
    local ABI=$1
    echo -e "${YELLOW}=== 构建架构: ${ABI} ===${NC}"
    
    local BUILD_DIR="${BUILD_ROOT_DIR}/${ABI}"
    local INSTALL_DIR="${OUTPUT_DIR}/${ABI}"
    
    # 创建构建目录
    mkdir -p "${BUILD_DIR}"
    cd "${BUILD_DIR}"
    
    # 运行 CMake 配置
    echo "CMake 配置..."
    cmake "${SCRIPT_DIR}" \
        -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAIN_FILE}" \
        -DANDROID_ABI="${ABI}" \
        -DANDROID_PLATFORM="android-${ANDROID_API_LEVEL}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DFLATBUFFERS_BUILD_TESTS=OFF \
        -DFLATBUFFERS_BUILD_FLATLIB=ON \
        -DFLATBUFFERS_BUILD_FLATC=OFF \
        -DFLATBUFFERS_BUILD_SHAREDLIB=OFF \
        -DFLATBUFFERS_INSTALL=ON \
        -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"
    
    # 编译
    echo "编译..."
    cmake --build . --config Release -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    
    # 安装
    echo "安装..."
    cmake --install .
    
    echo -e "${GREEN}=== ${ABI} 构建完成 ===${NC}"
    echo "输出: ${INSTALL_DIR}/lib/libflatbuffers.a"
    echo ""
}

# 构建所有架构
for ABI in "${ANDROID_ABIS[@]}"; do
    build_arch "${ABI}"
done

# 汇总信息
echo -e "${GREEN}=== 所有架构构建完成 ===${NC}"
echo ""
echo "输出目录结构:"
find "${OUTPUT_DIR}" -name "*.a" -o -name "*.h" | head -20
echo ""
echo "静态库文件:"
for ABI in "${ANDROID_ABIS[@]}"; do
    LIB_FILE="${OUTPUT_DIR}/${ABI}/lib/libflatbuffers.a"
    if [ -f "${LIB_FILE}" ]; then
        echo -e "${GREEN}✓${NC} ${ABI}: ${LIB_FILE}"
    else
        echo -e "${RED}✗${NC} ${ABI}: 未找到"
    fi
done

echo ""
echo -e "${GREEN}=== 构建成功 ===${NC}"
echo "头文件目录: ${OUTPUT_DIR}/arm64-v8a/include"
echo "静态库目录:"
for ABI in "${ANDROID_ABIS[@]}"; do
    echo "  ${OUTPUT_DIR}/${ABI}/lib/"
done
