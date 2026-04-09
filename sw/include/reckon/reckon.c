#include "sw/device/lib/dif/dif_spi_host.h"

#include <assert.h>
#include <stdalign.h>
#include <stddef.h>

#include "sw/device/lib/base/bitfield.h"
#include "sw/device/lib/base/memory.h"
#include "sw/device/lib/base/mmio.h"

#include "params.h"
#include "util.h"

#include "spi_host_regs.h"

// int write_axirf(int offset, uint32_t value);

// void read_axirf(int offset);