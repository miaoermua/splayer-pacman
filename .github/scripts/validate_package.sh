#!/bin/bash

# 验证 PKGBUILD 和 .SRCINFO 是否一致
set -e

echo "验证 PKGBUILD 和 .SRCINFO 的一致性..."

# 检查文件是否存在
if [ ! -f PKGBUILD ] || [ ! -f .SRCINFO ]; then
    echo "错误: PKGBUILD 或 .SRCINFO 文件不存在"
    exit 1
fi

# 提取版本信息进行比较
pkgbuild_ver=$(grep "^pkgver=" PKGBUILD | cut -d'=' -f2)
srcinfo_ver=$(grep -m 1 "^pkgver = " .SRCINFO | cut -d' ' -f3)

pkgbuild_rel=$(grep "^pkgrel=" PKGBUILD | cut -d'=' -f2)
srcinfo_rel=$(grep -m 1 "^pkgrel = " .SRCINFO | cut -d' ' -f3)

echo "PKGBUILD 版本: $pkgbuild_ver-$pkgbuild_rel"
echo ".SRCINFO 版本: $srcinfo_ver-$srcinfo_rel"

if [ "$pkgbuild_ver" != "$srcinfo_ver" ] || [ "$pkgbuild_rel" != "$srcinfo_rel" ]; then
    echo "错误: PKGBUILD 和 .SRCINFO 版本不匹配!"
    exit 1
else
    echo "版本检查通过"
fi

# 检查架构信息
for arch in x86_64 aarch64; do
    if ! grep -q "arch = $arch" .SRCINFO; then
        echo "错误: .SRCINFO 缺少架构 $arch"
        exit 1
    fi
done

echo "所有检查通过！"