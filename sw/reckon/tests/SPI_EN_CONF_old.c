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

typedef struct reckon_spi_command {
    uint32_t address;
    uint32_t data;
} reckon_spi_command_t;

int main() {

    mmio_region_t SPI_MMIO = mmio_region_from_addr((uintptr_t)__base_spih);
    dif_spi_host_t *chs_spi;
    dif_spi_host_config_t chs_spi_config;

    reckon_spi_command_t SPI_EN_CONF = {.address = 0x00010000, .data = 0x00000001};

    uint32_t rtc_freq = *reg32(&__base_regs, CHESHIRE_RTC_FREQ_REG_OFFSET);

    dif_spi_host_init(SPI_MMIO, chs_spi);

    chs_spi_config.spi_clock = 3750000;
    chs_spi_config.peripheral_clock_freq_hz = 50000000;
    chs_spi_config.full_cycle = 0;
    
    chs_spi_config.cpha = 0;
    chs_spi_config.cpol = 0;
    chs_spi_config.chip_select.idle  = 0;
    chs_spi_config.chip_select.trail = 0;
    chs_spi_config.chip_select.lead  = 0;

    dif_spi_host_configure(chs_spi, chs_spi_config);
    dif_spi_host_reset(chs_spi);

    int spi_cmd_length = 7;

    aux_write_command_reg(chs_spi, (uint16_t)spi_cmd_length, kDifSpiHostWidthStandard, kDifSpiHostDirectionTx, false);
    
    dif_spi_host_fifo_write(chs_spi, &SPI_EN_CONF, 8);

    // uprintf("Waiting for Transmission..........", __base_uart, rtc_freq);


    // uprintf("Done, exiting", __base_uart, rtc_freq);
    
    return 0;
}

// void uprintf(char *str, void *base_uart, uint32_t rtc_freq) {
//     // uint32_t rtc_freq = *reg32(&__base_regs, CHESHIRE_RTC_FREQ_REG_OFFSET);
//     uint64_t reset_freq = clint_get_core_freq(rtc_freq, 2500);
//     uart_init(&base_uart, reset_freq, __BOOT_BAUDRATE);
//     uart_write_str(&base_uart, str, sizeof(str));
//     uart_write_flush(&base_uart);
//     return;
// }

    // char str[] = "Hello World!\r\n";
    // uint32_t rtc_freq = *reg32(&__base_regs, CHESHIRE_RTC_FREQ_REG_OFFSET);
    // uint64_t reset_freq = clint_get_core_freq(rtc_freq, 2500);
    // uart_init(&__base_uart, reset_freq, __BOOT_BAUDRATE);
    // uart_write_str(&__base_uart, str, sizeof(str));
    // uart_write_flush(&__base_uart);