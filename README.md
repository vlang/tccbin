# thirdparty-linuxmusl-aarch64

This is a prebuilt tcc (https://repo.or.cz/tinycc.git), for aarch64 Linux distributions that use
musl, like Alpine.
See build_source_hash.txt for its version.
See build_on_date.txt for its build date.
See build_version.txt for the original output of `tcc.exe --version` on the build machine.

build.sh is a copy of the script that built it,
https://github.com/vlang/v/blob/master/thirdparty/build_scripts/thirdparty-linuxmusl-aarch64_tcc.sh .

The build ran in an Alpine 3.24 aarch64 userland (musl 1.2.6, gcc 15.2). `tcc.exe` is linked
statically, so it does not depend on the installed musl version. The script also makes `wchar_t`
`unsigned int` in lib/tcc/include/stddef.h, matching musl's aarch64 headers.

TinyCC e23dabed includes the upstream fix 128e7893 for the layout of thread-local data. The
bundles built from earlier commits put `.tdata` after `.bss` in the same segment, so a
`__thread` variable with a non-zero initializer started at 0 in every thread, and its initial
value overwrote the start of `.bss`.

lib/libgc.a is kept from the previous bundle; lib/libgc_build_cmd.txt shows how it was built.
On musl, V links the system libgc instead (`apk add gc-dev`).

# How to rebuild:
You *have* to be in V's main repo folder, with this branch checked out in thirdparty/tcc.
(in the next instruction, change e23dabed154a8495f3ac1ff3cc9d04fa1c207893 with the commit hash
from thirdparty/tcc/build_source_hash.txt).
Then do:
```sh
TCC_FOLDER=thirdparty/tcc TCC_COMMIT=e23dabed154a8495f3ac1ff3cc9d04fa1c207893 bash thirdparty/build_scripts/thirdparty-linuxmusl-aarch64_tcc.sh
```
