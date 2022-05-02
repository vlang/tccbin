# thirdparty-freebsd-arm64

This is a prebuild tcc (git://repo.or.cz/tinycc.git), cut at commit d3e940c .

It is compiled with:
```shell
#!/bin/bash

## should be run in V's main repo folder!

rm -rf tinycc/
rm -rf thirdparty/tcc/

pushd .

git clone git://repo.or.cz/tinycc.git
cd tinycc

./configure --prefix=thirdparty/tcc \
            --bindir=thirdparty/tcc \
            --crtprefix=thirdparty/tcc/lib:/usr/lib:/usr/lib64:/usr/lib/aarch64-linux-gnu \
            --sysincludepaths=thirdparty/tcc/lib/tcc/include:/usr/local/include:/usr/include/aarch64-linux-gnu:/usr/include \
            --libpaths=thirdparty/tcc/lib:/usr/lib/aarch64-linux-gnu:/usr/lib64:/usr/lib:/lib/aarch64-linux-gnu:/lib:/usr/local/lib/aarch64-linux-gnu:/usr/local/lib \
            --debug
make
make install

popd

mv tinycc/thirdparty/tcc thirdparty/tcc

mv thirdparty/tcc/tcc thirdparty/tcc/tcc.exe

thirdparty/tcc/tcc.exe -v -v
```
