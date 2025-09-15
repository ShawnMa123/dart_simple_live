# Flutter应用Docker构建指南

这个Dockerfile可以让你在Linux服务器上构建Flutter应用，无需手动安装Flutter SDK和Android SDK。

## 构建产物路径

构建完成后，所有产物将保存在容器的`/output`目录中：

- **Android APK文件**: `/output/android/`
  - `app-armeabi-v7a-release.apk` (ARM 32位)
  - `app-arm64-v8a-release.apk` (ARM 64位)
  - `app-x86_64-release.apk` (x86 64位)

- **Linux应用**: `/output/linux/`
  - `*.deb` (Debian安装包)
  - `*.zip` (便携版压缩包)

## 使用方法

### 方法1: 使用Docker命令

1. 构建Docker镜像：
```bash
docker build -t flutter-builder .
```

2. 运行容器并映射输出目录：
```bash
docker run --rm -v $(pwd)/output:/output flutter-builder
```

3. 构建完成后，在当前目录的`output`文件夹中查看构建产物：
```bash
ls -la output/android/  # 查看APK文件
ls -la output/linux/    # 查看Linux应用
```

### 方法2: 使用Docker Compose（推荐）

1. 运行构建：
```bash
docker-compose up --build
```

2. 构建完成后，在`output`目录中查看构建产物。

## 注意事项

1. **构建时间**: 首次构建可能需要较长时间（20-30分钟），因为需要下载Flutter SDK和Android SDK。

2. **磁盘空间**: 确保有足够的磁盘空间（至少5GB）。

3. **内存要求**: 建议至少4GB RAM。

4. **网络连接**: 构建过程需要下载依赖，确保网络连接稳定。

## 故障排除

如果构建失败，可以进入容器调试：

```bash
docker run -it --rm -v $(pwd)/output:/output flutter-builder /bin/bash
```

然后手动执行构建步骤：
```bash
cd simple_live_app
flutter pub get
flutter build apk --release --split-per-abi --no-shrink
```

## 自定义构建

如果需要修改构建参数，可以编辑Dockerfile中的构建脚本部分，或者创建自定义的构建脚本。