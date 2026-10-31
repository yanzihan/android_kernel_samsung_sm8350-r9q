#!/bin/bash
# PC 侧 Magisk boot 修补器 (复刻 Magisk app 的 patch 行为)
# 用法: patch_boot.sh <输入boot.img> <输出img> [PREINITDEVICE]
DIR="$(cd "$(dirname "$0")" && pwd)"
IN="$1"; OUT="$2"; PREINITDEVICE="$3"
[ -f "$IN" ] || { echo "❌ 输入文件不存在: $IN"; exit 1; }
cd "$DIR"

export SOURCEDMODE=1            # 跳过 util_functions 加载和设备检测
export BOOTMODE=false
[ -z $KEEPVERITY ] && export KEEPVERITY=false
[ -z $KEEPFORCEENCRYPT ] && export KEEPFORCEENCRYPT=false
[ -z $PATCHVBMETAFLAG ] && export PATCHVBMETAFLAG=false
[ -z $RECOVERYMODE ] && export RECOVERYMODE=false
[ -z $LEGACYSAR ] && export LEGACYSAR=false
[ -n "$PREINITDEVICE" ] && export PREINITDEVICE

# 替代 util_functions.sh 的最小函数集
ui_print() { echo "$1"; }
abort() { echo "❌ $1"; exit 1; }
grep_prop() { [ -f "$2" ] && sed -n "s/^$1=//p" "$2" | head -1; return 0; }
export -f ui_print abort grep_prop

bash boot_patch.sh "$IN" || exit 1
[ -f new-boot.img ] || { echo "❌ 未生成 new-boot.img"; exit 1; }
mv new-boot.img "$OUT"
echo "✅ 修补完成: $OUT"
