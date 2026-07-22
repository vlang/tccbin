# Build script for thirdparty-windows-amd64 tcc.exe / libtcc.dll / i386-win32-tcc.exe,
# recording how the fix for the DEF LIBRARY quoted/unsuffixed name bug
# (STATUS_DLL_NOT_FOUND on executables linked against .def files whose
# LIBRARY directive is quoted and has no .dll extension, e.g. OpenSSL's
# official Win64 installer .def files) was built.
#
# This branch had no prior build.ps1/build.sh of its own (unlike the linux
# branches, which have one recorded from vlib/v/../thirdparty/build_scripts/
# in the main vlang/v repo). This script only rebuilds the three binaries
# that actually contain the fix (tccpe.c is shared PE-target code linked
# into all three); it deliberately does NOT touch include/, lib/*.def, or
# any other file in this branch, since none of those are affected by the
# fix and several have vlang-specific patches on top of stock tinycc that
# must not be clobbered by a fresh checkout's copies.
#
# Requires git and a MinGW-w64 gcc on PATH. Built with:
#   gcc.exe (MinGW-W64 x86_64-ucrt-posix-seh, built by Brecht Sanders, r2) 16.1.0
#
# Usage: run from this directory (thirdparty/tcc in a vlang/v checkout, or
# any checkout of this branch).

$ErrorActionPreference = "Stop"

$TccBaseCommit = "9eef33993ade2d3b964d19b1081978ceae5d359d"
$PatchFile = Join-Path $PSScriptRoot "0001-tccpe-strip-quotes-and-default-.dll-extension-in-DEF.patch"
$OutDir = $PSScriptRoot

$Work = Join-Path ([System.IO.Path]::GetTempPath()) ("tcc-build-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $Work | Out-Null

Push-Location $Work
try {
    git clone git://repo.or.cz/tinycc.git tinycc
    Set-Location tinycc
    git checkout $TccBaseCommit
    git am $PatchFile

    Set-Location win32
    & cmd /c build-tcc.bat
    if ($LASTEXITCODE -ne 0) { throw "build-tcc.bat failed" }

    Copy-Item tcc.exe            (Join-Path $OutDir "tcc.exe") -Force
    Copy-Item libtcc.dll         (Join-Path $OutDir "libtcc.dll") -Force
    Copy-Item i386-win32-tcc.exe (Join-Path $OutDir "i386-win32-tcc.exe") -Force
}
finally {
    Pop-Location
    Remove-Item -Recurse -Force $Work
}

Write-Host "Done. Updated tcc.exe, libtcc.dll, i386-win32-tcc.exe in $OutDir"
