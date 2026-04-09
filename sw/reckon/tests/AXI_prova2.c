#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>

#include "sw/device/lib/dif/dif_spi_host.h"
#include "regs/cheshire.h"
#include "dif/clint.h"
#include "dif/uart.h"
#include "params.h"
#include "util.h"
#include "reckon/reckon.h"

int main() {

    // void *base = (void *)BASE_AXIRF;
    int reg = write_axirf(4, 0xcafebabe);
    // *reg32(&__base_axirf, 4)  = 0xCAFEBABE;
    // *reg32(&__base_axirf, 5)  = 0xAAAAAAAA;
    // *reg32(&__base_axirf, 6)  = 0xABABABAB;
    // *reg32(&__base_axirf, 7)  = 0xCCCC7777;
    // *reg32(&__base_axirf, 8)  = 0x12345678;
    // *reg32(&__base_axirf, 9)  = 0xF0F0F0F0;
    // *reg32(&__base_axirf, 10) = 0xF5F6F7F8;

    return 0;
}