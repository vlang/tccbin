#define WINVER 0x0600
#define _WIN32_WINNT 0x0600
#include <windows.h>

typedef WINBOOL (WINAPI *cancel_io_ex_fn)(HANDLE, LPOVERLAPPED);

static cancel_io_ex_fn checked_cancel_io_ex = CancelIoEx;

int main(void)
{
    return checked_cancel_io_ex == NULL;
}
