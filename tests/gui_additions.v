// Brief 15: touches each addition of the Win32 header and import-list patch series, so that
// the program compiles and links under V's bundled tcc on Windows (`v -cc tcc gui_additions.v`).
// It is meant to be compiled, and run only as far as `main` gets (nothing here opens a window).
module main

#include <windows.h>
#include <commctrl.h>
#include <commdlg.h>
#include <shellapi.h>
#include <shlobj.h>
#include <oleacc.h>

#flag windows -lcomctl32
#flag windows -lcomdlg32
#flag windows -luuid
#flag windows -lshell32
#flag windows -lgdi32
#flag windows -loleacc
#flag windows -lole32

// A struct with a field named `small`: rpcndr.h used to `#define small char`.
struct Sizes {
	small int
	big   int
}

@[typedef]
struct C.GUID {}

@[typedef]
struct C.INITCOMMONCONTROLSEX {
mut:
	dwSize u32
	dwICC  u32
}

@[typedef]
struct C.TOOLINFOW {
mut:
	cbSize u32
}

@[typedef]
struct C.OPENFILENAMEW {
mut:
	lStructSize u32
}

@[typedef]
struct C.BROWSEINFOW {}

@[typedef]
struct C.NOTIFYICONDATAW {
mut:
	cbSize u32
	hWnd   voidptr
}

@[typedef]
struct C.ACTCTXW {
mut:
	cbSize u32
}

@[typedef]
struct C.IAccessible {
	lpVtbl &C.IAccessibleVtbl
}

@[typedef]
struct C.IAccessibleVtbl {
	get_accChildCount fn (&C.IAccessible, &i32) int
	Release           fn (&C.IAccessible) u32
}

fn C.InitCommonControlsEx(&C.INITCOMMONCONTROLSEX) bool
fn C.GetOpenFileNameW(&C.OPENFILENAMEW) bool
fn C.SHBrowseForFolderW(&C.BROWSEINFOW) voidptr
fn C.SHGetPathFromIDListW(voidptr, &u16) bool
fn C.Shell_NotifyIconW(u32, &C.NOTIFYICONDATAW) bool
fn C.CreateActCtxW(&C.ACTCTXW) voidptr
fn C.ActivateActCtx(voidptr, &u64) bool
fn C.ReleaseActCtx(voidptr)
fn C.GetGlyphIndicesW(voidptr, &u16, int, &u16, u32) u32
fn C.AddFontResourceExW(&u16, u32, voidptr) int
fn C.AccessibleObjectFromWindow(voidptr, u32, voidptr, &voidptr) int
fn C.GetSystemMetrics(int) int

// touch_tooltip and touch_trackbar use the window classes of commctrl.h.
fn touch_common_controls() {
	mut icc := C.INITCOMMONCONTROLSEX{
		dwSize: sizeof(C.INITCOMMONCONTROLSEX)
		dwICC:  u32(C.ICC_BAR_CLASSES | C.ICC_WIN95_CLASSES)
	}
	C.InitCommonControlsEx(&icc)
	_ := C.TOOLTIPS_CLASSW
	_ := C.TRACKBAR_CLASSW
	_ := C.TTM_ADDTOOLW
	_ := C.TBM_SETRANGE
	mut tool := C.TOOLINFOW{}
	tool.cbSize = sizeof(C.TOOLINFOW)
	_ = tool
}

// touch_file_dialog is compiled, not called.
fn touch_file_dialog() bool {
	mut ofn := C.OPENFILENAMEW{}
	ofn.lStructSize = sizeof(C.OPENFILENAMEW)
	return C.GetOpenFileNameW(&ofn)
}

fn touch_folder_dialog() string {
	mut bi := C.BROWSEINFOW{}
	pidl := C.SHBrowseForFolderW(&bi)
	mut path := [260]u16{}
	if pidl != unsafe { nil } && C.SHGetPathFromIDListW(pidl, &path[0]) {
		return unsafe { string_from_wide(&path[0]) }
	}
	return ''
}

// touch_accessible calls a method through the vtable of an IAccessible.
fn touch_accessible(hwnd voidptr) {
	mut acc := unsafe { &C.IAccessible(nil) }
	if C.AccessibleObjectFromWindow(hwnd, u32(C.OBJID_CLIENT), voidptr(&C.IID_IAccessible), &voidptr(&acc)) == 0 {
		mut count := i32(0)
		acc.lpVtbl.get_accChildCount(acc, &count)
		acc.lpVtbl.Release(acc)
	}
}

fn touch_tray_icon(hwnd voidptr) {
	mut nid := C.NOTIFYICONDATAW{}
	nid.cbSize = sizeof(C.NOTIFYICONDATAW)
	nid.hWnd = hwnd
	C.Shell_NotifyIconW(C.NIM_ADD, &nid)
	C.Shell_NotifyIconW(C.NIM_DELETE, &nid)
}

fn touch_activation_context() {
	mut ctx := C.ACTCTXW{}
	ctx.cbSize = sizeof(C.ACTCTXW)
	handle := C.CreateActCtxW(&ctx)
	mut cookie := u64(0)
	if C.ActivateActCtx(handle, &cookie) {
		C.ReleaseActCtx(handle)
	}
}

fn touch_glyph_check(hdc voidptr) {
	text := [u16(`A`), 0]
	mut glyphs := [u16(0), 0]
	unsafe {
		C.GetGlyphIndicesW(hdc, &text[0], 1, &glyphs[0], u32(C.GGI_MARK_NONEXISTING_GLYPHS))
	}
	unsafe {
		C.AddFontResourceExW(&text[0], u32(C.FR_PRIVATE), nil)
	}
}

fn main() {
	s := Sizes{
		small: 1
		big:   2
	}
	// SM_CXPADDEDBORDER (92) and the SM_ metrics count are in winuser.h now.
	assert C.SM_CXPADDEDBORDER == 92
	assert C.EVENT_OBJECT_INVOKED == 0x8013
	_ := C.GetSystemMetrics(C.SM_CXPADDEDBORDER)
	assert s.small + s.big == 3
	_ := touch_common_controls
	_ := touch_file_dialog
	_ := touch_folder_dialog
	_ := touch_accessible
	_ := touch_tray_icon
	_ := touch_activation_context
	_ := touch_glyph_check
	println('ok')
}
