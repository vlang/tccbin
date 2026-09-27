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
 * No definitions are needed here:
 *  - Every call site for the handful of MSVC intrinsics vlang's cgen can
 *    emit (_umul128, _udiv128, _addcarry_u64, _BitScanForward,
 *    _BitScanForward64) is wrapped in `#if defined(_MSC_VER)` at the C
 *    level, so under TCC those branches never compile in the first place -
 *    portable fallbacks run instead.
 *  - <windows.h>, normally included immediately before this header,
 *    already pulls in include/winapi/winnt.h, which already provides
 *    working `_BitScanForward`, `_BitScanForward64` and `__faststorefence`
 *    for this toolchain (see vlang-header-compat.patch). Redeclaring them
 *    here causes a "redefinition" compile error.
 */
#ifndef TCC_INTRIN_H_SHIM
#define TCC_INTRIN_H_SHIM
#endif
