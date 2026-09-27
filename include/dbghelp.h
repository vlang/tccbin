/*
 * Minimal compatibility shim for MSVC/Windows SDK's <dbghelp.h>.
 *
 * Same root cause as intrin.h in this directory: vlang's vc/v_win.c
 * bootstrap snapshot is always generated with `-cc msvc`, so it
 * unconditionally does `#include <dbghelp.h>` under `#ifdef _WIN32`. This
 * toolchain does not otherwise ship that header.
 *
 * No definitions are needed: vlang resolves the DbgHelp API
 * (SymInitialize, SymFromAddr, SymGetLineFromAddr64, ...) dynamically via
 * GetProcAddress at runtime, not through this header's static
 * declarations, so this file only needs to exist to satisfy the #include.
 */
#ifndef TCC_DBGHELP_H_SHIM
#define TCC_DBGHELP_H_SHIM
#endif
