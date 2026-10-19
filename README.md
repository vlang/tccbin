# thirdparty-linux-aarch64

This is a prebuilt tcc (https://repo.or.cz/tinycc.git).
See build_source_hash.txt for its version.
See build_on_date.txt for its build date.
See build_version.txt for the original output of `tcc.exe --version` on the build machine.

build.sh is a copy of the script that built it,
https://github.com/vlang/v/blob/master/thirdparty/build_scripts/thirdparty-linux-aarch64_tcc.sh .

The build ran in a Debian 12 (bookworm) arm64 userland (glibc 2.36, gcc 12.2), so `tcc.exe`
needs glibc 2.34 or newer. On an older system, V's `make` uses the newest earlier commit of this
branch whose `tcc.exe` still works there (see cmd/tools/select_linux_tcc.sh in the V repo).

TinyCC e23dabed includes the upstream fix 128e7893 for the layout of thread-local data. The
bundles built from earlier commits put `.tdata` after `.bss` in the same segment, so a
`__thread` variable with a non-zero initializer started at 0 in every thread, and its initial
value overwrote the start of `.bss`.

lib/libgc.a is kept from the previous bundle; lib/libgc_build_cmd.txt shows how it was built.

# How to rebuild:
You *have* to be in V's main repo folder, with this branch checked out in thirdparty/tcc.
(in the next instruction, change e23dabed154a8495f3ac1ff3cc9d04fa1c207893 with the commit hash
from thirdparty/tcc/build_source_hash.txt).
Then do:
```sh
TCC_FOLDER=thirdparty/tcc TCC_COMMIT=e23dabed154a8495f3ac1ff3cc9d04fa1c207893 bash thirdparty/build_scripts/thirdparty-linux-aarch64_tcc.sh
```
