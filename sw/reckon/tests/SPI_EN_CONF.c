#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

//#include "dif_spi_host.h"
#include "reckon/reckon.h"
#include "reckon/reckon_params_vec.h"

#include "regs/cheshire.h"
#include "params.h"
#include "util.h"
#include "dif/uart.h"
#include "printf.h"
// #include "sw/include/spi_host_regs.h"

int main() {

    printf("----------------------------------------------------\n\r");
    printf("----------------------------------------------------\n\r");
    dif_spi_host_t chs_spi = {.base_addr = SPI_BASE_ADDR};
    dif_spi_host_config_t chs_spi_config;
    bool ready = false;

    uint32_t SPI_EN_CONF_ARR[2] = {0x00010000, 0};
    uint32_t DUMMY_ARR[4] = {0x12345678,0xAAAABBBB, 0xCCCCDDDD, 0xEEEEFFFF};

    /*STEP 0: INITIALIZE THE SPI HOST IP*/
    //printf("Initializing SPI Host - Base Address: 0x%08X - return %d\n\r", (uintptr_t)SPI_BASE_ADDR.base, dif_spi_host_init(SPI_BASE_ADDR, &chs_spi) );

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
    mmio_region_write32(SPI_BASE_ADDR, SPI_HOST_INTR_ENABLE_REG_OFFSET, 0);

    /*STEP 3: ENABLE THE IP*/
    uint32_t control_reg = mmio_region_read32(SPI_BASE_ADDR, SPI_HOST_CONTROL_REG_OFFSET);
    printf("Control Reg before enabling: 0x%08X\n\r", control_reg);
    mmio_region_write32(SPI_BASE_ADDR, SPI_HOST_CONTROL_REG_OFFSET, bitfield_bit32_write(control_reg, SPI_HOST_CONTROL_SW_RST_BIT, true));
    mmio_region_write32(SPI_BASE_ADDR, SPI_HOST_CONTROL_REG_OFFSET, bitfield_bit32_write(control_reg, SPI_HOST_CONTROL_SPIEN_BIT, true)); // Deassert reset and enabling IP + output
    // dif_spi_host_output_set_enabled(chs_spi, true);

    printf("Configuring SPI Host - return %d\n\r", dif_spi_host_configure_cs(&chs_spi, chs_spi_config, 0));

    /*STEP 4: LOAD DATA TO TX FIFO*/
    ready = false;
    uint32_t status = 0;
    for (int i = 0; i < 2; i++) {
        rck_write_txfifo_byteorder(SPI_EN_CONF_ARR[i]);
    }

    printf("NR OF QUEUED DATA ON TX FIFO: %d\r\n", bitfield_field32_read(mmio_region_read32(SPI_BASE_ADDR, SPI_HOST_STATUS_REG_OFFSET), SPI_HOST_STATUS_TXQD_FIELD) );
    printf("NR OF QUEUED DATA ON RX FIFO: %d\r\n", bitfield_field32_read(mmio_region_read32(SPI_BASE_ADDR, SPI_HOST_STATUS_REG_OFFSET), SPI_HOST_STATUS_RXQD_FIELD) );

    /*STEP 5: PROGRAMMING CSID*/
    //uint32_t csid_reg = mmio_region_read32(SPI_BASE_ADDR, SPI_HOST_CSID_REG_OFFSET);
    //bool csid = bitfield_bit32_read(csid_reg, 0);
    printf("CSID register: %d\n\r", mmio_region_read32(SPI_BASE_ADDR, SPI_HOST_CSID_REG_OFFSET));
    mmio_region_write32(SPI_BASE_ADDR, SPI_HOST_CSID_REG_OFFSET,0/*, bitfield_bit32_write(csid_reg, 0, true)*/);
    
    /*STEP 6: CHECK READY BIT*/
    ready = false;
    status = 0;
    do {
        status = mmio_region_read32(SPI_BASE_ADDR, SPI_HOST_STATUS_REG_OFFSET);
        ready = bitfield_bit32_read(status, SPI_HOST_STATUS_READY_BIT);
    } while (!ready);
    printf("SPI Host is ready...\n\r");
    printf("STATUS REG: 0x%08X\r\n", status);

    /*STEP 7: SEND COMMAND*/
    rck_send_command(8);

    /*WAITING FOR TRANSMISSION TO COMPLETE*/
    printf("Waiting for Transmission..........\r\n");

    ready = false;
    do {
        status = mmio_region_read32(SPI_BASE_ADDR, SPI_HOST_STATUS_REG_OFFSET);
        ready = bitfield_bit32_read(status, SPI_HOST_STATUS_TXEMPTY_BIT);
    } while (!ready);
    printf("TX FIFO is now empty.\n\r");

    control_reg = mmio_region_read32(SPI_BASE_ADDR, SPI_HOST_CONTROL_REG_OFFSET);
    mmio_region_write32(SPI_BASE_ADDR, SPI_HOST_CONTROL_REG_OFFSET, bitfield_bit32_write(control_reg, SPI_HOST_CONTROL_OUTPUT_EN_BIT, false));
    
    return 0;
}

