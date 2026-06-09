#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#include "dif_spi_host.h"
// #include "reckon/reckon.h"
#include "reckon/reckon_params_vec.h"

#include "regs/cheshire.h"
#include "params.h"
#include "util.h"
#include "dif/uart.h"
#include "printf.h"
#include "reckon/spi_regs_corrected.h"
#include "sw/include/spi_host_regs.h"

typedef struct reckon_spi_command {
    uint32_t address;
    uint32_t data;
} reckon_spi_command_t;

void send_command_reckon(uint32_t N_bytes) {

    mmio_region_t spi_base_addr = (mmio_region_t){.base = (void *)&__base_spih};

    uint32_t reg = 0;
    uint16_t length = N_bytes;
    dif_spi_host_width_t speed = 0;
    dif_spi_host_direction_t direction = 2;

    bitfield_field32_t len_field = {.mask = 0xFFFFF, .index = 5};
    bitfield_field32_t spd_field = {.mask = 0x3, .index = 1};
    bitfield_field32_t dir_field = {.mask = 0x3, .index = 3};
    
    reg = bitfield_field32_write(reg, spd_field, speed);
    reg = bitfield_field32_write(reg, dir_field, direction);
    reg = bitfield_field32_write(reg, len_field, length - 1);
    reg = bitfield_bit32_write(reg, 0, false); //csaat

    // bool ready = false;
    // uint32_t status = 0;
    // do {
    //     status = mmio_region_read32(spi_base_addr, SPI_HOST_STATUS_REG_OFFSET);
    //     ready = bitfield_bit32_read(status, SPI_HOST_STATUS_TXEMPTY_BIT);
    // } while (!ready);

    printf("Issuing command to SPI Host - Command Reg: 0x%08X\n\r", reg);
    uint32_t control_reg = mmio_region_read32(spi_base_addr, SPI_HOST_CONTROL_REG_OFFSET);
    mmio_region_write32(spi_base_addr, SPI_HOST_CONTROL_REG_OFFSET, bitfield_bit32_write(control_reg, SPI_HOST_CONTROL_OUTPUT_EN_BIT, true));
    mmio_region_write32(spi_base_addr, SPI_HOST_COMMAND_REG_OFFSET, reg);

    // return status;
}

