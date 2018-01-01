#!/bin/bash
# 定义下载的库的名字
source='ffmpeg-3.4'

#临时目录 存放.o文件
cache="cache"

# 保存静态库
staticdir=`pwd`/"zahi-ffmpeg-iOS"

# 添加FFmpeg配置选项
# Toolchain options:工具链选项（指定我么需要编译平台CPU架构类型，例如：arm64、x86等等…）
# --enable-cross-compile:交叉编译
# Developer options:开发者选项
# --disable-debug: 禁止使用调试模式
# Program options选项
# --disable-programs:不允许建立命令行程序
# Documentation options：文档选项
# --disable-doc：不需要编译文档
# Toolchain options：工具链选项
# --enable-pic：允许建立与位置无关代码
configure_flags="--enable-cross-compile --disable-debug --disable-programs --disable-doc --enable-pic"

# 定义默认CPU平台架构类型
archs="arm64 armv7 x86_64 i386"

# 指定这个库编译系统的版本
targetversion="8.0"

# 接受命令后输入参数
# 动态接受命令行输入CPU平台架构类型
if [ "$*" ]
then
    archs="$*"
fi

# 安装汇编器->yasm
if [ ! `which yasm` ]
then
    if [ ! `which brew` ]
    then
        echo "安装brew"
        ruby -e "$(curl -fsSL -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" || exit 1
    fi
    echo "安装yasm"
    brew install yasm || exit 1
fi
echo "循环编译"

# for循环编译FFmpeg静态库
currentdir=`pwd`
for arch in $archs
do 
    echo "开始编译"

    # 创建目录
    mkdir -p "$cache/$arch"
    # 进入这个目录
    cd "$cache/$arch"

    # 配置编译CPU结构类型
    archflags="-arch $arch"

    # 判断是那个CPU
    if [ "$arch" = "i386" -o "$arch" = "x86_64" ]
    then
        # 模拟器
        platform="iPhoneSimulator"
        # 支持最小系统版本
        archflags="$archflags -mios-simulator-version-min=$targetversion"
    else
        # 真机
        platform="iPhoneOS"
        # 支持最小系统版本
        archflags="$archflags -mios-version-min=$targetversion -fembed-bitcode"
        # 如果架构是arm64
        if [ "$arch" = "arm64" ]
        then
            # 变量访问越界一类的问题
            EXPORT="CASPP_FIX_XCODE5=1"
        fi
    fi

    # 正式编译
    # tr命令可以对来自标准输入的字符进行替换、压缩、删除
    XCRUN_SDK=`echo $platform | tr '[:upper:]' '[:lower:]'`
    # 编译平台
    CC="xcrun -sdk $XCRUN_SDK clang"

    # 结构类型
    if [ "arch" = "arm64" ]
    then
        # preprocessor.pl帮助我们编译FFmpeg->arm64位静态库
        AS="gas-preprocessor.pl -arch aarch64 -- $CC"
    else
        AS="$CC"
    fi
    # 目录找到FFmepg编译源代码目录->设置编译配置->编译FFmpeg源码
    # --target-os:目标系统->darwin(mac系统早起版本名字)
    # darwin:是mac系统、iOS系统祖宗
    # --arch:CPU平台架构类型
    # --cc：指定编译器类型选项
    # --as:汇编程序
    # $configure_flags最初配置
    # --extra-cflags
    # --prefix：静态库输出目录
    TMPDIR=${TMPDIR/%\/} $currentdir/$source/configure \
        --target-os=darwin \
        --arch=$arch \
        --cc="$CC" \
        --as="$AS" \
        $configure_flags \
        --extra-cflags="$archflags" \
        --extra-ldflags="$archflags" \
        --prefix="$staticdir/$arch" \
        || exit 1
    echo "执行了"
    # 执行命令
    make -j3 install $EXPORT || exit 1
    # 回到我们脚本目录
    cd $currentdir
    
done
