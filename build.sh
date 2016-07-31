#!/bin/bash

set -e

#git submodule update --init --recursive
cd "$(dirname "$0")" # switch to script directory
SCRIPT_ROOT_DIR=`pwd`

echo "Cleaning up old dirs"
#rm -rf $SCRIPT_ROOT_DIR/install
#rm -rf $SCRIPT_ROOT_DIR/build
rm -rf $SCRIPT_ROOT_DIR/framework/include
rm -rf $SCRIPT_ROOT_DIR/framework/lua
rm -rf $SCRIPT_ROOT_DIR/framework/lib

export INSTALL_DIR=$SCRIPT_ROOT_DIR/install

mkdir -p ${INSTALL_DIR}/man

cd distro/exe/luajit-rocks/luajit-2.1

#ISDKP=$(xcrun --sdk iphoneos --show-sdk-path)
#ICC=$(xcrun --sdk iphoneos --find clang)
#ISDKF="-arch armv7 -isysroot $ISDKP"
ISDKP=$(xcrun --sdk iphonesimulator --show-sdk-path)
ICC=$(xcrun --sdk iphonesimulator --find clang)
#ISDKF="-arch x86_64 -isysroot $ISDKP"
#ARCH=i386
ARCH=x86_64
ISDKF="-arch $ARCH -mios-simulator-version-min=8.1 -isysroot $ISDKP"
#make HOST_CC="clang -m32 -arch i386" CROSS="$(dirname $ICC)/" \
#       TARGET_FLAGS="$ISDKF" TARGET_SYS=iOS

#(make HOST_CC="clang -m32 -arch x86_64" CROSS="$(dirname $ICC)/" \
#(make HOST_CC="clang -m32 -arch $ARCH" CROSS="$(dirname $ICC)/" \
(make HOST_CC="clang -arch $ARCH" CROSS="$(dirname $ICC)/" \
  TARGET_FLAGS="$ISDKF" TARGET_SYS=iOS) || exit 1


echo "Done installing Lua"

export MAKE=make
export MAKEARGS=-j$(getconf _NPROCESSORS_ONLN)
#export MAKEARGS=""

cd $SCRIPT_ROOT_DIR
#(cmake -E make_directory build && cd build && do_cmake_config ..) || exit 1


SCRIPT_DIR=$( cd $(dirname $0) ; pwd -P )
XCODE_ROOT=`xcode-select -print-path`
IPHONE_SDKVERSION=`xcodebuild -showsdks | grep iphoneos | egrep "[[:digit:]]+\.[[:digit:]]+" -o | tail -1`
ARM_DEV_CMD="xcrun --sdk iphoneos"
SIM_DEV_CMD="xcrun --sdk iphonesimulator"
#EXTRA_FLAGS="-miphoneos-version-min=6.0 -fembed-bitcode"
#EXTRA_FLAGS="-miphoneos-version-min=6.0"
EXTRA_FLAGS="-miphoneos-version-min=8.1"





#DEV_CMD=$SIM_DEV_CMD
#NEON_FLAGS=""
#export CXX="$DEV_CMD clang++ -arch $1 $EXTRA_FLAGS $NEON_FLAGS"
#export CC="$DEV_CMD clang -arch $1 $EXTRA_FLAGS $NEON_FLAGS"
#XCMAKE=`$DEV_CMD --find make`
#XCPATH=`dirname $XCMAKE`
#export PATH="$XCPATH:$PATH"
#XCRANLIB=`$DEV_CMD --find ranlib`
#XCPATH=`dirname $XCRANLIB`
#export PATH="$XCPATH:$PATH"

#export ASM_DEFINES="--sdk iphonesimulator clang -arch -miphoneos-version-min=6.0"

configure_exports() {
  if [[ $1 = arm* ]]; then
    DEV_CMD=$ARM_DEV_CMD
  else
    DEV_CMD=$SIM_DEV_CMD
  fi
  if [[ $1 = armv7* ]]; then
    NEON_FLAGS=" -D__NEON__ -mfpu=neon"
  else
    NEON_FLAGS=""
  fi
  export CXX="$DEV_CMD clang++ -arch $1 $EXTRA_FLAGS $NEON_FLAGS"
  export CC="$DEV_CMD clang -arch $1 $EXTRA_FLAGS $NEON_FLAGS"
  #export ASM="/Applications/Xcode.app/Contents/Developer/usr/bin/$DEV_CMD clang -arch $1 $EXTRA_FLAGS $NEON_FLAGS"
  export ASM_DEFINES="--sdk iphonesimulator clang -arch -miphoneos-version-min=6.0"
  XCMAKE=`$DEV_CMD --find make`
  XCPATH=`dirname $XCMAKE`
  export PATH="$XCPATH:$PATH"
  XCRANLIB=`$DEV_CMD --find ranlib`
  XCPATH=`dirname $XCRANLIB`
  export PATH="$XCPATH:$PATH"
}

