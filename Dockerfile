# 使用Ubuntu作为基础镜像
FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_VERSION=3.35.0
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH="$PATH:/opt/flutter/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools"

# 安装基础依赖
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk \
    wget \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    libmpv-dev \
    mpv \
    && rm -rf /var/lib/apt/lists/*

# 设置Java环境
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# 下载并安装Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /opt/flutter
RUN /opt/flutter/bin/flutter config --no-analytics
RUN /opt/flutter/bin/flutter precache --android

# 创建Android SDK目录
RUN mkdir -p $ANDROID_SDK_ROOT

# 下载Android命令行工具
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O /tmp/cmdline-tools.zip \
    && unzip -q /tmp/cmdline-tools.zip -d /tmp \
    && mkdir -p $ANDROID_SDK_ROOT/cmdline-tools \
    && mv /tmp/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest \
    && rm /tmp/cmdline-tools.zip

# 安装Android SDK组件
RUN yes | sdkmanager --licenses
RUN sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# 启用Flutter桌面支持
RUN /opt/flutter/bin/flutter config --enable-linux-desktop

# 安装flutter_distributor
RUN /opt/flutter/bin/dart pub global activate flutter_distributor

# 设置工作目录
WORKDIR /workspace

# 创建输出目录
RUN mkdir -p /output

# 复制项目文件
COPY . .

# 构建脚本
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "开始构建Flutter应用..."\n\
\n\
# 进入应用目录\n\
cd simple_live_app\n\
\n\
# 清理缓存\n\
echo "清理Flutter缓存..."\n\
flutter clean\n\
\n\
# 获取依赖\n\
echo "获取Flutter依赖..."\n\
flutter pub get\n\
\n\
# 检查Flutter配置\n\
echo "检查Flutter配置..."\n\
flutter --version\n\
\n\
# 构建Android APK - 包括通用版本和按ABI分离的版本\n\
echo "构建Android APK..."\n\
flutter build apk --release --split-per-abi --no-tree-shake-icons\n\
\n\
# 构建通用APK（如果需要）\n\
echo "构建通用APK..."\n\
flutter build apk --release --no-tree-shake-icons\n\
\n\
# 创建输出目录\n\
mkdir -p /output/apk\n\
\n\
# 复制APK文件\n\
echo "复制APK文件..."\n\
if [ -d "build/app/outputs/flutter-apk" ]; then\n\
    cp build/app/outputs/flutter-apk/*.apk /output/apk/\n\
    echo "APK文件已复制到 /output/apk/"\n\
    echo "构建的APK文件："\n\
    ls -la /output/apk/\n\
else\n\
    echo "错误：未找到APK构建目录"\n\
    exit 1\n\
fi\n\
\n\
# 显示文件大小信息\n\
echo ""\n\
echo "APK文件详情："\n\
for apk in /output/apk/*.apk; do\n\
    if [ -f "$apk" ]; then\n\
        size=$(du -h "$apk" | cut -f1)\n\
        echo "$(basename "$apk"): $size"\n\
    fi\n\
done\n\
\n\
echo ""\n\
echo "构建完成！APK文件保存在 /output/apk/ 目录下"\n\
' > /build.sh && chmod +x /build.sh

# 暴露输出目录
VOLUME ["/output"]

# 默认命令
CMD ["/build.sh"]