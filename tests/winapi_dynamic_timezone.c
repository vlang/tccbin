#include <windows.h>

/* Match V's declarations; the bundled headers predate these APIs. */
DWORD WINAPI GetDynamicTimeZoneInformation(void *);
WINBOOL WINAPI GetTimeZoneInformationForYear(WORD, void *, void *);

static DWORD (WINAPI *volatile dynamic_zone)(void *) = GetDynamicTimeZoneInformation;
static WINBOOL (WINAPI *volatile zone_for_year)(WORD, void *, void *) = GetTimeZoneInformationForYear;

int main(void)
{
    return dynamic_zone == NULL || zone_for_year == NULL;
}
