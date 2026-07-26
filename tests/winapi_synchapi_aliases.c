#define WINVER 0x0600
#define _WIN32_WINNT 0x0600
#ifdef TCCBIN_SYNCHAPI_REVERSE_INCLUDE_ORDER
#include <excpt.h>
#include <stdarg.h>
#include <windef.h>
#define WINBASEAPI DECLSPEC_IMPORT
typedef struct _SECURITY_ATTRIBUTES *LPSECURITY_ATTRIBUTES;
typedef PRTL_CRITICAL_SECTION PCRITICAL_SECTION;
typedef PRTL_CRITICAL_SECTION LPCRITICAL_SECTION;
#include <synchapi.h>
#include <winbase.h>
#else
#include <windows.h>
#include <synchapi.h>
#endif

#ifndef OpenEvent
#error OpenEvent alias is missing
#endif
#ifndef CreateMutex
#error CreateMutex alias is missing
#endif
#ifndef CreateEvent
#error CreateEvent alias is missing
#endif

#ifdef UNICODE
typedef HANDLE (WINAPI *open_event_alias_fn)(DWORD,WINBOOL,LPCWSTR);
typedef HANDLE (WINAPI *create_mutex_alias_fn)(LPSECURITY_ATTRIBUTES,WINBOOL,LPCWSTR);
typedef HANDLE (WINAPI *create_event_alias_fn)(LPSECURITY_ATTRIBUTES,WINBOOL,WINBOOL,LPCWSTR);
#define EXPECTED_OPEN_EVENT OpenEventW
#define EXPECTED_CREATE_MUTEX CreateMutexW
#define EXPECTED_CREATE_EVENT CreateEventW
#else
typedef HANDLE (WINAPI *open_event_alias_fn)(DWORD,WINBOOL,LPCSTR);
typedef HANDLE (WINAPI *create_mutex_alias_fn)(LPSECURITY_ATTRIBUTES,WINBOOL,LPCSTR);
typedef HANDLE (WINAPI *create_event_alias_fn)(LPSECURITY_ATTRIBUTES,WINBOOL,WINBOOL,LPCSTR);
#define EXPECTED_OPEN_EVENT OpenEventA
#define EXPECTED_CREATE_MUTEX CreateMutexA
#define EXPECTED_CREATE_EVENT CreateEventA
#endif

static volatile open_event_alias_fn open_event_alias = OpenEvent;
static volatile create_mutex_alias_fn create_mutex_alias = CreateMutex;
static volatile create_event_alias_fn create_event_alias = CreateEvent;

int main(void)
{
    return open_event_alias != EXPECTED_OPEN_EVENT ||
           create_mutex_alias != EXPECTED_CREATE_MUTEX ||
           create_event_alias != EXPECTED_CREATE_EVENT;
}
