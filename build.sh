#!/bin/bash
# FastTranslate 构建脚本（无需 Xcode）
set -e
cd "$(dirname "$0")"

APP_NAME="FastTranslate"
BUILD_DIR="Build"

echo "==> 1/3 编译（swift build -c release）..."
swift build -c release --package-path . -Xswiftc -O

echo "==> 2/3 打包 .app 结构..."
BIN=".build/release/$APP_NAME"
APP="$BUILD_DIR/$APP_NAME.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$APP_NAME"
cp "$BUILD_DIR/Info.plist" "$APP/Contents/Info.plist"

echo "==> 3/3 ad-hoc 签名..."
codesign --force --deep --sign - "$APP" >/dev/null 2>&1

echo "✅ 完成：$APP"
echo "   安装：open \"$BUILD_DIR\"  或 把 FastTranslate.app 拖进 /Applications"
