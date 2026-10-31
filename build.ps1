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
$TccPatch10 = Join-Path $PSScriptRoot "0010-win32-export-batched-iocp.patch"
$TccPatch11 = Join-Path $PSScriptRoot "0011-win32-include-synchapi-from-windows-h.patch"
$TccPatch12 = Join-Path $PSScriptRoot "0012-win32-declare-and-export-GetTickCount64.patch"
$TccPatch13 = Join-Path $PSScriptRoot "0013-win32-export-GetFileSizeEx-and-TryAcquireSRWLockExclusive.patch"
$TccPatch14 = Join-Path $PSScriptRoot "0014-win32-declare-and-export-GetFileInformationByHandleEx.patch"
$TccPatch15 = Join-Path $PSScriptRoot "0015-win32-export-SRW-lock-functions.patch"
$TccPatch16 = Join-Path $PSScriptRoot "0016-win32-export-bundled-kernel32-functions.patch"
$TccPatch17 = Join-Path $PSScriptRoot "0017-win32-ignore-remaining-benign-debug-exceptions.patch"
$GcPatch = Join-Path $PSScriptRoot "v-ae88ee5-tinycc-bdwgc.patch"
$OutDir = $PSScriptRoot

# ---- the Win32 GUI series (patches 0018 onwards of this branch) ----
# The series adds headers, replaces a few, and extends the export lists.
# build.ps1 copies tinycc's include/ and kernel32.def and shell32.def over the
# bundled ones, so the series keeps itself through a rebuild like this:
#   - series-files.txt names every header file the series adds or changes; they are set
#     aside before the copy and put back after it (so a rebuild does not take them away);
#   - series/<dll>.add and series/<dll>.drop are merged into the copied .def: names to add
#     (sorted into place) and names that no Windows DLL exports (dropped);
#   - lib\uuid.c is built into lib\libuuid.a, the GUIDs of the headers (-luuid).
# gdi32.def, user32.def and advapi32.def are not copied from tinycc, so they stay as committed.
function Merge-SeriesDef([string]$Path, [string]$AddFile, [string]$DropFile) {
    $drop = @{}
    foreach ($n in (Get-Content $DropFile)) { if ($n.Trim()) { $drop[$n.Trim()] = $true } }
    $head = New-Object System.Collections.Generic.List[string]
    $names = New-Object System.Collections.Generic.List[string]
    foreach ($l in (Get-Content $Path)) {
        $t = $l.Trim()
        if ($t -eq '' -or $t -eq 'EXPORTS' -or $t.StartsWith('LIBRARY')) {
            if ($t -eq '' -and $names.Count -gt 0) { continue }
            $head.Add($l)
        } elseif (-not $drop.ContainsKey($t)) { $names.Add($t) }
    }
    $have = @{}
    foreach ($n in $names) { $have[$n] = $true }
    $pend = New-Object System.Collections.Generic.List[string]
    foreach ($n in (Get-Content $AddFile)) { $t = $n.Trim(); if ($t -and -not $have.ContainsKey($t)) { $pend.Add($t) } }
    $pend.Sort([System.StringComparer]::Ordinal)
    $out = New-Object System.Collections.Generic.List[string]
    $i = 0
    foreach ($e in $names) {
        while ($i -lt $pend.Count -and [string]::CompareOrdinal($pend[$i], $e) -lt 0) { $out.Add($pend[$i]); $i++ }
        $out.Add($e)
    }
    while ($i -lt $pend.Count) { $out.Add($pend[$i]); $i++ }
    [System.IO.File]::WriteAllText($Path, ((@($head) + @($out)) -join "`n") + "`n")
}

