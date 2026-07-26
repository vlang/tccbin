#include <windows.h>
#include <shellapi.h>

#ifndef TCCBIN_NO_SHELL32_PRAGMA
#pragma comment(lib,"shell32")
#endif

_Static_assert(sizeof(HDROP) == sizeof(void *),"HDROP must be pointer-sized");
_Static_assert(sizeof(POINT) == 8,"POINT must contain two 32-bit LONG values");
_Static_assert(sizeof(WINBOOL) == 4,"WINBOOL must be 32-bit");

typedef UINT (WINAPI *drag_query_file_a_fn)(HDROP hDrop,UINT iFile,LPSTR lpszFile,UINT cch);
typedef UINT (WINAPI *drag_query_file_w_fn)(HDROP hDrop,UINT iFile,LPWSTR lpszFile,UINT cch);
typedef WINBOOL (WINAPI *drag_query_point_fn)(HDROP hDrop,POINT *ppt);
typedef void (WINAPI *drag_finish_fn)(HDROP hDrop);
typedef void (WINAPI *drag_accept_files_fn)(HWND hWnd,WINBOOL fAccept);
typedef HINSTANCE (WINAPI *shell_execute_a_fn)(HWND hwnd,LPCSTR lpOperation,LPCSTR lpFile,LPCSTR lpParameters,LPCSTR lpDirectory,INT nShowCmd);
typedef HINSTANCE (WINAPI *shell_execute_w_fn)(HWND hwnd,LPCWSTR lpOperation,LPCWSTR lpFile,LPCWSTR lpParameters,LPCWSTR lpDirectory,INT nShowCmd);
typedef HINSTANCE (WINAPI *find_executable_a_fn)(LPCSTR lpFile,LPCSTR lpDirectory,LPSTR lpResult);
typedef HINSTANCE (WINAPI *find_executable_w_fn)(LPCWSTR lpFile,LPCWSTR lpDirectory,LPWSTR lpResult);
typedef LPWSTR *(WINAPI *command_line_to_argv_w_fn)(LPCWSTR lpCmdLine,int *pNumArgs);

#ifdef UNICODE
typedef drag_query_file_w_fn drag_query_file_neutral_fn;
typedef shell_execute_w_fn shell_execute_neutral_fn;
typedef find_executable_w_fn find_executable_neutral_fn;
#define EXPECTED_DRAG_QUERY_FILE DragQueryFileW
#define EXPECTED_SHELL_EXECUTE ShellExecuteW
#define EXPECTED_FIND_EXECUTABLE FindExecutableW
#else
typedef drag_query_file_a_fn drag_query_file_neutral_fn;
typedef shell_execute_a_fn shell_execute_neutral_fn;
typedef find_executable_a_fn find_executable_neutral_fn;
#define EXPECTED_DRAG_QUERY_FILE DragQueryFileA
#define EXPECTED_SHELL_EXECUTE ShellExecuteA
#define EXPECTED_FIND_EXECUTABLE FindExecutableA
#endif

static volatile drag_query_file_a_fn drag_query_file_a_ptr = DragQueryFileA;
static volatile drag_query_file_w_fn drag_query_file_w_ptr = DragQueryFileW;
static volatile drag_query_file_neutral_fn drag_query_file_ptr = DragQueryFile;
static volatile drag_query_point_fn drag_query_point_ptr = DragQueryPoint;
static volatile drag_finish_fn drag_finish_ptr = DragFinish;
static volatile drag_accept_files_fn drag_accept_files_ptr = DragAcceptFiles;
static volatile shell_execute_a_fn shell_execute_a_ptr = ShellExecuteA;
static volatile shell_execute_w_fn shell_execute_w_ptr = ShellExecuteW;
static volatile shell_execute_neutral_fn shell_execute_ptr = ShellExecute;
static volatile find_executable_a_fn find_executable_a_ptr = FindExecutableA;
static volatile find_executable_w_fn find_executable_w_ptr = FindExecutableW;
static volatile find_executable_neutral_fn find_executable_ptr = FindExecutable;
static volatile command_line_to_argv_w_fn command_line_to_argv_w_ptr = CommandLineToArgvW;

int main(void)
{
    return drag_query_file_a_ptr == 0 ||
           drag_query_file_w_ptr == 0 ||
           drag_query_file_ptr != EXPECTED_DRAG_QUERY_FILE ||
           drag_query_point_ptr == 0 ||
           drag_finish_ptr == 0 ||
           drag_accept_files_ptr == 0 ||
           shell_execute_a_ptr == 0 ||
           shell_execute_w_ptr == 0 ||
           shell_execute_ptr != EXPECTED_SHELL_EXECUTE ||
           find_executable_a_ptr == 0 ||
           find_executable_w_ptr == 0 ||
           find_executable_ptr != EXPECTED_FIND_EXECUTABLE ||
           command_line_to_argv_w_ptr == 0;
}
