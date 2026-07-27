# Build script for thirdparty-windows-amd64: bumps the bundled tcc from the
# 2020-era snapshot (commit 9eef339) this branch was originally cut from, up
# to current tinycc mob, plus a matching rebuild of libgc.a.
#
# This is a bigger, separate change from the fix/def-library-quoted-name
# branch (PR #66), which keeps the old tinycc base and only patches the one
# DEF-parsing bug. That fix alone doesn't need a new libgc.a (the existing
# one already matches the old tinycc it was built against). This script is
# for the full version bump, which *does* need a matching libgc.a rebuild -
# see the two patches applied below for why.
#
# Run from the root of a vlang/v checkout (this file lives in
# thirdparty/tcc/ within it). Requires git and a MinGW-w64 gcc on PATH.
# Built with:
#   gcc.exe (MinGW-W64 x86_64-ucrt-posix-seh, built by Brecht Sanders, r2) 16.1.0

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
if (-not (Test-Path (Join-Path $RepoRoot "vlib\v\compiler_errors_test.v"))) {
    throw "run this from a vlang/v checkout (thirdparty/tcc/build.ps1 relative to repo root)"
}

$TccBaseCommit = "d9d02c56401e43be43760b63f7d82f771a7ed1f6"
$TccPatch1 = Join-Path $PSScriptRoot "0001-tccpe-strip-quotes-and-default-.dll-extension-in-DEF.patch"
$TccPatch2 = Join-Path $PSScriptRoot "0002-win32-don-t-treat-DBG_PRINTEXCEPTION_C-as-a-fatal-cr.patch"
$TccPatch3 = Join-Path $PSScriptRoot "0003-win32-declare-CreateSymbolicLink.patch"
$TccPatch4 = Join-Path $PSScriptRoot "0004-win32-declare-WSAConnectBy-family.patch"
$TccPatch5 = Join-Path $PSScriptRoot "0005-win32-declare-InetNtop-InetPton-family.patch"
$TccPatch6 = Join-Path $PSScriptRoot "0006-win32-declare-shell-drag-drop-family.patch"
$TccPatch7 = Join-Path $PSScriptRoot "0007-win32-declare-secure-narrow-stdio.patch"
$TccPatch8 = Join-Path $PSScriptRoot "0008-win32-fix-exp2-range-reduction.patch"
$TccPatch9 = Join-Path $PSScriptRoot "0009-win32-declare-CancelIoEx.patch"
$GcPatch = Join-Path $PSScriptRoot "v-ae88ee5-tinycc-bdwgc.patch"
$OutDir = $PSScriptRoot

