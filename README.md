# tccbin-windows-amd64 (tcc64, tccwin64)

It is based on prebuilt [tcc compiler](https://repo.or.cz/tinycc.git) imported from https://github.com/vlang/tccbin_win, whose source code is cut at commit [9eef339](https://repo.or.cz/tinycc.git/commit/9eef33993ade2d3b964d19b1081978ceae5d359d) (20200605) from mob branch. It is intended to be a ***minimalism*** version just enough to be V's backend, as lightweight is one of the beauties of tcc.

## Target OS
As V's backend it produces ***64-bit executables*** compatiable with ***64-bit Windows***.  

## What if V reports lack of C header files in use?
In this case please create a PR to help us improve it. Please try finding lacked header files in [this](http://download.savannah.gnu.org/releases/tinycc/winapi-full-for-0.9.27.zip) official full version of tcc, or releases of [MinGW64](https://sourceforge.net/projects/mingw-w64/). For most cases the ported headers should just work nicely. However, small modification is sometimes needed to make them work with V.
