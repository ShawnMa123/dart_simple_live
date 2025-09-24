@echo off
REM APK构建脚本 (Windows)
REM 使用方法：build-apk.bat

echo 🚀 开始构建 Simple Live APK...

REM 检查Docker是否运行
docker info >nul 2>&1
if errorlevel 1 (
    echo ❌ 错误：Docker 未运行，请启动 Docker
    pause
    exit /b 1
)

REM 构建Docker镜像
echo 📦 构建Docker镜像...
docker build -t simple-live-builder .

REM 创建输出目录
set OUTPUT_DIR=%CD%\build-output
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo 🔨 开始构建APK...
echo 输出目录：%OUTPUT_DIR%

REM 运行容器并构建APK
docker run --rm -v "%OUTPUT_DIR%:/output" simple-live-builder

echo.
echo ✅ 构建完成！
echo 📱 APK文件已保存到：%OUTPUT_DIR%\apk\
echo.
echo 构建的文件：
dir "%OUTPUT_DIR%\apk\" 2>nul || echo 未找到APK文件

pause