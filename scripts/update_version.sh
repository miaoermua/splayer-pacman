#!/bin/bash

set -e

if [ $# -ne 1 ]; then
    echo "用法: $0 <new_version>"
    exit 1
fi

new_version=$1
old_version=$(grep "^pkgver=" PKGBUILD | cut -d'=' -f2)

echo "正在将版本从 $old_version 更新到 $new_version"

new_pkgrel=1

new_version_formatted="${new_version//_/-}"

echo "获取新版本的 SHA256 值..."

# 创建临时目录
tmp_dir=$(mktemp -d)
cleanup() {
    rm -rf "$tmp_dir"
}
trap cleanup EXIT

# 为每个架构下载并计算 SHA256
echo "下载 x86_64 版本"
x86_64_url="https://github.com/imsyy/SPlayer/releases/download/v${new_version_formatted}/splayer-${new_version_formatted}-x64.pacman"
curl -L -o "$tmp_dir/splayer-x64.pacman" "$x86_64_url"
x86_64_sha256=$(sha256sum "$tmp_dir/splayer-x64.pacman" | cut -d' ' -f1)
echo "x86_64 SHA256: $x86_64_sha256"

echo "下载 aarch64 版本"
aarch64_url="https://github.com/imsyy/SPlayer/releases/download/v${new_version_formatted}/splayer-${new_version_formatted}-aarch64.pacman"
curl -L -o "$tmp_dir/splayer-aarch64.pacman" "$aarch64_url"
aarch64_sha256=$(sha256sum "$tmp_dir/splayer-aarch64.pacman" | cut -d' ' -f1)
echo "aarch64 SHA256: $aarch64_sha256"

# 创建新的 PKGBUILD
cat > PKGBUILD.new << EOF
# Maintainer: miaoermua <miaoermua@gmail.com>
# Updated for native pacman package support with multi-arch(arm64/amd64)

_pkgname=splayer
pkgname=splayer
pkgver=${new_version}
pkgrel=${new_pkgrel}
pkgdesc="Splayer | A minimalist music player"
arch=('x86_64' 'aarch64')
url="https://github.com/imsyy/SPlayer"
license=("AGPL-3.0-only")
provides=("\${_pkgname}=\${pkgver}")
conflicts=("\${_pkgname}")
depends=(
  'c-ares'
  'ffmpeg'
  'gtk3'
  'libevent'
  'libvpx'
  'libxslt'
  'libxss'
  'minizip'
  'nss'
  're2'
  'snappy'
  'libnotify'
)
optdepends=(
  'http-parser: required by some Electron builds'
  'libappindicator: for system tray icon support'
)
options=(!strip !debug)

if [ "\$CARCH" = "x86_64" ]; then
    _arch_pkg="x64"
    _sha256="$x86_64_sha256"
elif [ "\$CARCH" = "aarch64" ]; then
    _arch_pkg="aarch64"
    _sha256="$aarch64_sha256"
else
    error "Unsupported architecture: \$CARCH"
    exit 1
fi

source=("https://github.com/imsyy/SPlayer/releases/download/v\${pkgver//_/-}/splayer-\${pkgver//_/-}-\${_arch_pkg}.pacman")
sha256sums=("\${_sha256}")

noextract=("\${source[0]##*/}")

package() {
    msg2 "Extracting native pacman package for \$CARCH..."
    bsdtar -x -f "\${srcdir}/\${source[0]##*/}" -C "\$pkgdir" --exclude .PKGINFO --exclude .MTREE --exclude .INSTALL
}
EOF

mv PKGBUILD.new PKGBUILD

# 更新 .SRCINFO 文件
echo "更新 .SRCINFO 文件..."

# 替换版本格式
srcinfo_version="${new_version//-/_}"

cat > .SRCINFO << EOF
pkgbase = splayer
	pkgdesc = Splayer | A minimalist music player
	pkgver = ${srcinfo_version}
	pkgrel = ${new_pkgrel}
	url = https://github.com/imsyy/SPlayer
	arch = x86_64
	arch = aarch64
	license = AGPL-3.0-only
	depends = c-ares
	depends = ffmpeg
	depends = gtk3
	depends = libevent
	depends = libvpx
	depends = libxslt
	depends = libxss
	depends = minizip
	depends = nss
	depends = re2
	depends = snappy
	depends = libnotify
	optdepends = http-parser: required by some Electron builds
	optdepends = libappindicator: for system tray icon support
	provides = splayer=${srcinfo_version}
	conflicts = splayer
	noextract = splayer-${new_version_formatted}-x64.pacman
	options = !strip
	options = !debug
	source_x86_64 = https://github.com/imsyy/SPlayer/releases/download/v${new_version_formatted}/splayer-${new_version_formatted}-x64.pacman
	sha256sums_x86_64 = ${x86_64_sha256}
	source_aarch64 = https://github.com/imsyy/SPlayer/releases/download/v${new_version_formatted}/splayer-${new_version_formatted}-aarch64.pacman
	sha256sums_aarch64 = ${aarch64_sha256}

pkgname = splayer
EOF

echo "版本已成功更新到 $new_version"