/*
 * One-shot DSM K4 DRM close-path probe. Never run stages in a loop: a kernel
 * fault may leave this process in uninterruptible D state despite SIGKILL.
 */
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "amdgpu.h"

typedef int (*initialize_fn)(int, uint32_t *, uint32_t *, amdgpu_device_handle *);
typedef int (*deinitialize_fn)(amdgpu_device_handle);
typedef int (*query_gpu_info_fn)(amdgpu_device_handle, struct amdgpu_gpu_info *);

static void checkpoint(const char *message)
{
    fprintf(stderr, "[k4-drm-probe pid=%ld] %s\n", (long)getpid(), message);
    fflush(stderr);
}

static void *required_symbol(void *library, const char *name)
{
    void *symbol = dlsym(library, name);
    if (!symbol) {
        fprintf(stderr, "dlsym(%s): %s\n", name, dlerror());
        exit(2);
    }
    return symbol;
}

int main(int argc, char **argv)
{
    const char *node = "/dev/dri/renderD128";
    int fd, result;
    void *library;
    uint32_t major = 0, minor = 0;
    amdgpu_device_handle device = NULL;
    initialize_fn initialize;
    deinitialize_fn deinitialize;

    if (argc < 2 || argc > 3 ||
        (strcmp(argv[1], "open-close") && strcmp(argv[1], "init-close") &&
         strcmp(argv[1], "query-close"))) {
        fprintf(stderr, "Usage: %s {open-close|init-close|query-close} [render-node]\n", argv[0]);
        return 2;
    }
    if (argc == 3)
        node = argv[2];

    checkpoint("before open");
    fd = open(node, O_RDWR | O_CLOEXEC);
    if (fd < 0) {
        fprintf(stderr, "open(%s): %s\n", node, strerror(errno));
        return 1;
    }
    checkpoint("after open");

    if (!strcmp(argv[1], "open-close")) {
        checkpoint("before close");
        result = close(fd);
        checkpoint("after close");
        return result == 0 ? 0 : 1;
    }

    library = dlopen("libdrm_amdgpu.so.1", RTLD_NOW | RTLD_LOCAL);
    if (!library) {
        fprintf(stderr, "dlopen: %s\n", dlerror());
        close(fd);
        return 2;
    }
    initialize = (initialize_fn)required_symbol(library, "amdgpu_device_initialize");
    deinitialize = (deinitialize_fn)required_symbol(library, "amdgpu_device_deinitialize");

    checkpoint("before amdgpu_device_initialize");
    result = initialize(fd, &major, &minor, &device);
    checkpoint("after amdgpu_device_initialize");
    if (result) {
        fprintf(stderr, "initialize returned %d\n", result);
        close(fd);
        dlclose(library);
        return 1;
    }
    fprintf(stderr, "AMDGPU DRM version %u.%u\n", major, minor);

    if (!strcmp(argv[1], "query-close")) {
        struct amdgpu_gpu_info info = {0};
        query_gpu_info_fn query =
            (query_gpu_info_fn)required_symbol(library, "amdgpu_query_gpu_info");
        checkpoint("before amdgpu_query_gpu_info");
        result = query(device, &info);
        checkpoint("after amdgpu_query_gpu_info");
        if (result)
            fprintf(stderr, "query returned %d\n", result);
        else
            fprintf(stderr, "ASIC ID 0x%x\n", info.asic_id);
    }

    checkpoint("before amdgpu_device_deinitialize");
    result = deinitialize(device);
    checkpoint("after amdgpu_device_deinitialize");
    checkpoint("before close");
    if (close(fd))
        result = 1;
    checkpoint("after close");
    dlclose(library);
    checkpoint("before exit");
    return result ? 1 : 0;
}
