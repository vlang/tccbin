# thirdparty-windows-amd64 (tcc64, tccwin64)

This repository contains a prebuilt [tcc compiler](https://repo.or.cz/tinycc.git),
whose source code is cut at commit
[d9d02c5](https://repo.or.cz/tinycc.git/commit/d9d02c56401e43be43760b63f7d82f771a7ed1f6),
from the mob branch, plus two patches (included here, and submitted
upstream to tinycc-devel): `0001-tccpe-...patch` and
`0002-win32-don-t-treat-DBG_PRINTEXCEPTION_C-...patch`.

Previously this branch was cut at the much older commit
[9eef339](https://repo.or.cz/tinycc.git/commit/9eef33993ade2d3b964d19b1081978ceae5d359d)
(20200605). See "Version bump notes" below for what changed and why.

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

## Version bump notes

This branch was bumped from tinycc commit 9eef339 (2020-06-05) to d9d02c5
(current mob at the time of this bump), together with a matching rebuild
of `lib/libgc.a`. Both were needed together - neither works with the
other's counterpart:

- **`lib/libgc.a` had to be rebuilt** because the old one was compiled
  against tinycc headers where `setjmp()` expanded via a hand-written
  `tinyc_getbp` assembly helper (in `lib/chkstk.S`). Current tinycc
  dropped that helper in favor of `__builtin_frame_address(0)` directly
  (upstream commit `30afb50e`), so the old `libgc.a` fails to link against
  the new `tcc.exe` with `unresolved reference to 'tinyc_getbp'`.
  `v-ae88ee5-tinycc-bdwgc.patch` (included here) makes the current BDWGC
  8.3.0 amalgamation (`thirdparty/libgc/gc.c` in the main v repo) compile
  under current tinycc; `build.ps1` applies it and rebuilds `libgc.a`.
- **Patch 0002 was needed** because, once linking succeeded, any program
  built with tcc's default `-bt`/`-bcheck` flags that calls
  `OutputDebugString` (Boehm GC does, in its Windows logging path) crashed
  at startup - tcc's own exception handler misclassified the benign
  `DBG_PRINTEXCEPTION_C` exception `OutputDebugString` raises internally
  as a fatal crash. Fixed in tinycc itself (also submitted upstream).
- **Patch 0001** (the DEF `LIBRARY` quoting/`.dll`-extension fix) is
  unrelated to the above - found separately, bundled into the same bump
  for convenience.
- The three small header patches (`vlang-header-compat.patch`:
  `gmtime_s`, `CONDITION_VARIABLE`, `__faststorefence`) are vlang-local
  additions unrelated to any of this - re-applied here because they were
  present in the old headers and are needed for building some third-party
  libraries (e.g. mbedtls) with tcc; they are not upstream tinycc's
  concern.
- `i386-win32-tcc.exe` is now built via `build-tcc.bat -x i386` (a
  separate cross-compile step) rather than automatically alongside the
  x86_64 build - a structural change in tinycc's own `build-tcc.bat`
  unrelated to this bump. Runtime archives were renamed accordingly
  (`libtcc1-32.a`/`libtcc1-64.a` → `libtcc1.a`/`i386-win32-libtcc1.a`).

Reproduce the whole thing with `build.ps1` (included here).
