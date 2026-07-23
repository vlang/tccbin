/* Smoke test 3: a genuine fault, to confirm patch 0002 doesn't weaken
   real crash detection - only DBG_PRINTEXCEPTION_C should be passed
   through, everything else must still be caught and reported. */
int main(void) {
    int *p = (int *)0;
    return *p;
}