$Work = Join-Path ([System.IO.Path]::GetTempPath()) ("tccbin-bump-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $Work | Out-Null

Push-Location $Work
try {
    # ---- tcc.exe / libtcc.dll / i386-win32-tcc.exe ----
    git clone git://repo.or.cz/tinycc.git tinycc
    Set-Location tinycc
    git checkout $TccBaseCommit
    if ($LASTEXITCODE -ne 0) { throw "git checkout $TccBaseCommit failed" }
    git apply $TccPatch1
    if ($LASTEXITCODE -ne 0) { throw "$TccPatch1 failed to apply" }
    git apply $TccPatch2
    if ($LASTEXITCODE -ne 0) { throw "$TccPatch2 failed to apply" }
    git apply $TccPatch3
    if ($LASTEXITCODE -ne 0) { throw "$TccPatch3 failed to apply" }
    git apply $TccPatch4
    if ($LASTEXITCODE -ne 0) { throw "$TccPatch4 failed to apply" }
    git apply $TccPatch5
    if ($LASTEXITCODE -ne 0) { throw "$TccPatch5 failed to apply" }
    git apply $TccPatch6
    if ($LASTEXITCODE -ne 0) { throw "$TccPatch6 failed to apply" }
    git apply $TccPatch7
    if ($LASTEXITCODE -ne 0) { throw "$TccPatch7 failed to apply" }
    git apply $TccPatch8
    if ($LASTEXITCODE -ne 0) { throw "$TccPatch8 failed to apply" }
    git apply $TccPatch9
    if ($LASTEXITCODE -ne 0) { throw "$TccPatch9 failed to apply" }

    Set-Location win32
    & .\build-tcc.bat -clean
    & .\build-tcc.bat
    if ($LASTEXITCODE -ne 0) { throw "build-tcc.bat (x86_64) failed" }
    & .\build-tcc.bat -x i386
    if ($LASTEXITCODE -ne 0) { throw "build-tcc.bat -x i386 failed" }

    Copy-Item tcc.exe                (Join-Path $OutDir "tcc.exe") -Force
    Copy-Item libtcc.dll             (Join-Path $OutDir "libtcc.dll") -Force
    Copy-Item i386-win32-tcc.exe     (Join-Path $OutDir "i386-win32-tcc.exe") -Force
    Copy-Item lib\libtcc1.a           (Join-Path $OutDir "lib\libtcc1.a") -Force
    Copy-Item lib\i386-win32-libtcc1.a (Join-Path $OutDir "lib\i386-win32-libtcc1.a") -Force
    Copy-Item lib\shell32.def          (Join-Path $OutDir "lib\shell32.def") -Force
    foreach ($f in @("bcheck.o","bt-exe.o","bt-log.o","bt-dll.o","runmain.o",
                      "i386-win32-bcheck.o","i386-win32-bt-exe.o","i386-win32-bt-log.o",
                      "i386-win32-bt-dll.o","i386-win32-runmain.o",
                      "chkstk.S","crt1.c","crt1w.c","dllcrt1.c","dllmain.c",
                      "wincrt1.c","wincrt1w.c","winex.c")) {
        Copy-Item (Join-Path "lib" $f) (Join-Path $OutDir "lib\$f") -Force
    }
    Copy-Item libtcc\libtcc.def (Join-Path $OutDir "libtcc\libtcc.def") -Force
    Copy-Item libtcc\libtcc.h   (Join-Path $OutDir "libtcc\libtcc.h") -Force
    Copy-Item -Recurse -Force include\* (Join-Path $OutDir "include")

    Pop-Location
    Push-Location $Work

    # ---- vlang-local header compat patches ----
    # Not upstream tinycc's concern - these exist to let TCC compile
    # third-party libs like mbedtls (gmtime_s, CONDITION_VARIABLE,
    # __faststorefence). Applied against the just-copied output headers,
    # not against stock tinycc's tree.
    Push-Location $OutDir
    git apply (Join-Path $OutDir "vlang-header-compat.patch")
    if ($LASTEXITCODE -ne 0) { throw "vlang-header-compat.patch failed to apply - upstream tinycc headers likely shifted; update the patch" }
    Pop-Location

    # ---- libgc.a ----
    $GcSrc = Join-Path $RepoRoot "thirdparty\libgc\gc.c"
    $GcWork = Join-Path $Work "gc_patch"
    New-Item -ItemType Directory -Path (Join-Path $GcWork "thirdparty\libgc") -Force | Out-Null
    Copy-Item $GcSrc (Join-Path $GcWork "thirdparty\libgc\gc.c")
    Set-Location $GcWork
    git init -q
    git apply $GcPatch
    if ($LASTEXITCODE -ne 0) { throw "$GcPatch failed to apply" }

    $tcc = Join-Path $OutDir "tcc.exe"
    & $tcc thirdparty\libgc\gc.c -DGC_NOT_DLL -DGC_WIN32_THREADS -DGC_THREADS -DGC_BUILTIN_ATOMIC `
        -I (Join-Path $RepoRoot "thirdparty\libgc\include") -c -o gc.o
    if ($LASTEXITCODE -ne 0) { throw "gc.c compile failed" }
    & $tcc -ar (Join-Path $OutDir "lib\libgc.a") gc.o
    if ($LASTEXITCODE -ne 0) { throw "libgc.a archive failed" }
}
finally {
    Pop-Location
    Remove-Item -Recurse -Force $Work
}

date                                   > (Join-Path $OutDir "lib\libgc_build_on_date.txt")
$TccBaseCommit                         > (Join-Path $OutDir "lib\libgc_build_tcc_commit.txt")
(Get-FileHash (Join-Path $OutDir "tcc.exe") -Algorithm SHA256).Hash > (Join-Path $OutDir "lib\libgc_build_tcc_exe_sha256.txt")

Write-Host "Done. Updated tcc.exe, libtcc.dll, i386-win32-tcc.exe, include/, lib/ in $OutDir"
