#define WINVER 0x0600
#define _WIN32_WINNT 0x0600
#include <winsock2.h>

#ifdef UNICODE
typedef LPWSTR wsa_connect_by_name_string;
#define WSA_CONNECT_BY_NAME_EXPECTED WSAConnectByNameW
#else
typedef LPCSTR wsa_connect_by_name_string;
#define WSA_CONNECT_BY_NAME_EXPECTED WSAConnectByNameA
#endif

typedef WINBOOL (WSAAPI *wsa_connect_by_list_fn)(SOCKET s,LPSOCKET_ADDRESS_LIST SocketAddress,LPDWORD LocalAddressLength,LPSOCKADDR LocalAddress,LPDWORD RemoteAddressLength,LPSOCKADDR RemoteAddress,const struct timeval *timeout,LPWSAOVERLAPPED Reserved);
typedef WINBOOL (WSAAPI *wsa_connect_by_name_a_fn)(SOCKET s,LPCSTR nodename,LPCSTR servicename,LPDWORD LocalAddressLength,LPSOCKADDR LocalAddress,LPDWORD RemoteAddressLength,LPSOCKADDR RemoteAddress,const struct timeval *timeout,LPWSAOVERLAPPED Reserved);
typedef WINBOOL (WSAAPI *wsa_connect_by_name_w_fn)(SOCKET s,LPWSTR nodename,LPWSTR servicename,LPDWORD LocalAddressLength,LPSOCKADDR LocalAddress,LPDWORD RemoteAddressLength,LPSOCKADDR RemoteAddress,const struct timeval *timeout,LPWSAOVERLAPPED Reserved);
typedef WINBOOL (WSAAPI *wsa_connect_by_name_fn)(SOCKET s,wsa_connect_by_name_string nodename,wsa_connect_by_name_string servicename,LPDWORD LocalAddressLength,LPSOCKADDR LocalAddress,LPDWORD RemoteAddressLength,LPSOCKADDR RemoteAddress,const struct timeval *timeout,LPWSAOVERLAPPED Reserved);

static volatile wsa_connect_by_list_fn connect_by_list_ptr = WSAConnectByList;
static volatile wsa_connect_by_name_a_fn connect_by_name_a_ptr = WSAConnectByNameA;
static volatile wsa_connect_by_name_w_fn connect_by_name_w_ptr = WSAConnectByNameW;
static volatile wsa_connect_by_name_fn connect_by_name_ptr = WSAConnectByName;

int main(void)
{
    return connect_by_list_ptr == 0 ||
           connect_by_name_a_ptr == 0 ||
           connect_by_name_w_ptr == 0 ||
           connect_by_name_ptr != WSA_CONNECT_BY_NAME_EXPECTED;
}
