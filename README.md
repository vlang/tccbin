# thirdparty-windows-amd64 (tcc64, tccwin64)

This repository contains a prebuilt [tcc compiler](https://repo.or.cz/tinycc.git),
whose source code is cut at commit
[d9d02c5](https://repo.or.cz/tinycc.git/commit/d9d02c56401e43be43760b63f7d82f771a7ed1f6),
from the mob branch, plus the numbered patches `0001` to `0017` in this directory
(applied to the tinycc sources by `build.ps1`; `0001` and `0002` were also submitted
upstream to tinycc-devel), and the Win32 GUI series described in the next section.

Previously this branch was cut at the much older commit
[9eef339](https://repo.or.cz/tinycc.git/commit/9eef33993ade2d3b964d19b1081978ceae5d359d)
(20200605). See "Version bump notes" below for what changed and why.

It is a ***minimalistic*** C compiler, that is just enough to be V's
backend. It is small and fast, although it does not produce optimised
executables. For that, use MSVC, GCC or CLANG instead.

## Target OS
The tcc build here produces ***64-bit executables***, compatiable with ***64-bit Windows***.  

## The Win32 GUI series

Commits `0018` onwards of this branch (not files to apply: they are in the tree) make a GUI
program build under this tcc, as it would under mingw-w64:

- `include/winapi`: `commctrl.h`, `commdlg.h`, `shlobj.h`, `shtypes.h`, `oleacc.h` and the
  headers they include (24 files, from mingw-w64 11.0.1), and changes to `rpcndr.h`
  (`small` is a macro only under `RC_INVOKED`), `winuser.h` (`SM_` and `EVENT_` constants),
  `winnt.h`, `objbase.h`, `shellapi.h`, `winapifamily.h` and `_mingw.h`.
- `lib/*.def`: the functions that the headers declare and that the Windows DLL exports, for
  `gdi32`, `kernel32`, `shell32`, `user32` and `advapi32`. The rule is the export table of the
  DLL, intersected with the export list of mingw-w64's import library and with the names the
  headers mention. mingw's import libraries alone are not enough: they carry intrinsic stubs
  (`_BitScanForward`, `_Interlocked*`) that no DLL exports.
- `lib/uuid.c`: the GUIDs of those headers, built into `lib/libuuid.a` by `build.ps1`. Programs
  that take the address of an `IID_` or `CLSID_` link with `-luuid` as under mingw-w64
  (`#flag windows -luuid` in V), or define `INITGUID` before the includes in one file.
- `tests/gui_additions.v` touches each addition: `v -cc tcc tests/gui_additions.v`.

A rebuild with `build.ps1` keeps the series: `series-files.txt` lists the header files it
sets aside before copying tinycc's `include/` and puts back after; `series/<dll>.add` and
`series/<dll>.drop` are merged into the `kernel32.def` and `shell32.def` that `build.ps1`
copies from tinycc (the other three `.def` files are not copied, so they stay as they are);
`libuuid.a` is built from `lib/uuid.c`. When tinycc changes one of the listed headers, the
branch's version wins until the list is edited.

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
- **Patch 0017** extends that allowlist: `DBG_PRINTEXCEPTION_WIDE_C`
  (`OutputDebugStringW`), `DBG_RIPEXCEPTION`, `MS_VC_EXCEPTION`
  (`SetThreadName`), and Microsoft C++ EH (`0xE06D7363`). Same default
  still treats access violation and other real faults as fatal. Required
  after 0002; rebuild `bt-exe.o` then relink `v.exe`.
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

## IOCP completion imports

`lib/kernel32.def` exports the Windows Vista APIs `GetQueuedCompletionStatusEx`
and `SetFileCompletionNotificationModes`. Existing distributions only need the
updated definition file; rebuilding `tcc.exe` is unnecessary. Patch 0010 keeps
these exports when `build.ps1` rebuilds the distribution. The optional
`OVERLAPPED_ENTRY` type and function declarations can still be supplied by the
calling program when its bundled Windows headers do not declare them.

Since `build.ps1` copies tinycc's patched `win32/lib/kernel32.def` over
`lib/kernel32.def`, every export the bundle needs has to come from a patch.
Patches 0012-0015 add the Vista-era file, tick and SRW lock exports, and patch
0016 carries the exports that were previously hand-added only to the bundled
copy (`CreateHardLinkW`, `GetFinalPathNameByHandleW`, `GetNativeSystemInfo`,
`K32GetProcessMemoryInfo`, the condition-variable functions, and others). The
committed `lib/kernel32.def` is the file those patches produce.
