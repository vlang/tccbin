# thirdparty-linux-arm

This is a prebuild tcc (git://repo.or.cz/tinycc.git), cut at commit 0378168 .

It is compiled with:

```shell
#!/usr/bin/env bash

## should be run in V's main repo folder!

rm -rf tinycc/
rm -rf thirdparty/tcc/

pushd .

git clone git://repo.or.cz/tinycc.git
cd tinycc

./configure \
            --prefix=thirdparty/tcc \
            --bindir=thirdparty/tcc \
            --crtprefix=thirdparty/tcc/lib:/usr/lib:/usr/lib/arm-linux-gnueabihf \
            --libpaths=thirdparty/tcc/lib:/usr/lib/arm-linux-gnueabihf:/usr/lib:/lib/arm-linux-gnueabihf:/lib:/usr/local/lib/arm-linux-gnueabihf:/usr/local/lib \
            --extra-cflags="-O3 -flto" \
            --debug

make
make install

popd

mv tinycc/thirdparty/tcc thirdparty/tcc

mv thirdparty/tcc/tcc thirdparty/tcc/tcc.exe

thirdparty/tcc/tcc.exe -v -v
```
