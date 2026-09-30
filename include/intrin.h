/*
 * Minimal compatibility shim for MSVC's <intrin.h>.
 *
 * vlang's vc/v_win.c bootstrap snapshot is always generated with `-cc msvc`
 * (see vlang/v's .github/workflows/gen_vc_ci.yml), which makes its cgen
 * emit an unconditional `#include <intrin.h>` under `#ifdef _WIN32` (see
 * vlang/v's vlib/v/gen/c/cleanc.v, the `g.ccompiler == 'msvc'` branch).
 * This toolchain does not otherwise ship that header, so building
 * vc/v_win.c directly with the bundled tcc fails before reaching any real
 * code.
 *
 * This is an empty stub, not a ported real intrin.h, because this
 * toolchain's own include/_mingw.h unconditionally does
 * `#define __INTRIN_H_` (see its line ~146), which is the real
 * mingw-w64 intrin.h's own header guard. Since <windows.h> (included
 * immediately before this header in vc/v_win.c) pulls in _mingw.h first,
 * a real ported intrin.h's body would already be skipped by its own
 * guard in that include order - it would silently do nothing, while
 * still being unable to preprocess standalone, since this bundle does
 * not ship intrin.h's own dependencies (crtdefs.h,
 * psdk_inc/intrin-impl.h). An empty stub is the honest version of the
 * same no-op, without the missing-dependency failure in any other
 * include order.
 *
 * No definitions are needed here regardless: every call site for the
 * handful of MSVC intrinsics vlang's cgen can emit (_umul128, _udiv128,
 * _addcarry_u64, _BitScanForward, _BitScanForward64) is wrapped in
 * `#if defined(_MSC_VER)` at the C level, so under TCC those branches
 * never compile in the first place - portable fallbacks run instead.
 * include/winapi/winnt.h (pulled in by <windows.h>) already provides
 * working `_BitScanForward`, `_BitScanForward64` and `__faststorefence`
 * for this toolchain (see vlang-header-compat.patch).
 */
#ifndef TCC_INTRIN_H_SHIM
#define TCC_INTRIN_H_SHIM
#endif