generate_arch() {
  configure_exports $1
  #rm -rf $SCRIPT_DIR/build
  #mkdir -p $SCRIPT_DIR/build
  cd $SCRIPT_DIR/build
  SROOT=`$DEV_CMD --show-sdk-path`
  #SROOT=`"xcrun --sdk iphonesimulator" --show-sdk-path`
  #SROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator9.3.sdk"
  cmake .. -DCMAKE_INSTALL_PREFIX="$SCRIPT_DIR/installed/" -DCMAKE_OSX_SYSROOT=$SROOT \
    -DCMAKE_VERBOSE_MAKEFILE=ON -DWITH_LUAROCKS=OFF -DWITH_LUAJIT21=ON
  make install
  cd $SCRIPT_DIR

}


do_cmake_config() {

  #  -DLUAJIT_SYSTEM_MINILUA="$SCRIPT_ROOT_DIR/distro/exe/luajit-rocks/luajit-2.1/src/host/minilua" \
  #  -DLUAJIT_SYSTEM_BUILDVM="$SCRIPT_ROOT_DIR/distro/exe/luajit-rocks/luajit-2.1/src/host/buildvm" \
  #-DLUAJIT_CPU_SSE2=OFF -DLUAJIT_ENABLE_LUA52COMPAT=OFF \
  #configure_exports x86_64
  #iconfigure_exports i386
  configure_exports $ARCH
  echo "-----------HERE--------------"
  echo $CC
  SROOT=`$DEV_CMD --show-sdk-path`
  #SROOT=`"xcrun --sdk iphonesimulator" --show-sdk-path`
  #SROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator9.3.sdk"

    #-DCMAKE_TOOLCHAIN_FILE="$SCRIPT_ROOT_DIR/cmake/iOS.cmake"\
  echo $SROOT
  cmake $1 -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DWITH_LUAROCKS=OFF \
    -DWITH_LUAJIT21=ON\
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" -DCMAKE_INSTALL_SUBDIR="${CMAKE_INSTALL_SUBDIR}" \
    -DLIBRARY_OUTPUT_PATH_ROOT="${INSTALL_DIR}" \
    -DLIBRARY_OUTPUT_PATH="${INSTALL_DIR}" \
    -DCMAKE_OSX_SYSROOT=$SROOT \
    -DCMAKE_C_FLAGS="-DDISABLE_POSIX_MEMALIGN" \
    -DLUAJIT_SYSTEM_MINILUA="$SCRIPT_ROOT_DIR/distro/exe/luajit-rocks/luajit-2.1/src/host/minilua" \
    -DLUAJIT_SYSTEM_BUILDVM="$SCRIPT_ROOT_DIR/distro/exe/luajit-rocks/luajit-2.1/src/host/buildvm" \
    #-DCMAKE_C_FLAGS=-fPIC -DCMAKE_CXX_FLAGS=-fPIC
    #-DCMAKE_ASM_DEFINES="--sdk iphonesimulator clang -arch -miphoneos-version-min=6.0"
    #-DCMAKE_ASM_COMPILER="$CC"
    #-DCMAKE_CXX_COMPILER="/Applications/Xcode.app/Contents/Developer/usr/bin/xcrun" \
    #-DCMAKE_C_COMPILER="/Applications/Xcode.app/Contents/Developer/usr/bin/xcrun" \
    #-DCMAKE_CXX_FLAGS="$DEV_CMD clang++ -arch $1 $EXTRA_FLAGS $NEON_FLAGS" \
    #-DCMAKE_C_FLAGS="$DEV_CMD clang++ -arch $1 $EXTRA_FLAGS $NEON_FLAGS"
  echo " -------------- Configuring DONE ---------------"



}


#generate_arch x86_64


configure_exports $ARCH


cd $SCRIPT_ROOT_DIR
(cmake -E make_directory build && cd build && do_cmake_config ..) || exit 1

echo "-----------HERE--------------"
echo $CC

echo $ASM

cd build



#  configure_exports x86_64
echo $ASM_DEFINES
(cd distro/exe && $MAKE $MAKEARGS install) || exit 1

(cd distro/pkg/cwrap && $MAKE $MAKEARGS install) || exit 1


#(cd distro/extra/luaffifb && $MAKE $MAKEARGS install) || exit 1

#(cd distro/pkg/sundown && $MAKE $MAKEARGS install) || exit 1
#(cd distro/pkg && $MAKE $MAKEARGS install) || exit 1

#(cd distro/extra && $MAKE  $MAKEARGS install) || exit 1


#cd build

