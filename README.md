# thirdparty-windows-amd64 (tcc64, tccwin64)

This repository contains a prebuilt [tcc compiler](https://repo.or.cz/tinycc.git),
imported from https://github.com/vlang/tccbin_win, 
whose source code is cut at commit 
[9eef339](https://repo.or.cz/tinycc.git/commit/9eef33993ade2d3b964d19b1081978ceae5d359d) (20200605),
from the mob branch. 

It is a ***minimalistic*** C compiler, that is just enough to be V's
backend. It is small and fast, although it does not produce optimised
executables. For that, use MSVC, GCC or CLANG instead.

## Target OS
The tcc build here produces ***64-bit executables***, compatiable with ***64-bit Windows***.  

## What if V reports missing C header files?
In this case, please create a PR to help us improve it.
Please try finding the missing header files in
[this](http://download.savannah.gnu.org/releases/tinycc/winapi-full-for-0.9.27.zip)
official full version of the WINAPI headers for tcc, 
or in the releases of [MinGW64](https://sourceforge.net/projects/mingw-w64/).

Most of the time, the ported headers should just work if you copy them inside the include/ folder,
however small modifications are sometimes needed to make them work with V.
