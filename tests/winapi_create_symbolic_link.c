#define WINVER 0x0600
#define _WIN32_WINNT 0x0600
#include <windows.h>
#include <tchar.h>

int main(void)
{
    DWORD flags = SYMBOLIC_LINK_FLAG_DIRECTORY |
                  SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE;
    (void)CreateSymbolicLinkA("tccbin-probe-link-a", "tccbin-probe-target-a", flags);
    (void)CreateSymbolicLinkW(L"tccbin-probe-link-w", L"tccbin-probe-target-w", flags);
    (void)CreateSymbolicLink(TEXT("tccbin-probe-link"),
                            _T("tccbin-probe-target"), flags);
    return 0;
}
