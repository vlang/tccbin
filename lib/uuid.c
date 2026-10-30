/*
 * uuid.c: the GUIDs that the headers of include/winapi declare, defined once,
 * as mingw-w64's libuuid.a does. A program that takes the address of an IID_
 * or CLSID_ (AccessibleObjectFromWindow(..., &IID_IAccessible, ...)) links
 * without defining INITGUID itself.
 *
 * build.ps1 compiles this file and adds the object to libtcc1.a, which tcc
 * links into every program, so no -luuid is needed either.
 */
#define INITGUID
#include <windows.h>
#include <shellapi.h>
#include <ole2.h>
#include <objbase.h>
#include <objidl.h>
#include <oleauto.h>
#include <servprov.h>
#include <urlmon.h>
#include <audioclient.h>
#include <mmdeviceapi.h>
#include <commdlg.h>
#include <comcat.h>
#include <docobj.h>
#include <exdisp.h>
#include <isguids.h>
#include <objectarray.h>
#include <ocidl.h>
#include <oleacc.h>
#include <propsys.h>
#include <propkeydef.h>
#include <shldisp.h>
#include <shlguid.h>
#include <shlobj.h>
#include <structuredquerycondition.h>