int main() {

    printf("----------------------------------------------------\n\r");
    printf("----------------------------------------------------\n\r");
    // mmio_region_t SPI_MMIO = mmio_region_from_addr((uintptr_t)&__base_spih);
    mmio_region_t SPI_MMIO = (mmio_region_t){.base = (void *)&__base_spih};
    dif_spi_host_t chs_spi = {.base_addr = SPI_MMIO};
    dif_spi_host_config_t chs_spi_config;
    bool ready = false;

    reckon_spi_command_t SPI_EN_CONF = {.address = 0x00010000, .data = 0x00000000};
    uint32_t SPI_EN_CONF_ARR[2] = {0x00010000, 0x00000000};
    uint32_t DUMMY_ARR[4] = {0xAAAABBBB, 0xCCCCDDDD, 0xEEEEFFFF, 0x11112222};

    /*STEP 0: INITIALIZE THE SPI HOST IP*/
    //printf("Initializing SPI Host - Base Address: 0x%08X - return %d\n\r", (uintptr_t)SPI_MMIO.base, dif_spi_host_init(SPI_MMIO, &chs_spi) );

    /* STEP 1: CONFIGURE CONFIGOPTS*/
    chs_spi_config.spi_clock = 2500000;
    chs_spi_config.peripheral_clock_freq_hz = 50000000;
    chs_spi_config.full_cycle = 0;
    chs_spi_config.cpha = 0;
    chs_spi_config.cpol = 0;
    chs_spi_config.chip_select.idle  = 0;
    chs_spi_config.chip_select.trail = 0;
    chs_spi_config.chip_select.lead  = 0;

    /*STEP 2: SET THE INTERRUPTS*/
    mmio_region_write32(SPI_MMIO, SPI_HOST_INTR_ENABLE_REG_OFFSET, 0);

    /*STEP 3: ENABLE THE IP*/
    uint32_t control_reg = mmio_region_read32(SPI_MMIO, SPI_HOST_CONTROL_REG_OFFSET);
    printf("Control Reg before enabling: 0x%08X\n\r", control_reg);
    mmio_region_write32(SPI_MMIO, SPI_HOST_CONTROL_REG_OFFSET, bitfield_bit32_write(control_reg, SPI_HOST_CONTROL_SW_RST_BIT, true));
    mmio_region_write32(SPI_MMIO, SPI_HOST_CONTROL_REG_OFFSET, bitfield_bit32_write(control_reg, SPI_HOST_CONTROL_SPIEN_BIT, true)); // Deassert reset and enabling IP + output
    // dif_spi_host_output_set_enabled(chs_spi, true);

    printf("Configuring SPI Host - return %d\n\r", dif_spi_host_configure_cs(&chs_spi, chs_spi_config, 0));

    /*STEP 4: LOAD DATA TO TX FIFO*/
    //printf("Loading data into TX FIFO - return %d\n\r", dif_spi_host_fifo_write(&chs_spi, (const void *)SPI_EN_CONF_ARR, 8));
    // printf("Loading data into TX FIFO - return %d\n\r", /*dif_spi_host_fifo_write(&chs_spi, (const void *)DUMMY_ARR, 16)*/ 0);
    ready = false;
    uint32_t status = 0;
    for (int i = 0; i < 2; i++) {
        do {
            status = mmio_region_read32(SPI_MMIO, SPI_HOST_STATUS_REG_OFFSET);
            ready = bitfield_bit32_read(status, SPI_HOST_STATUS_READY_BIT);
        } while (!ready);
        mmio_region_write32(SPI_MMIO, (ptrdiff_t)SPI_HOST_TXDATA_REG_OFFSET, DUMMY_ARR[i]);
    }
    // do {
    //     status = mmio_region_read32(SPI_MMIO, SPI_HOST_STATUS_REG_OFFSET);
    //     ready = bitfield_bit32_read(status, SPI_HOST_STATUS_READY_BIT);
    // } while (!ready);
    // mmio_region_write32(SPI_MMIO, SPI_HOST_TXDATA_REG_OFFSET, DUMMY_ARR[0]);
    // mmio_region_write32(SPI_MMIO, SPI_HOST_TXDATA_REG_OFFSET, DUMMY_ARR[1]);
    // mmio_region_write32(SPI_MMIO, SPI_HOST_TXDATA_REG_OFFSET, DUMMY_ARR[2]);
    // mmio_region_write32(SPI_MMIO, SPI_HOST_TXDATA_REG_OFFSET, DUMMY_ARR[3]);

    bitfield_field32_t txfifostatus_field = {.mask = 0xFF, .index = 0};
    bitfield_field32_t rxfifostatus_field = {.mask = 0xFF, .index = 8};
    printf("NR OF QUEUED DATA ON TX FIFO: %d\r\n", bitfield_field32_read(mmio_region_read32(SPI_MMIO, SPI_HOST_STATUS_REG_OFFSET), txfifostatus_field) );
    printf("NR OF QUEUED DATA ON RX FIFO: %d\r\n", bitfield_field32_read(mmio_region_read32(SPI_MMIO, SPI_HOST_STATUS_REG_OFFSET), rxfifostatus_field) );

    /*STEP 5: PROGRAMMING CSID*/
    //uint32_t csid_reg = mmio_region_read32(SPI_MMIO, SPI_HOST_CSID_REG_OFFSET);
    //bool csid = bitfield_bit32_read(csid_reg, 0);
    printf("CSID register: %d\n\r", mmio_region_read32(SPI_MMIO, SPI_HOST_CSID_REG_OFFSET));
    mmio_region_write32(SPI_MMIO, SPI_HOST_CSID_REG_OFFSET,0/*, bitfield_bit32_write(csid_reg, 0, true)*/);
    
    /*STEP 6: CHECK READY BIT*/
    ready = false;
    status = 0;
    do {
        status = mmio_region_read32(SPI_MMIO, SPI_HOST_STATUS_REG_OFFSET);
        ready = bitfield_bit32_read(status, SPI_HOST_STATUS_READY_BIT);
    } while (!ready);
    printf("SPI Host is ready...\n\r");
    printf("STATUS REG: 0x%08X\r\n", status);

    /*STEP 7: SEND COMMAND*/
    send_command_reckon(1);

    /*WAITING FOR TRANSMISSION TO COMPLETE*/
    printf("Waiting for Transmission..........\r\n");

    ready = false;
    do {
        status = mmio_region_read32(SPI_MMIO, SPI_HOST_STATUS_REG_OFFSET);
        ready = bitfield_bit32_read(status, SPI_HOST_STATUS_TXEMPTY_BIT);
    } while (!ready);
    printf("TX FIFO is now empty.\n\r");

    control_reg = mmio_region_read32(SPI_MMIO, SPI_HOST_CONTROL_REG_OFFSET);
    mmio_region_write32(SPI_MMIO, SPI_HOST_CONTROL_REG_OFFSET, bitfield_bit32_write(control_reg, SPI_HOST_CONTROL_OUTPUT_EN_BIT, false));
    
    return 0;
}