$Work = Join-Path ([System.IO.Path]::GetTempPath()) ("tccbin-bump-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $Work | Out-Null

Push-Location $Work
try {
    # ---- tcc.exe / libtcc.dll / i386-win32-tcc.exe ----
    git clone https://repo.or.cz/tinycc.git tinycc
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
    git apply $TccPatch10
    if ($LASTEXITCODE -ne 0) { throw "$TccPatch10 failed to apply" }
    git apply $TccPatch11
    if ($LASTEXITCODE -ne 0) { throw "$TccPatch11 failed to apply" }
    git apply $TccPatch12
    if ($LASTEXITCODE -ne 0) { throw "$TccPatch12 failed to apply" }
    git apply $TccPatch13
    if ($LASTEXITCODE -ne 0) { throw "$TccPatch13 failed to apply" }
    git apply $TccPatch14
    if ($LASTEXITCODE -ne 0) { throw "$TccPatch14 failed to apply" }
    git apply $TccPatch15
    if ($LASTEXITCODE -ne 0) { throw "$TccPatch15 failed to apply" }
    git apply $TccPatch16
    if ($LASTEXITCODE -ne 0) { throw "$TccPatch16 failed to apply" }
    git apply $TccPatch17
    if ($LASTEXITCODE -ne 0) { throw "$TccPatch17 failed to apply" }

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
    Copy-Item lib\kernel32.def         (Join-Path $OutDir "lib\kernel32.def") -Force
    foreach ($dll in @("kernel32","shell32")) {
        Merge-SeriesDef (Join-Path $OutDir "lib\$dll.def") (Join-Path $OutDir "series\$dll.add") (Join-Path $OutDir "series\$dll.drop")
    }
    foreach ($f in @("bcheck.o","bt-exe.o","bt-log.o","bt-dll.o","runmain.o",
                      "i386-win32-bcheck.o","i386-win32-bt-exe.o","i386-win32-bt-log.o",
                      "i386-win32-bt-dll.o","i386-win32-runmain.o",
                      "chkstk.S","crt1.c","crt1w.c","dllcrt1.c","dllmain.c",
                      "wincrt1.c","wincrt1w.c","winex.c")) {
        Copy-Item (Join-Path "lib" $f) (Join-Path $OutDir "lib\$f") -Force
    }
    Copy-Item libtcc\libtcc.def (Join-Path $OutDir "libtcc\libtcc.def") -Force
    Copy-Item libtcc\libtcc.h   (Join-Path $OutDir "libtcc\libtcc.h") -Force
    # Set the series' header files aside, copy tinycc's include/, put them back.
    $SeriesFiles = @(Get-Content (Join-Path $OutDir "series-files.txt") | Where-Object { $_.Trim() })
    $SeriesStash = Join-Path $Work "series-stash"
    foreach ($f in $SeriesFiles) {
        $src = Join-Path $OutDir $f
        if (Test-Path $src) {
            $dst = Join-Path $SeriesStash $f
            New-Item -ItemType Directory -Path (Split-Path $dst) -Force | Out-Null
            Copy-Item $src $dst -Force
        }
    }
    Copy-Item -Recurse -Force include\* (Join-Path $OutDir "include")
    foreach ($f in $SeriesFiles) {
        $stashed = Join-Path $SeriesStash $f
        if (Test-Path $stashed) { Copy-Item $stashed (Join-Path $OutDir $f) -Force }
    }

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

    # ---- libuuid.a: the GUIDs of the headers, as mingw-w64's libuuid.a (link with -luuid) ----
    Set-Location $Work
    & $tcc -c (Join-Path $OutDir "lib\uuid.c") -I (Join-Path $OutDir "include") -I (Join-Path $OutDir "include\winapi") -o uuid.o
    if ($LASTEXITCODE -ne 0) { throw "uuid.c compile failed" }
    & $tcc -ar (Join-Path $OutDir "lib\libuuid.a") uuid.o
    if ($LASTEXITCODE -ne 0) { throw "libuuid.a archive failed" }
}
finally {
    Pop-Location
    Remove-Item -Recurse -Force $Work
}

date                                   > (Join-Path $OutDir "lib\libgc_build_on_date.txt")
$TccBaseCommit                         > (Join-Path $OutDir "lib\libgc_build_tcc_commit.txt")
(Get-FileHash (Join-Path $OutDir "tcc.exe") -Algorithm SHA256).Hash > (Join-Path $OutDir "lib\libgc_build_tcc_exe_sha256.txt")

Write-Host "Done. Updated tcc.exe, libtcc.dll, i386-win32-tcc.exe, include/, lib/ (with libuuid.a) in $OutDir"
