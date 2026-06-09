#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>

//#include "dif_spi_host.h"
#include "sw/device/lib/dif/dif_spi_host.h"
//#include "spi_host.h"
#include "regs/cheshire.h"
#include "dif/clint.h"
#include "dif/uart.h"
#include "params.h"
#include "util.h"

#define CLKDIV  8
#define CPHA    false
#define CPOL    false
#define FULLCYC false

#define TXFIFO_Dpth 72
#define NREADS      4

const uint32_t reckon_csid = 0;

int main() {

    uint32_t rx_reckon_readback[NREADS];

    /////////////////SPI SIGNALS/////////////////
    bool poll_var_a = true, poll_var_r = false;

    spi_host_t spi0;
    spi0.base_addr = mmio_region_from_addr((uintptr_t)SPI_HOST_START_ADDRESS);

    uint32_t N_fill_TXFIFO, FIFO_fill = 0;
    uint32_t cmd_reg_reckon, conf_reg_reckon;

    spi_configopts_t conf_struct_reckon;
    spi_command_t cmd_struct_reckon;

    spi_ch_status_t TX_status;

    /////////////////GPIO SIGNALS/////////////////
    gpio_result_t gpio_res;
    gpio_cfg_t gpio_start_cfg;
    gpio_cfg_t gpio_stop_cfg;
    gpio_cfg_t gpio_rst_cfg;
    gpio_cfg_t gpio_test_cfg;
    
    //////////////////////////////////////////////    
    
    conf_struct_reckon.clkdiv       = CLKDIV/2-1;
    conf_struct_reckon.fullcyc      = FULLCYC;
    conf_struct_reckon.cpha         = CPHA;
    conf_struct_reckon.cpol         = CPOL;
    conf_struct_reckon.csnlead      = 0;
    conf_struct_reckon.csntrail     = 0;
    conf_struct_reckon.csnidle      = 0;

    //cmd_struct_reckon.len           = 4*NPARAM*2-1;
    //cmd_struct_reckon.csaat         = 0;
    //cmd_struct_reckon.speed         = 0;
    //cmd_struct_reckon.direction     = 2;

    gpio_start_cfg.pin              = GPIO_START;
    gpio_start_cfg.mode             = GpioModeOutPushPull;

    gpio_stop_cfg.pin               = GPIO_STOP;
    gpio_stop_cfg.mode              = GpioModeOutPushPull;

    gpio_rst_cfg.pin                = GPIO_RST;
    gpio_rst_cfg.mode               = GpioModeOutPushPull;

    gpio_test_cfg.pin               = GPIO_TEST;
    gpio_test_cfg.mode              = GpioModeOutPushPull;

    gpio_res += gpio_config(gpio_start_cfg);
    gpio_res += gpio_config(gpio_stop_cfg);
    gpio_res += gpio_config(gpio_rst_cfg);
    gpio_res += gpio_config(gpio_test_cfg);

    ////////////////////////////////////////////// 
    
    ///////////RESET ReckOn///////////////////////

    gpio_write(GPIO_RST, false);
    gpio_write(GPIO_TEST, false);
    gpio_write(GPIO_STOP, false);
    gpio_write(GPIO_START, false);

    spi_set_enable(&spi0, true);
    spi_output_enable(&spi0, true);

    conf_reg_reckon = spi_create_configopts(conf_struct_reckon);
    spi_set_configopts(&spi0, reckon_csid, conf_reg_reckon);

    //spi_set_csid(&spi0, reckon_csid);
    //cmd_reg_reckon = spi_create_command(cmd_struct_reckon);

//////////////////////////////////////////////////
    // Write the command to ReckOn
    cmd_struct_reckon.len          = 7;
    cmd_struct_reckon.csaat        = 0;
    cmd_struct_reckon.speed        = 0;
    cmd_struct_reckon.direction    = 2;
    cmd_reg_reckon = spi_create_command(cmd_struct_reckon);

    printf("ReckOn SPI configuration with %d parameters\n\r", NPARAM);

    reckon_enable_SPI_EN_CONF(&spi0, reckon_csid);
    for (int i = 0; i < NPARAM; i++) {
        // Write the parameter to ReckOn
        //First load parameter address and data in the TXFIFO
        spi_write_word_2(&spi0, tx_reckon_conf[2*i]);
        spi_write_word_2(&spi0, tx_reckon_conf[2*i+1]);
        //printf("Parameter %d - ADD: %08X, CMD: %08X\n\r", i, tx_reckon_conf[2*i], tx_reckon_conf[2*i+1]);
        //address the spi0
        spi_set_csid(&spi0, reckon_csid);
        spi_wait_for_ready(&spi0);
        spi_set_command(&spi0, cmd_reg_reckon);
        //printf("%d - ", i+1);
        //printf("ERR: 0x%08X\n\r", mmio_region_read32(spi0.base_addr, SPI_HOST_STATUS_REG_OFFSET) & 0x0000003F);
        //Then send the data to ReckOn
    }
    spi_wait_for_tx_empty(&spi0);
    //reckon_disable_SPI_EN_CONF(&spi0, reckon_csid);

    //uint32_t SPI_words[5] = {0x30040000, 0xFFFFFFFF, 0xAAAAAAAA, 0xDEADBEEF, 0x12345678};

    //send_SPI_words(&spi0, reckon_csid, 5, SPI_words);
    
    //lettura winp
    //SPI_send_read_cmd(&spi0, reckon_csid, 0xB0000004, (uint16_t)NREADS, rx_reckon_readback);

    //lettura inferenza
    uint32_t infer_count = 0;
    reckon_disable_SPI_EN_CONF(&spi0, reckon_csid);
    //SPI_send_read_cmd(&spi0, reckon_csid, 0xE0000000, 1, &infer_count);

/*
    int command_uart = 0;
    for(;;) {
        printf("Send command:\n\r");
        while (scanf("%d\n", &command_uart)==0) {}
        if (command_uart==1) {
            gpio_write(GPIO_START, true);
        }
    }
*/  //gpio_write(GPIO_RST, true);
    //gpio_write(GPIO_START, true);
    //gpio_write(GPIO_STOP, true);
    
    return 0;
}
