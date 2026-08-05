#!/bin/bash
# 创建稳定的自签名代码签名证书（一次性）
# 作用：FastTranslate 的辅助功能权限与代码签名绑定。
#       若用 ad-hoc 签名（codesign -s -），每次重建二进制签名都变 → 权限失效 → 反复弹窗。
#       改用稳定自签名证书签名后，重建 App 权限仍然有效。
# 该脚本把证书私钥导入登录钥匙串后即删除本地副本，不留敏感文件。

set -e
cd "$(dirname "$0")/.."

IDENTITY="FastTranslate Development"

if security find-identity -p codesigning 2>/dev/null | grep -q "$IDENTITY"; then
    echo "✅ 签名身份已存在：$IDENTITY（无需重复创建）"
    exit 0
fi

echo "==> 生成自签名代码签名证书..."
TMP_DIR="$(mktemp -d)"
openssl req -x509 -newkey rsa:2048 -keyout "$TMP_DIR/key.pem" -out "$TMP_DIR/cert.pem" \
    -days 3650 -nodes -subj "/CN=FastTranslate Development" \
    -addext "keyUsage=digitalSignature" \
    -addext "extendedKeyUsage=codeSigning" 2>/dev/null

echo "==> 导入登录钥匙串..."
openssl pkcs12 -export -legacy -in "$TMP_DIR/cert.pem" -inkey "$TMP_DIR/key.pem" \
    -out "$TMP_DIR/ft.p12" -passout pass:fttemp 2>/dev/null
security import "$TMP_DIR/ft.p12" -k ~/Library/Keychains/login.keychain-db -P fttemp -T /usr/bin/codesign

rm -rf "$TMP_DIR"
echo "✅ 签名身份创建成功：$IDENTITY"
echo "   （注意：自签名证书未受系统信任，find-identity 会显示 NOT_TRUSTED，这是正常的，不影响 codesign 使用）"
