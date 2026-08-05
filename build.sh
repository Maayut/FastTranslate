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

echo "==> 3/3 签名..."

# 优先使用稳定自签名证书（保证重建后辅助功能权限不失效）；没有则退回 ad-hoc
IDENTITY="FastTranslate Development"
if security find-identity -p codesigning 2>/dev/null | grep -q "$IDENTITY"; then
    codesign --force --deep --sign "$IDENTITY" "$APP" 2>/dev/null
    echo "   签名身份：$IDENTITY（稳定签名 ✓）"
else
    codesign --force --deep --sign - "$APP" 2>/dev/null
    echo "   ⚠️ 未找到稳定签名身份，退回 ad-hoc 签名"
    echo "   （提示：运行 scripts/setup-signing-cert.sh 创建稳定证书，可避免重建后权限失效）"
fi

echo "✅ 完成：$APP"
echo "   安装：open \"$BUILD_DIR\"  或 把 FastTranslate.app 拖进 /Applications"
