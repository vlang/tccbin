#!/bin/bash

## this script should be run in V's main repo folder!

set -e

export CC="${CC:-gcc}"
export TCC_FOLDER="${TCC_FOLDER:-thirdparty/tcc}"
mkdir -p $TCC_FOLDER/lib/

rm -rf bdwgc/
git clone https://github.com/ivmai/bdwgc
LIBGC_COMMIT=$(git -C bdwgc rev-parse HEAD)
cd bdwgc/
./autogen.sh
CC=$CC CFLAGS='-Os -mtune=generic -fPIC' LDFLAGS='-Os -fPIC' ./configure \
	--disable-dependency-tracking \
	--disable-docs \
	--enable-handle-fork=yes \
	--enable-rwlock \
	--enable-threads=pthreads \
	--enable-static \
	--enable-shared=no \
	--enable-parallel-mark \
	--enable-single-obj-compilation \
	--enable-gc-debug \
	--with-libatomic-ops=yes \
	--enable-sigrt-signals

make
cd ..

cp bdwgc/.libs/libgc.a $TCC_FOLDER/lib/libgc.a
echo $LIBGC_COMMIT > $TCC_FOLDER/lib/libgc_commit.txt

ls -la $TCC_FOLDER/lib/libgc.a
echo "done compiling libgc, at commit $LIBGC_COMMIT ."
