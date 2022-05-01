#!/bin/bash

## should be run in V's main repo folder!

rm -rf tinycc/
rm -rf thirdparty/tcc/*

pushd .

git clone git://repo.or.cz/tinycc.git
cd tinycc

./configure \
    --config-musl \
    --config-backtrace=yes \
    --config-bcheck=yes \
    --prefix=thirdparty/tcc \
    --bindir=thirdparty/tcc \
    --crtprefix=thirdparty/tcc/lib:/usr/lib64:/usr/lib/x86_64-linux-gnu:/usr/lib \
    --libpaths=thirdparty/tcc/lib:/usr/lib/x86_64-linux-gnu:/usr/lib64:/usr/lib:/lib/x86_64-linux-gnu:/lib:/usr/local/lib/x86_64-linux-gnu:/usr/local/lib \
    --debug

make
make install

popd

rsync -av tinycc/thirdparty/tcc/ thirdparty/tcc/

mv thirdparty/tcc/tcc thirdparty/tcc/tcc.exe

thirdparty/tcc/tcc.exe -v -v

