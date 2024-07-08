#!/usr/bin/env bash

## error early:
set -e

## this script, should be run in V's main repo folder!

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

export CC=gcc
export CFLAGS='-O3'

./configure \
            --prefix=$TCC_FOLDER \
            --bindir=$TCC_FOLDER \
            --crtprefix=$TCC_FOLDER/lib:/usr/lib:/usr/lib64 \
            --sysincludepaths=$TCC_FOLDER/lib/tcc/include:/usr/local/include:/usr/include \
            --libpaths=$TCC_FOLDER/lib/tcc:$TCC_FOLDER/lib:/usr/lib64:/usr/lib:/lib:/usr/local/lib \
            --cc="$CC" \
            --extra-cflags="$CFLAGS" \
	    --config-backtrace=yes \
	    --config-bcheck=yes \
            --debug

##     --extra-ldflags="-L/usr/home/ec2-user/v/tinycc -ltcc" \

gmake
gmake install

popd

rsync -a --delete tinycc/$TCC_FOLDER/                 $TCC_FOLDER/
rsync -a          thirdparty/tcc.original/.git/       $TCC_FOLDER/.git/
rsync -a          thirdparty/tcc.original/lib/libgc*  $TCC_FOLDER/lib/
rsync -a          thirdparty/tcc.original/README.md   $TCC_FOLDER/README.md
rsync -a          build.sh                            $TCC_FOLDER/build.sh
mv                $TCC_FOLDER/tcc                     $TCC_FOLDER/tcc.exe

$TCC_FOLDER/tcc.exe -v -v

echo "tcc commit: $TCC_COMMIT . The tcc executable is ready in $TCC_FOLDER/tcc.exe "
