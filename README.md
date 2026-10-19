# thirdparty-linux-arm

This is a prebuilt tcc (https://repo.or.cz/tinycc.git) for 32-bit ARM Linux (armhf).
See build_source_hash.txt for its version.
See build_on_date.txt for its build date.
See build_version.txt for the original output of `tcc.exe --version` on the build machine.

build.sh is a copy of the script that built it,
https://github.com/vlang/v/blob/master/thirdparty/build_scripts/thirdparty-linux-arm_tcc.sh .

The build ran in a Debian 12 (bookworm) armhf userland (glibc 2.36, gcc 12.2), so `tcc.exe`
needs glibc 2.34 or newer. Its search paths are the arm-linux-gnueabihf ones of Debian, Ubuntu
and Raspberry Pi OS. Its libtcc1.a does not use `sdiv`/`udiv`, so it also runs on Cortex-A8/A9.

lib/libgc.a is bdwgc (see lib/libgc_build_source_hash.txt), built in the same userland by
lib/build_libgc.sh, a copy of
https://github.com/vlang/v/blob/master/thirdparty/build_scripts/thirdparty-linux-armv7_bdwgc.sh .
TinyCC's ARM linker needs it without unwind tables, in ARM (not Thumb) code and without fork
handlers; the script explains each flag.

Known limits of TinyCC on armhf: it cannot link V itself (the Thumb-2 C startup code calls libc
with a branch that cannot reach across V's text), so V's `make` builds V with the system C
compiler and uses this tcc for other programs. In programs that it links, calls into the
Thumb-2 functions of libc_nonshared.a (`atexit`, `pthread_atfork`) jump to address 0, and the
code it generates for `__thread` variables in an executable (local-exec TLS) reads the thread
pointer with an invalid `mrc` encoding (0xee1d0fe0) and dies with SIGILL.

# How to rebuild:
You *have* to be in V's main repo folder, with this branch checked out in thirdparty/tcc.
(in the next instruction, change e23dabed154a8495f3ac1ff3cc9d04fa1c207893 with the commit hash
from thirdparty/tcc/build_source_hash.txt).
Then do:
```sh
TCC_FOLDER=thirdparty/tcc TCC_COMMIT=e23dabed154a8495f3ac1ff3cc9d04fa1c207893 bash thirdparty/build_scripts/thirdparty-linux-arm_tcc.sh
CC=gcc TCC_FOLDER=thirdparty/tcc bash thirdparty/build_scripts/thirdparty-linux-armv7_bdwgc.sh
```
