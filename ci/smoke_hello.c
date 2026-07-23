/* Smoke test 1: trivial program, GC-initialized but no real allocation
   load. Exercises the same startup path (GC_INIT -> Boehm's Windows
   logging, which calls OutputDebugString) that crashed before patch
   0002, without needing a full V bootstrap in CI. */
#include <stdio.h>
#include "gc.h"

int main(void) {
    GC_INIT();
    printf("hello\n");
    return 0;
}
