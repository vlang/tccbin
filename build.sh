#!/bin/bash

## should be run in V's main repo folder!

set -e 

export TCC_COMMIT="${TCC_COMMIT:-mob}"
export TCC_FOLDER="${TCC_FOLDER:-thirdparty/tcc.$TCC_COMMIT}"

echo "TCC_COMMIT: $TCC_COMMIT"
echo "TCC_FOLDER: $TCC_FOLDER"
echo ===============================================================

rm -rf tinycc/
rm -rf thirdparty/tcc.original/
rsync -a thirdparty/tcc/ thirdparty/tcc.original/
## rm -rf $TCC_FOLDER

pushd .

git clone git://repo.or.cz/tinycc.git

cd tinycc

git checkout $TCC_COMMIT


### NB: the symlinks below are needed, to ensure proper support for bootstrapping tcc, otherwise backtraces will be disabled .
for i in include/*.h; do echo $i; ln -s $i $(basename $i); done

#	    --libdir=$TCC_FOLDER/lib \

./configure \
            --prefix=$TCC_FOLDER \
            --bindir=$TCC_FOLDER \
	    --tccdir=$TCC_FOLDER/lib \
            --includedir=$TCC_FOLDER/include \
            --crtprefix=$TCC_FOLDER/lib:/usr/lib \
            --sysincludepaths=$TCC_FOLDER/include:$TCC_FOLDER/lib/include:/usr/local/include:/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include:/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include \
            --libpaths=$TCC_FOLDER/lib:/usr/local/lib:/usr/lib:/lib \
	    --config-new_macho=yes \
	    --config-codesign \
            --extra-cflags=-O3 \
	    --config-bcheck=yes \
	    --config-backtrace=yes \
	    --enable-static \
	    --dwarf=5 \
            --debug

make
make install

popd

rsync -a --delete tinycc/$TCC_FOLDER/*                $TCC_FOLDER/
rsync -a          thirdparty/tcc.original/.git/       $TCC_FOLDER/.git/
rsync -a          thirdparty/tcc.original/lib/libgc*  $TCC_FOLDER/lib/
rsync -a          thirdparty/tcc.original/README.md   $TCC_FOLDER/README.md
rsync -a          build.sh                            $TCC_FOLDER/build.sh
mv                $TCC_FOLDER/tcc                     $TCC_FOLDER/tcc.exe

$TCC_FOLDER/tcc.exe -v -v

## needed for Big Sur
ln -s /System/DriverKit/usr/lib/libSystem.dylib $TCC_FOLDER/lib/libc.dylib

echo "tcc commit: $TCC_COMMIT . The tcc executable is ready in $TCC_FOLDER/tcc.exe "
