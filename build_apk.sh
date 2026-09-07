#!/bin/bash
set -e
export JAVA_HOME=/home/user/.super_doubao/super-doubao-runtime/workspace/jdk-17.0.2
export PATH=$JAVA_HOME/bin:/home/user/.super_doubao/super-doubao-runtime/workspace/flutter/bin:$PATH
export ANDROID_HOME=/home/user/.super_doubao/super-doubao-runtime/workspace/android-sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
cd /home/user/.super_doubao/super-doubao-runtime/workspace/chumian_ai/chumian_app
echo "=== Flutter doctor ==="
flutter doctor --android-licenses 2>/dev/null || true
echo "=== Building APK ==="
flutter build apk --release --target-platform android-arm64 2>&1
echo "=== Build result ==="
ls -la build/app/outputs/flutter-apk/*.apk 2>/dev/null
