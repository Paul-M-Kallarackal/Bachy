// Test-only barrier: pause this writer after its temp file is synced, before replacement.
#define _GNU_SOURCE
#include <dlfcn.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int rename(const char *from, const char *to) {
    int (*real_rename)(const char *, const char *) = dlsym(RTLD_NEXT, "rename");
    const char *target = getenv("BACHY_UISTATE_TARGET");
    const char *ready = getenv("BACHY_UISTATE_READY");
    if (target && ready && strcmp(to, target) == 0) {
        FILE *file = fopen(ready, "wx");
        if (file) {
            fprintf(file, "%s", from);
            fclose(file);
            raise(SIGSTOP); // Parent kills only the PID it spawned after checking the marker.
        }
    }
    return real_rename(from, to);
}
