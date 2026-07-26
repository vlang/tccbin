#define WINVER 0x0600
#define _WIN32_WINNT 0x0600
#include <winsock2.h>
#include <ws2tcpip.h>

typedef LPCSTR (WSAAPI *inet_ntop_a_fn)(INT Family,LPCVOID pAddr,LPSTR pStringBuf,size_t StringBufSize);
typedef LPCWSTR (WSAAPI *inet_ntop_w_fn)(INT Family,LPCVOID pAddr,LPWSTR pStringBuf,size_t StringBufSize);
typedef INT (WSAAPI *inet_pton_a_fn)(INT Family,LPCSTR pStringBuf,PVOID pAddr);
typedef INT (WSAAPI *inet_pton_w_fn)(INT Family,LPCWSTR pStringBuf,PVOID pAddr);

#ifdef UNICODE
typedef inet_ntop_w_fn inet_ntop_neutral_fn;
typedef inet_pton_w_fn inet_pton_neutral_fn;
#define EXPECTED_INET_NTOP InetNtopW
#define EXPECTED_INET_PTON InetPtonW
#else
typedef inet_ntop_a_fn inet_ntop_neutral_fn;
typedef inet_pton_a_fn inet_pton_neutral_fn;
#define EXPECTED_INET_NTOP InetNtopA
#define EXPECTED_INET_PTON InetPtonA
#endif

static volatile inet_ntop_a_fn inet_ntop_ptr = inet_ntop;
static volatile inet_ntop_a_fn inet_ntop_a_ptr = InetNtopA;
static volatile inet_ntop_w_fn inet_ntop_w_ptr = InetNtopW;
static volatile inet_ntop_neutral_fn inet_ntop_neutral_ptr = InetNtop;
static volatile inet_pton_a_fn inet_pton_ptr = inet_pton;
static volatile inet_pton_a_fn inet_pton_a_ptr = InetPtonA;
static volatile inet_pton_w_fn inet_pton_w_ptr = InetPtonW;
static volatile inet_pton_neutral_fn inet_pton_neutral_ptr = InetPton;

static int probe_calls(void)
{
    IN_ADDR ansi_address = {0};
    IN_ADDR wide_address = {0};
    char ansi_text[INET_ADDRSTRLEN];
    WCHAR wide_text[INET_ADDRSTRLEN];

    if (inet_pton(AF_INET,"127.0.0.1",&ansi_address) != 1)
        return 2;
    if (inet_ntop(AF_INET,&ansi_address,ansi_text,sizeof(ansi_text)) == 0)
        return 3;
    if (InetPtonW(AF_INET,L"127.0.0.1",&wide_address) != 1)
        return 4;
    if (InetNtopW(AF_INET,&wide_address,wide_text,sizeof(wide_text) / sizeof(wide_text[0])) == 0)
        return 5;
    return 0;
}

int main(void)
{
    if (inet_ntop_ptr == 0 ||
        inet_ntop_a_ptr != inet_ntop_ptr ||
        inet_ntop_w_ptr == 0 ||
        inet_ntop_neutral_ptr != EXPECTED_INET_NTOP ||
        inet_pton_ptr == 0 ||
        inet_pton_a_ptr != inet_pton_ptr ||
        inet_pton_w_ptr == 0 ||
        inet_pton_neutral_ptr != EXPECTED_INET_PTON)
        return 1;
    return probe_calls();
}
