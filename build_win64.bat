@echo off
REM FlatBuffers Windows x64 构建脚本
REM 需要在 Windows 上安装: CMake, Visual Studio 2019 or later (with C++ development tools)

setlocal EnableDelayedExpansion

set SCRIPT_DIR=%~dp0
set BUILD_DIR=%SCRIPT_DIR%build_win64
set INSTALL_DIR=%SCRIPT_DIR%..\Cpp\flatbuffers_win64

echo === Building FlatBuffers for Windows x64 ===
echo Build directory: %BUILD_DIR%
echo Install directory: %INSTALL_DIR%

REM 创建构建目录
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
cd /d "%BUILD_DIR%"

REM 运行 CMake 配置 (使用 Visual Studio 生成器)
cmake -G "Visual Studio 16 2019" -A x64 ^
      -DFLATBUFFERS_BUILD_TESTS=OFF ^
      -DFLATBUFFERS_BUILD_FLATLIB=ON ^
      -DFLATBUFFERS_BUILD_FLATC=ON ^
      -DFLATBUFFERS_INSTALL=ON ^
      -DCMAKE_INSTALL_PREFIX="%INSTALL_DIR%" ^
      ..

REM 编译 Release 版本
echo === Compiling (Release x64) ===
cmake --build . --config Release --parallel

REM 安装
echo === Installing ===
cmake --install . --config Release

echo === Build Complete ===
echo Headers: %INSTALL_DIR%\include
echo Library: %INSTALL_DIR%\lib\flatbuffers.lib
echo FlatC: %INSTALL_DIR%\bin\flatc.exe

pause
