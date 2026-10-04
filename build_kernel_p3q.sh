#!/bin/bash

export ARCH=arm64

# 每次编译前自动清空并重新创建 out 目录，确保无残留缓存
rm -rf out
mkdir -p out

TOPDIR=$(pwd)
CLANG_DIR=${TOPDIR}/toolchains/clang/clang-r416183b
GCC64_DIR=${TOPDIR}/toolchains/gcc64

export PATH=${CLANG_DIR}/bin:${GCC64_DIR}/bin:$PATH

BUILD_CROSS_COMPILE=${GCC64_DIR}/bin/aarch64-linux-android-
KERNEL_LLVM_BIN=${CLANG_DIR}/bin/clang
CLANG_TRIPLE=aarch64-linux-gnu-

KERNEL_MAKE_ENV="DTC_EXT=${TOPDIR}/tools/dtc CONFIG_BUILD_ARM64_DT_OVERLAY=y"

echo "=== 1. 开始生成配置 ==="
make -j16 -C ${TOPDIR} O=${TOPDIR}/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CONFIG_SECTION_MISMATCH_WARN_ONLY=y vendor/p3q_chn_hkx_defconfig

if [ $? -ne 0 ]; then
    echo "❌ 配置生成失败！"
    exit 1
fi

echo "=== 2. 开始单线程编译 (调试模式) ==="
# -j1 单线程编译，便于精确定位报错点
make -j16 -C ${TOPDIR} O=${TOPDIR}/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CONFIG_SECTION_MISMATCH_WARN_ONLY=y 2>&1 | tee build.log

if [ $? -eq 0 ]; then
    echo "=== 3. 编译成功，拷贝 Image ==="
    cp out/arch/arm64/boot/Image ${TOPDIR}/arch/arm64/boot/Image
    echo "✅ 编译完成！"
else
    echo "❌ 编译报错！请检查上方终端输出，或直接查看生成的 build.log 文件。"
    exit 1
fi
