#!/bin/bash

# APK构建脚本
# 使用方法：./build-apk.sh

set -e

echo "🚀 开始构建 Simple Live APK..."

# 检查Docker是否运行
if ! docker info >/dev/null 2>&1; then
    echo "❌ 错误：Docker 未运行，请启动 Docker"
    exit 1
fi

# 构建Docker镜像
echo "📦 构建Docker镜像..."
docker build -t simple-live-builder .

# 创建输出目录
OUTPUT_DIR="$(pwd)/build-output"
mkdir -p "$OUTPUT_DIR"

echo "🔨 开始构建APK..."
echo "输出目录：$OUTPUT_DIR"

# 运行容器并构建APK
docker run --rm \
    -v "$OUTPUT_DIR:/output" \
    simple-live-builder

echo ""
echo "✅ 构建完成！"
echo "📱 APK文件已保存到：$OUTPUT_DIR/apk/"
echo ""
echo "构建的文件："
ls -la "$OUTPUT_DIR/apk/" 2>/dev/null || echo "未找到APK文件"