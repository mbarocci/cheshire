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
#include "../SPI_reckon/lib/aux_func.h"

const int base_axirf = 0x44000000;

int main() {

    mmio_region_t AXI_RF = mmio_region_from_addr((uintptr_t)base_axirf);

    mmio_region_write32(AXI_RF, 7, 0xDEADBEEF);

    uint32_t AXIread = mmio_region_read32(AXI_RF, 7);
    
    char str[] = "Presidente!\r\n";
    uint32_t rtc_freq = *reg32(&__base_regs, CHESHIRE_RTC_FREQ_REG_OFFSET);
    uint64_t reset_freq = clint_get_core_freq(rtc_freq, 2500);
    uart_init(&__base_uart, reset_freq, __BOOT_BAUDRATE);
    uart_write_str(&__base_uart, str, sizeof(str));
    uart_write_str(&__base_uart, "\r\n", 2);
    uart_write_flush(&__base_uart);

    return 0;
}
