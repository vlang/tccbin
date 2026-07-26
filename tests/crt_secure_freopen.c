#include <stdio.h>
#include <string.h>

typedef errno_t (__cdecl *fopen_s_fn)(FILE **, const char *, const char *);
typedef errno_t (__cdecl *freopen_s_fn)(FILE **, const char *, const char *, FILE *);

static fopen_s_fn checked_fopen_s = fopen_s;
static freopen_s_fn checked_freopen_s = freopen_s;

int main(int argc, char **argv) {
	static const char expected[] = "tccbin secure CRT probe\n";
	char actual[sizeof(expected)] = {0};
	FILE *stream = NULL;
	FILE *reopened = NULL;
	int result = 0;

	if (argc != 2) {
		return 2;
	}
	if (checked_fopen_s(&stream, argv[1], "w+") != 0 || stream == NULL) {
		return 3;
	}
	if (fputs(expected, stream) == EOF) {
		fclose(stream);
		return 4;
	}
	if (checked_freopen_s(&reopened, argv[1], "r", stream) != 0 || reopened == NULL) {
		return 5;
	}
	if (fgets(actual, (int) sizeof(actual), reopened) == NULL) {
		result = 6;
	} else if (strcmp(actual, expected) != 0) {
		result = 7;
	}
	if (fclose(reopened) != 0 && result == 0) {
		result = 8;
	}
	return result;
}
