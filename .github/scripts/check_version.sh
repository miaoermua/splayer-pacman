#!/bin/bash

set -e

# 获取当前本地版本
current_version=$(grep "^pkgver=" PKGBUILD | cut -d'=' -f2)

echo "当前本地版本: $current_version"

latest_release_response=$(curl -sSL -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/imsyy/SPlayer/releases/latest" || true)
latest_release=$(printf '%s' "$latest_release_response" | jq -r '.tag_name // empty')

if [ -n "$latest_release" ] && [ "$latest_release" != "null" ]; then
  latest_version="${latest_release#v}"
else
  echo "release/latest 未返回 tag_name，改为从 tags 获取最新版本"
  latest_version=$(git ls-remote --tags https://github.com/imsyy/SPlayer.git \
    | awk '{print $2}' \
    | sed 's#refs/tags/##' \
    | sed 's/\^{}$//' \
    | grep -E '^v[0-9]+(\.[0-9]+)*$' \
    | sort -V \
    | tail -n1 | sed 's/^v//')
fi

echo "最新上游版本: $latest_version"

# 比较版本
compare_versions() {
    local v1=$1
    local v2=$2

    # 确保版本号不为空且不为 "null"
    [ -n "$v1" ] && [ "$v1" != "null" ] || return 1
    [ -n "$v2" ] && [ "$v2" != "null" ] || return 0

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
