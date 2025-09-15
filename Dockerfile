# 使用Ubuntu作为基础镜像
FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_VERSION=3.22.3
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
RUN git clone https://github.com/flutter/flutter.git -b stable /opt/flutter
RUN /opt/flutter/bin/flutter doctor

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
# 获取依赖\n\
echo "获取Flutter依赖..."\n\
flutter pub get\n\
\n\
# 构建Android APK\n\
echo "构建Android APK..."\n\
flutter build apk --release --split-per-abi --no-shrink\n\
\n\
# 构建Linux应用\n\
echo "构建Linux应用..."\n\
flutter_distributor package --platform linux --targets deb,zip --skip-clean\n\
\n\
# 复制构建产物到输出目录\n\
echo "复制构建产物..."\n\
\n\
# 复制APK文件\n\
mkdir -p /output/android\n\
cp -r build/app/outputs/flutter-apk/*.apk /output/android/ 2>/dev/null || echo "未找到APK文件"\n\
\n\
# 复制Linux构建产物\n\
mkdir -p /output/linux\n\
cp -r build/dist/*/*.deb /output/linux/ 2>/dev/null || echo "未找到DEB文件"\n\
cp -r build/dist/*/*.zip /output/linux/ 2>/dev/null || echo "未找到ZIP文件"\n\
\n\
echo "构建完成！"\n\
echo "构建产物保存在以下路径："\n\
echo "- Android APK: /output/android/"\n\
echo "- Linux应用: /output/linux/"\n\
ls -la /output/android/ 2>/dev/null || echo "Android目录为空"\n\
ls -la /output/linux/ 2>/dev/null || echo "Linux目录为空"\n\
' > /build.sh && chmod +x /build.sh

# 暴露输出目录
VOLUME ["/output"]

# 默认命令
CMD ["/build.sh"]