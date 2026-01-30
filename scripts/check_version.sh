#!/bin/bash

set -e

# 获取当前本地版本
current_version=$(grep "^pkgver=" PKGBUILD | cut -d'=' -f2)
current_version_clean="${current_version//_/-}"

echo "当前本地版本: $current_version"

# 从 GitHub API 获取最新的发布版本
latest_release=$(curl -s "https://api.github.com/repos/imsyy/SPlayer/releases/latest" | jq -r '.tag_name')
latest_version="${latest_release#v}"  # 移除 'v' 前缀

echo "最新上游版本: $latest_version"

# 比较版本
compare_versions() {
    local v1=$1
    local v2=$2

    # 将版本号标准化以便比较
    # 替换 _ 为 - 并处理 beta 标记
    local normalized_v1="${v1//_/-}"
    local normalized_v2="${v2//_/-}"

    # 使用 sort -V 来比较版本号
    # 如果排序后的第一个是 v2，说明 v1 > v2
    # 如果排序后的第一个是 v1，说明 v1 <= v2
    local sorted_first=$(printf '%s\n%s' "$normalized_v1" "$normalized_v2" | sort -V | head -n1)

    if [ "$sorted_first" = "$normalized_v2" ] && [ "$normalized_v1" != "$normalized_v2" ]; then
        # v2 < v1, 所以 v1 > v2
        return 0  # v1 > v2
    elif [ "$sorted_first" = "$normalized_v1" ] && [ "$normalized_v1" != "$normalized_v2" ]; then
        # v1 < v2, 所以 v2 > v1
        return 1  # v2 > v1
    else
        # v1 == v2
        return 0  # v1 == v2
    fi
}

if compare_versions "$current_version" "$latest_version"; then
    echo "已是最新版本或本地版本更新"
    echo "VERSION_UPDATE=false"
    if [ -n "$GITHUB_ENV" ]; then
        echo "VERSION_UPDATE=false" >> $GITHUB_ENV
    fi
    exit 0
else
    # compare_versions 返回非0值表示 v2 > v1
    echo "发现新版本: $latest_version"
    echo "VERSION_UPDATE=true"
    echo "NEW_VERSION=$latest_version"
    current_time=$(date +%s)
    echo "CURRENT_TIME=$current_time"
    if [ -n "$GITHUB_ENV" ]; then
        echo "VERSION_UPDATE=true" >> $GITHUB_ENV
        echo "NEW_VERSION=$latest_version" >> $GITHUB_ENV
        echo "CURRENT_TIME=$current_time" >> $GITHUB_ENV
    fi
    exit 0
fi