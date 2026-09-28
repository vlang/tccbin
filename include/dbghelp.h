/**
 * This file has no copyright assigned and is placed in the Public Domain.
 * This file is part of the mingw-w64 runtime package.
 * No warranty is given; refer to the file DISCLAIMER.PD within this package.
 */
/*
 * Unlike include/intrin.h in this same directory (an empty stub with zero
 * dependencies), this is the real mingw-w64 header, and it is NOT
 * include-order-independent: its dependency psdk_inc/_dbg_LOAD_IMAGE.h uses
 * PSTR/PUCHAR/HANDLE/etc. without defining or including them itself - they
 * must already come from <windows.h>. Including this header before
 * <windows.h> fails to preprocess. This matches vc/v_win.c's actual order
 * (<windows.h>, then <intrin.h>, then <dbghelp.h>), which this bundle's
 * bootstrap depends on and has been verified to build; any other consumer
 * must include <windows.h> first too.
 */
#ifndef _DBGHELP_
#define _DBGHELP_

#include <_mingw_unicode.h>

#ifdef _WIN64
#ifndef _IMAGEHLP64
#define _IMAGEHLP64
#endif
#endif

#include <psdk_inc/_dbg_LOAD_IMAGE.h>
#include <psdk_inc/_dbg_common.h>

#endif
