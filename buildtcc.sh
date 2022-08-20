#!/usr/local/bin/bash

## this script, should be run in V's main repo folder!

rm -rf tinycc/
rm -rf thirdparty/tcc/

pushd .

git clone git://repo.or.cz/tinycc.git
cd tinycc

export CC=cc
export CFLAGS='-O3 -flto'

./configure \
            --prefix=thirdparty/tcc \
            --bindir=thirdparty/tcc \
            --crtprefix=thirdparty/tcc/lib:/usr/lib:/usr/lib64 \
            --sysincludepaths=thirdparty/tcc/lib/tcc/include:/usr/local/include:/usr/include \
            --libpaths=thirdparty/tcc/lib/tcc:thirdparty/tcc/lib:/usr/lib64:/usr/lib:/lib:/usr/local/lib \
            --extra-cflags="$CFLAGS" \
	    --config-backtrace=yes \
	    --config-bcheck=yes \
            --debug
gmake
gmake install

popd

mv tinycc/thirdparty/tcc thirdparty/tcc

mv thirdparty/tcc/tcc thirdparty/tcc/tcc.exe

thirdparty/tcc/tcc.exe -v -v

