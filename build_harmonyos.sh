#!/bin/bash
# FlatBuffers HarmonyOS 静态库交叉编译脚本
# 支持架构: arm64-v8a, armeabi-v7a, x86_64
# 输出: .a 静态库

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_ROOT_DIR="${SCRIPT_DIR}/build_harmonyos"
OUTPUT_DIR="${SCRIPT_DIR}/Cpp/flatbuffers_harmonyos"

# HarmonyOS 配置
HARMONYOS_API_LEVEL=9  # 对应 HarmonyOS 3.0+
HARMONYOS_ABIS=("arm64-v8a" "armeabi-v7a" "x86_64")

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== FlatBuffers HarmonyOS 静态库构建脚本 ==="
echo "构建目录: ${BUILD_ROOT_DIR}"
echo "输出目录: ${OUTPUT_DIR}"
echo "HarmonyOS API Level: ${HARMONYOS_API_LEVEL}"
echo "目标架构: ${HARMONYOS_ABIS[*]}"
echo ""

# 检查 OHOS_NDK 环境变量，如果未设置则尝试自动检测
if [ -z "${OHOS_NDK}" ]; then
    echo -e "${YELLOW}警告: 未设置 OHOS_NDK 环境变量，尝试自动检测...${NC}"
    
    # 常见的 HarmonyOS NDK 安装路径
    POSSIBLE_PATHS=(
        "$HOME/Library/Huawei/Sdk/hmscore/3.1.0/toolchains"
        "$HOME/Library/Huawei/Sdk/hmscore/4.0.0/toolchains"
        "$HOME/Library/Huawei/Sdk/hmscore/4.1.0/toolchains"
        "$HOME/Library/Huawei/Sdk/toolchains"
        "/Applications/DevEco-Studio.app/Contents/sdk/toolchains"
    )
    
    for path in "${POSSIBLE_PATHS[@]}"; do
        if [ -d "$path" ] && [ -f "$path/build/cmake/ohos.toolchain.cmake" ]; then
            export OHOS_NDK="$path"
            echo -e "${GREEN}自动检测到 HarmonyOS NDK: ${OHOS_NDK}${NC}"
            break
        fi
    done
    
    if [ -z "${OHOS_NDK}" ]; then
        echo -e "${RED}错误: 未找到 HarmonyOS NDK${NC}"
        echo ""
        echo "请安装 HarmonyOS NDK 或设置 OHOS_NDK 环境变量："
        echo "  export OHOS_NDK=/path/to/ohos-sdk/version/toolchains"
        echo ""
        echo "常见安装方式："
        echo "  1. 安装 DevEco Studio"
        echo "  2. 在 DevEco Studio 中安装 HarmonyOS SDK"
        echo "  3. SDK 通常位于: ~/Library/Huawei/Sdk/hmscore/version/toolchains"
        exit 1
    fi
fi

# 检查 NDK 路径是否存在
if [ ! -d "${OHOS_NDK}" ]; then
    echo -e "${RED}错误: HarmonyOS NDK 路径不存在: ${OHOS_NDK}${NC}"
    exit 1
fi

# 检查 NDK 中的 CMake toolchain 文件
TOOLCHAIN_FILE="${OHOS_NDK}/build/cmake/ohos.toolchain.cmake"
if [ ! -f "${TOOLCHAIN_FILE}" ]; then
    echo -e "${YELLOW}警告: 找不到标准 toolchain 文件，尝试查找...${NC}"
    # 尝试其他可能的位置
    TOOLCHAIN_FILE=$(find "${OHOS_NDK}" -name "ohos.toolchain.cmake" 2>/dev/null | head -1)
    if [ -z "${TOOLCHAIN_FILE}" ]; then
        echo -e "${RED}错误: 找不到 CMake toolchain 文件: ohos.toolchain.cmake${NC}"
        echo "请确保 OHOS_NDK 指向正确的 HarmonyOS NDK 目录"
        exit 1
    fi
    echo -e "${GREEN}找到 toolchain 文件: ${TOOLCHAIN_FILE}${NC}"
fi

echo -e "${GREEN}使用 HarmonyOS NDK: ${OHOS_NDK}${NC}"
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
        -DOHOS_ARCH="${ABI}" \
        -DOHOS_PLATFORM="ohos" \
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
for ABI in "${HARMONYOS_ABIS[@]}"; do
    build_arch "${ABI}"
done

# 汇总信息
echo -e "${GREEN}=== 所有架构构建完成 ===${NC}"
echo ""
echo "输出目录结构:"
find "${OUTPUT_DIR}" -name "*.a" -o -name "*.h" | head -20
echo ""
echo "静态库文件:"
for ABI in "${HARMONYOS_ABIS[@]}"; do
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
for ABI in "${HARMONYOS_ABIS[@]}"; do
    echo "  ${OUTPUT_DIR}/${ABI}/lib/"
done
