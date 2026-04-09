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

#define INFER_COUNT_REG 0
#define BATCH_DONE_REG  1
#define EPOCH_DONE_REG  2
#define TEST_REG        3

#define N_READ_REGS     4

#define BATCH_SIZE_ADD  0
#define N_EPOCH_ADD     1
#define N_SAMPLES_ADD   2
#define DO_EPROP_ADD    3

#define NEW_EPOCH_REG   4
#define NEW_BATCH_REG   5
#define STOP_REG        6
#define TEST_REG        7

///////////////////////////////
///////////// SPI /////////////
///////////////////////////////

typedef struct reckon_spi_command {
    uint32_t address;
    uint32_t data;
} reckon_spi_command_t;

void write_spi_confreg(const dif_spi_host_t *spi_host, reckon_spi_command_t command) {
    
    dif_spi_host_fifo_write(spi_host, &command.address, 4);
    dif_spi_host_fifo_write(spi_host, &command.data, 4);
    
    mmio_region_write32(spi_host->base_addr, SPI_HOST_CSID_REG_OFFSET, 0);

    uint32_t commandreg = 0;
    commandreg |= (2 << 3) | (7 << 5);
    mmio_region_write32(spi_host->base_addr, SPI_HOST_COMMAND_REG_OFFSET, commandreg);

    // wait_tx_fifo(spi_host);
}

///////////////////////////////
///////////// AXI /////////////
///////////////////////////////

void write_axirf(int offset, uint32_t value) {
    *reg32(&__base_axirf, (offset + (uint32_t)N_READ_REGS)*4) = value;   
}

unsigned int read_axirf(int offset) {
    return *reg32(&__base_axirf, offset*4);    
}

void toggle_signal(int offset, int value) {
    write_axirf(offset, value);
    for (int i=0 ; i<5 ; i++) {
        asm volatile ("nop");
    }
    write_axirf(offset, 1-value);
}

void wait_for_signal(int offset) {
    int flag = 0;
    do {
        flag = read_axirf(offset);
    } while (flag == 0);
}

uint32_t read_accuracy() {
    return read_axirf((uint32_t)INFER_COUNT_REG);
}