#(cd distro/exe && $MAKE $MAKEARGS install) || exit 1
# cwrap needs to be there first
#(cd distro/pkg/cwrap && $MAKE $MAKEARGS install) || exit 1
(cd distro/pkg && $MAKE $MAKEARGS install) || exit 1

# Cutorch installs some headers/libs used by other modules in extra
#if [[ "$WITH_CUDA" == "ON" ]]; then
#  (cd distro/extra/cutorch && $MAKE $MAKEARGS install) || exit 1
#fi

(cd distro/extra && $MAKE  $MAKEARGS install) || exit 1
#(cd src && $MAKE $MAKEARGS install) || exit 2

cd ..


mkdir -p $SCRIPT_ROOT_DIR/framework/lib

cp $SCRIPT_ROOT_DIR/distro/exe/luajit-rocks/luajit-2.1/src/libluajit.a $SCRIPT_ROOT_DIR/framework/lib
cp $SCRIPT_ROOT_DIR/install/*.a $SCRIPT_ROOT_DIR/framework/lib

cp -r $SCRIPT_ROOT_DIR/install/share/lua/5.1 $SCRIPT_ROOT_DIR/framework/lua
cp -r $SCRIPT_ROOT_DIR/install/include $SCRIPT_ROOT_DIR/framework/include

extract_archive() {
  mkdir $1
  cd $1
  ar -x ../lib$1.a
  cd ..
}

#libTH_static.a    libjpeg.a   libluajit   libnnx.a    libppm.a    libthreads.a
#libimage.a    libluaT_static.a  libluajit.a   libpng.a    libsys.a    libtorch.a
extract_recombine() {
  #cd $SCRIPT_DIR/framework/lib/$1
  cd $SCRIPT_DIR/framework/lib/
  extract_archive luajit
  extract_archive TH_static
  extract_archive image
  extract_archive jpeg
  extract_archive luaT_static
  extract_archive nnx
  extract_archive png
  extract_archive ppm
  extract_archive sys
  extract_archive threads
  extract_archive torch
  extract_archive THNN_static
  ar -qc libtorch-1.a luajit/*.o TH_static/*.o luaT_static/*.o image/*.o jpeg/*.o nnx/*.o \
    png/*.o ppm/*.o sys/*.o threads/*.o torch/*.o THNN_static/*.o
  cp libtorch-1.a libtorch.a
  cd $SCRIPT_DIR
}

extract_recombine

rm -rf $SCRIPT_DIR/Torch.framework

echo "creating framework"
mkdir -p $SCRIPT_DIR/Torch.framework/Versions/A/Headers
cp $SCRIPT_DIR/framework/lib/libtorch.a \
  $SCRIPT_DIR/Torch.framework/Versions/A/Torch
cp -r $SCRIPT_DIR/framework/include/* \
  $SCRIPT_DIR/Torch.framework/Versions/A/Headers
cp -r $SCRIPT_DIR/framework/lua \
  $SCRIPT_DIR/Torch.framework/Versions/A/Resources
cd $SCRIPT_DIR/Torch.framework/Versions
ln -s A Current
cd $SCRIPT_DIR/Torch.framework
ln -s Versions/Current/Torch Torch
ln -s Versions/Current/Headers Headers
ln -s Versions/Current/Resources Resources

echo "creating header files"
HEADER=$SCRIPT_DIR/Torch.framework/Versions/A/Headers/Torch.h
echo '#ifndef TORCH_IOS_FRAMEWORK_TORCH_H' > $HEADER
echo '#define TORCH_IOS_FRAMEWORK_TORCH_H' >> $HEADER
echo '#ifdef __cplusplus' >> $HEADER
echo 'extern "C" {' >> $HEADER
echo '#endif' >> $HEADER
echo '#include "TH/TH.h"' >> $HEADER
echo '#include "lua.h"' >> $HEADER
echo '#include "luaconf.h"' >> $HEADER
echo '#include "lauxlib.h"' >> $HEADER
echo '#include "luaT.h"' >> $HEADER
echo '#include "lualib.h"' >> $HEADER
echo '#ifdef __cplusplus' >> $HEADER
echo '}' >> $HEADER
echo '#endif' >> $HEADER
echo '#endif' >> $HEADER
echo >> $HEADER

cat $SCRIPT_DIR/Torch.framework/Versions/A/Headers/luaT.h | \
  sed 's/include [<]/include "/g' | \
  sed 's/[>]$/"/g' > \
  $SCRIPT_DIR/Torch.framework/Versions/A/Headers/luaT-new.h

mv  $SCRIPT_DIR/Torch.framework/Versions/A/Headers/luaT-new.h \
  $SCRIPT_DIR/Torch.framework/Versions/A/Headers/luaT.h



echo "done"
