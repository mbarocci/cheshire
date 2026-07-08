#include "sw/device/lib/dif/dif_spi_host.h"

#include <assert.h>
#include <stdalign.h>
#include <stddef.h>

#include "sw/device/lib/base/bitfield.h"
#include "sw/device/lib/base/memory.h"
#include "sw/device/lib/base/mmio.h"

#include "params.h"
#include "util.h"

#include "reckon/reckon.h"

#include "spi_host_regs.h"

uint32_t rck_write_txfifo_byteorder(uint32_t data) {
    uint32_t newdata = 0;
    uint8_t byte = 0;

    for (int i=0; i<4; i++) {
        byte = (data & (0xFF << (8 * i))) >> (8 * i);
        newdata |= (byte << (8 * (3 - i)));
    }

    bool ready = false;
    do {
        ready = bitfield_bit32_read(mmio_region_read32(SPI_BASE_ADDR, SPI_HOST_STATUS_REG_OFFSET), SPI_HOST_STATUS_READY_BIT);
    } while (!ready);
    
    mmio_region_write32(SPI_BASE_ADDR, SPI_HOST_TXDATA_REG_OFFSET, newdata);
    return newdata;
}

uint32_t rck_gen_spi_cmd(uint32_t N_bytes) {

    uint32_t reg = 0;
    uint16_t length = N_bytes;
    dif_spi_host_width_t speed = 0;
    dif_spi_host_direction_t direction = 2;

    reg = bitfield_field32_write(reg, SPI_HOST_COMMAND_SPEED_FIELD, speed);
    reg = bitfield_field32_write(reg, SPI_HOST_COMMAND_DIRECTION_FIELD, direction);
    reg = bitfield_field32_write(reg, SPI_HOST_COMMAND_LEN_FIELD, length -1);
    reg = bitfield_bit32_write(reg, SPI_HOST_COMMAND_CSAAT_BIT, false); //csaat

    return reg;
}

bool wait_for_ready(mmio_region_t base, ptrdiff_t offset, bitfield_bit32_index_t bit_index) {

    volatile bool ready = false;
    volatile uint32_t status = 0;

    do {
        status = mmio_region_read32(base, offset);
        ready = bitfield_bit32_read(status, bit_index);
    } while (!ready);

    return ready;
}

///////////////////////////////
///////////// AXI /////////////
///////////////////////////////

void rck_write_axirf(int offset, uint32_t value) {
    *reg32(&__base_axirf, (offset + (uint32_t)N_READ_REGS)*8) = value;   
}

uint32_t rck_read_axirf(int offset) {
    return *reg32(&__base_axirf, offset*8);    
}

void rck_toggle_signal(int offset, int value) {
    rck_write_axirf(offset, value);
    for (int i=0 ; i<32 ; i++) {
        asm volatile ("nop");
    }
    rck_write_axirf(offset, 1-value);
}

bool rck_wait_for_signal(int offset) {
    bool flag = 0;
    uint32_t reg = 0;
    do {
        reg = rck_read_axirf(offset);
        flag = bitfield_bit32_read(reg, (bitfield_bit32_index_t)0);
    } while (!flag);
    return flag;
}

uint32_t rck_read_accuracy() {
    return rck_read_axirf((uint32_t)INFER_COUNT_REG);
}

void rck_set_counter_conf(int nr_count, uint32_t value) {
    *reg32(&__base_axirf, (COUNTER_CONF_START_ADD + nr_count)*8) = value;
}

uint32_t rck_get_counter_value(int nr_count) {
    return rck_read_axirf(COUNTER_READ_ADD + nr_count);
}

