#include <windows.h>
#include <winreg.h>

typedef LONG (WINAPI *reg_delete_key_w_fn)(HKEY hKey,LPCWSTR lpSubKey);

static volatile reg_delete_key_w_fn reg_delete_key_w_ptr = RegDeleteKeyW;

int main(void)
{
    return reg_delete_key_w_ptr == 0;
}
