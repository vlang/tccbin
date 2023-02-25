#!/bin/bash

# Ensure that thirdparty/tcc/ exists (simplifies the script logic)
mkdir -p thirdparty/tcc/

rm -rf tinycc/
rm -rf thirdparty/tcc/tcc.exe  thirdparty/tcc/include thirdparty/tcc/lib thirdparty/tcc/share

pushd .
git clone git://repo.or.cz/tinycc.git
cd tinycc

### NB: the symlinks below are needed, to ensure proper support for bootstrapping tcc, otherwise backtraces will be disabled .
for i in include/*.h; do echo $i; ln -s $i $(basename $i); done

./configure --prefix=thirdparty/tcc \
            --bindir=thirdparty/tcc \
            --crtprefix=thirdparty/tcc/lib:/usr/lib \
            --libpaths=thirdparty/tcc/lib:/usr/local/lib:/usr/lib:/lib \
            --sysincludepaths=thirdparty/tcc/lib/tcc/include:/usr/local/include:/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include:/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include \
	    --config-bcheck=yes --config-new_macho=yes --config-codesign --config-backtrace=yes \
            --debug
make
make install
popd

mv tinycc/thirdparty/tcc/* thirdparty/tcc/
mv thirdparty/tcc/lib/tcc/*.o thirdparty/tcc/lib/
mv thirdparty/tcc/lib/tcc/*.a thirdparty/tcc/lib/
tree thirdparty/tcc/lib/

mv thirdparty/tcc/tcc thirdparty/tcc/tcc.exe
thirdparty/tcc/tcc.exe -v -v

## needed for Big Sur
ln -s /System/DriverKit/usr/lib/libSystem.dylib $PWD/thirdparty/tcc/lib/libc.dylib
