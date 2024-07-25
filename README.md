# thirdparty-freebsd-aarch64

This is a prebuild tcc (git://repo.or.cz/tinycc.git), cut at commit 08a4c52 .

It is compiled with:
```shell
#!/usr/bin/env bash

## should be run in V's main repo folder!

rm -rf tinycc/
rm -rf thirdparty/tcc/

pushd .

git clone git://repo.or.cz/tinycc.git
cd tinycc

./configure --prefix=thirdparty/tcc \
	    --bindir=thirdparty/tcc \
	    --crtprefix=thirdparty/tcc/lib:/usr/lib \
	    --sysincludepaths=thirdparty/tcc/lib/tcc/include:/usr/local/include:/usr/include \
	    --libpaths=thirdparty/tcc/lib:/usr/local/lib:/usr/lib:/lib \
	    --debug
gmake
gmake install

popd

mv tinycc/thirdparty/tcc thirdparty/tcc

mv thirdparty/tcc/tcc thirdparty/tcc/tcc.exe

thirdparty/tcc/tcc.exe -v -v
```
