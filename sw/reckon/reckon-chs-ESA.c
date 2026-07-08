#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>

#include "regs/cheshire.h"
#include "params.h"
#include "util.h"
#include "dif/uart.h"
#include "printf.h"

#include "reckon/reckon.h"
#include "reckon/winp.h"
#include "reckon/wrec.h"
#include "reckon/wout.h"
#include "reckon/reckon_params_vec.h"
#include "spi_host_regs.h"

#define ON  true
#define OFF false

#define N_EPOCHS 20
#define N_SAMPLES 200

#define TRAIN 7
#define VAL   0

#define MAX(a, b) (((a) > (b)) ? (a) : (b))
#define CEIL(n, m)   (((n) % m) != 0) ? ((n) + 1) : (n)

#define SRAM_WRITE 0
#define SRAM_READ  1

int main() {

    printf("\n\r----------------------------------------------------\n\r");
    dif_spi_host_t chs_spi = {.base_addr = SPI_BASE_ADDR};
    dif_spi_host_config_t chs_spi_config;
    // volatile bool ready = false;
    // volatile uint32_t status = 0;
    volatile uint32_t command_reg = 0;

    uint32_t inference_train[N_EPOCHS], inference_val[N_EPOCHS];

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
    volatile uint32_t control_reg = mmio_region_read32(SPI_BASE_ADDR, SPI_HOST_CONTROL_REG_OFFSET);
    
    mmio_region_write32(SPI_BASE_ADDR, SPI_HOST_CONTROL_REG_OFFSET, bitfield_bit32_write(control_reg, SPI_HOST_CONTROL_SW_RST_BIT, true));

    mmio_region_write32(SPI_BASE_ADDR, SPI_HOST_CONTROL_REG_OFFSET, bitfield_bit32_write(control_reg, SPI_HOST_CONTROL_SPIEN_BIT, true)); // Deassert reset and enabling IP + output

    dif_spi_host_configure_cs(&chs_spi, chs_spi_config, 0);

    mmio_region_write32(SPI_BASE_ADDR, SPI_HOST_CSID_REG_OFFSET,0);

    printf("Configuring the accelerator via SPI........\n\r");

    /*--OPENING SPI_EN_CONF--*/
    
    rck_write_txfifo_byteorder(0x00010000);
    rck_write_txfifo_byteorder(1);

    command_reg = rck_gen_spi_cmd(8);
    mmio_region_write32(SPI_BASE_ADDR, SPI_HOST_COMMAND_REG_OFFSET, command_reg);

    while(!wait_for_ready(SPI_BASE_ADDR, SPI_HOST_STATUS_REG_OFFSET, SPI_HOST_STATUS_TXEMPTY_BIT));

    // STEP 4: DATA TO TX FIFO
    // FIRST HALF OF WORDS
    
    for (int i = 0; i < NPARAM_RECKON; i++) {
        rck_write_txfifo_byteorder(reckon_spi_conf[i]);
    }
    
    // STEP 6: CHECK READY BIT
    while(!wait_for_ready(SPI_BASE_ADDR, SPI_HOST_STATUS_REG_OFFSET, SPI_HOST_STATUS_READY_BIT));

    // STEP 7: SEND SPI COMMAND
    command_reg = rck_gen_spi_cmd(NPARAM_RECKON*4);
    mmio_region_write32(SPI_BASE_ADDR, SPI_HOST_COMMAND_REG_OFFSET, command_reg);

    while(!wait_for_ready(SPI_BASE_ADDR, SPI_HOST_STATUS_REG_OFFSET, SPI_HOST_STATUS_TXEMPTY_BIT));

    for (int i = NPARAM_RECKON; i < NPARAM_RECKON*2; i++) {
        rck_write_txfifo_byteorder(reckon_spi_conf[i]);
    }

    // STEP 6: CHECK READY BIT
    while(!wait_for_ready(SPI_BASE_ADDR, SPI_HOST_STATUS_REG_OFFSET, SPI_HOST_STATUS_READY_BIT));

    // STEP 7: SEND SPI COMMAND
    command_reg = rck_gen_spi_cmd(NPARAM_RECKON*4);
    mmio_region_write32(SPI_BASE_ADDR, SPI_HOST_COMMAND_REG_OFFSET, command_reg);

    while(!wait_for_ready(SPI_BASE_ADDR, SPI_HOST_STATUS_REG_OFFSET, SPI_HOST_STATUS_TXEMPTY_BIT));

    /*--WRITING ON THE NEURON MEMORY--*/

    printf("Writing to neuron memory...\n\r");
    uint32_t num_rw = MAX(N_REC_NEUR, N_INP_NEUR);
    num_rw = CEIL(num_rw, 2);
    uint32_t spi_data = ((ALPHALSB & 0xFFF) << 20) | ((THRESHOLD) << 4);
    uint32_t spi_add  = (SRAM_WRITE << 31) | (1 << 28) | ((num_rw*2) << 16);
    
    rck_write_txfifo_byteorder(spi_add);
    for (uint32_t n =0; n < (num_rw >> 1); n++) {
        rck_write_txfifo_byteorder(0);
        rck_write_txfifo_byteorder(0);
        rck_write_txfifo_byteorder(0);
        rck_write_txfifo_byteorder(spi_data);
    }

    command_reg = rck_gen_spi_cmd(4 + num_rw*8);
    mmio_region_write32(SPI_BASE_ADDR, SPI_HOST_COMMAND_REG_OFFSET, command_reg);

    while(!wait_for_ready(SPI_BASE_ADDR, SPI_HOST_STATUS_REG_OFFSET, SPI_HOST_STATUS_TXEMPTY_BIT));

    /*--INITIALIZING RANDOM WEIGHTS--*/
    /*--INPUT WEIGHTS--*/
     
    printf("Writing input weights...\n\r");
    int p1 = 0;
    num_rw = CEIL(N_REC_NEUR, 4);
    num_rw = (num_rw >> 2) & 0xFFF;
    for (int n = 0; n < N_INP_NEUR; n++) {
        spi_add = (SRAM_WRITE << 31) | (0b011 << 28) | (num_rw << 16) | (n << 6);
        rck_write_txfifo_byteorder(spi_add);
        for (p1 = 0; p1 < N_REC_NEUR-3; p1+=4) {
            spi_data = 0;
            for (int p2 = 0; p2 < 4; p2++) {
                spi_data |= ((uint32_t)winp[n][p1+p2] & 0x000000FF) << (p2*8);
            }
            // printf("Data #%d to write: %08X\n\r", p1, spi_data);
            rck_write_txfifo_byteorder(spi_data);
        }
        spi_data = 0;

        if ((N_REC_NEUR & 0x3) != 0) {
            for (int r1=0;r1<(N_REC_NEUR & 0x3);r1++) {
                spi_data |= ((uint32_t)winp[n][r1+p1] & 0x000000FF) << (r1*8);
            }
            // printf("Data #%d to write: %08X\n\r", p1+1, spi_data);
            rck_write_txfifo_byteorder(spi_data);
        }
        command_reg = rck_gen_spi_cmd(4+num_rw*4);
        mmio_region_write32(SPI_BASE_ADDR, SPI_HOST_COMMAND_REG_OFFSET, command_reg);
        // printf("Writing neuron %d...\n\r", n);
        while(!wait_for_ready(SPI_BASE_ADDR, SPI_HOST_STATUS_REG_OFFSET, SPI_HOST_STATUS_TXEMPTY_BIT));
    }

    /*--RECURRENT WEIGHTS--*/

    printf("Writing recurrent weights...\n\r");
    num_rw = CEIL(N_REC_NEUR, 4);
    num_rw = (num_rw >> 2) & 0xFFF;
    for (int n = 0; n < N_REC_NEUR; n++) {
        spi_add = (SRAM_WRITE << 31) | (0b100 << 28) | (num_rw << 16) | (n << 6); // num_rw << 2 << 16
        rck_write_txfifo_byteorder(spi_add);
        for (p1 = 0; p1 < N_REC_NEUR-3; p1+=4) {
            spi_data = 0;
            for (int p2 = 0; p2 < 4; p2++) {
                spi_data |= ((uint32_t)wrec[n][p1+p2] & 0x000000FF) << (p2*8);
            }
            rck_write_txfifo_byteorder(spi_data);
        }
        spi_data = 0;
        if ((N_REC_NEUR & 0x3) != 0) {
            for (int r1=0;r1<(N_REC_NEUR & 0x3);r1++) {
                spi_data |= ((uint32_t)wrec[n][r1+p1] & 0x000000FF) << (r1*8);
            }
            rck_write_txfifo_byteorder(spi_data);
        }
        command_reg = rck_gen_spi_cmd(4+num_rw*4);
        mmio_region_write32(SPI_BASE_ADDR, SPI_HOST_COMMAND_REG_OFFSET, command_reg);

        while(!wait_for_ready(SPI_BASE_ADDR, SPI_HOST_STATUS_REG_OFFSET, SPI_HOST_STATUS_TXEMPTY_BIT));
    }

    /*--OUTPUT WEIGHTS--*/
    
    printf("Writing output weights...\n\r");
    num_rw = CEIL(N_OUT_NEUR, 4);
    num_rw = (num_rw >> 2) & 0xFFF;
    for (int n = 0; n < N_REC_NEUR; n++) {
        spi_add = (SRAM_WRITE << 31) | (0b101 << 28) | (num_rw << 16) | (n << 2); // num_rw << 2 << 16
        rck_write_txfifo_byteorder(spi_add);
        for (p1 = 0; p1 < N_OUT_NEUR-3; p1+=4) {
            spi_data = 0;
            for (int p2 = 0; p2 < 4; p2++) {
                spi_data |= ((uint32_t)wout[n][p1+p2] & 0x000000FF) << (p2*8);
            }
            rck_write_txfifo_byteorder(spi_data);
        }
        spi_data = 0;
        if ((N_REC_NEUR & 0x3) != 0) {
            for (int r1=0;r1<(N_OUT_NEUR & 0x3);r1++) {
                spi_data |= ((uint32_t)wout[n][r1+p1] & 0x000000FF) << (r1*8);
            }
            rck_write_txfifo_byteorder(spi_data);
        }
        command_reg = rck_gen_spi_cmd(4+num_rw*4);
        mmio_region_write32(SPI_BASE_ADDR, SPI_HOST_COMMAND_REG_OFFSET, command_reg);

        while(!wait_for_ready(SPI_BASE_ADDR, SPI_HOST_STATUS_REG_OFFSET, SPI_HOST_STATUS_TXEMPTY_BIT));
    }

    /*--CLOSING SPI_EN_CONF--*/

    rck_write_txfifo_byteorder(0x00010000);
    rck_write_txfifo_byteorder(0);

    command_reg = rck_gen_spi_cmd(8);
    mmio_region_write32(SPI_BASE_ADDR, SPI_HOST_COMMAND_REG_OFFSET, command_reg);

    while(!wait_for_ready(SPI_BASE_ADDR, SPI_HOST_STATUS_REG_OFFSET, SPI_HOST_STATUS_TXEMPTY_BIT));

    printf("Configuration complete\n\r");

    /*CONFIGURING THE EXPERIMENT*/

    rck_write_axirf(BATCH_SIZE_ADD, N_SAMPLES);
    rck_write_axirf(N_EPOCH_ADD,    N_EPOCHS);
    rck_write_axirf(N_SAMPLES_ADD,  N_SAMPLES);

    // printf("Starting the experiment %08X\n\r", rck_read_axirf(TEST_REG));

    printf("Starting the experiment.......\n\r");
    rck_set_counter_conf(0, 0);

    for (int i = 0; i < N_EPOCHS; i++) {
        rck_write_axirf(DO_EPROP_ADD,   TRAIN);
        rck_write_axirf(TEST_gpio,       0);

        rck_toggle_signal(NEW_EPOCH_gpio, 1);

        rck_wait_for_signal(EPOCH_DONE_REG);

        inference_train[0] = rck_read_accuracy();

        printf("Train accuracy at epoch %d -------- %u/%d\n\r", i+1, inference_train[0], N_SAMPLES);
        
        rck_toggle_signal(STOP_gpio, 1);

        rck_write_axirf(DO_EPROP_ADD,   VAL);
        rck_write_axirf(TEST_gpio,       1);
        
        rck_toggle_signal(NEW_EPOCH_gpio, 1);

        rck_wait_for_signal(EPOCH_DONE_REG);

        inference_val[i] = rck_read_accuracy();
        printf("Validation accuracy at epoch %d --- %u/%d\n\r", i+1, inference_val[i], N_SAMPLES);
        printf("-------------------------------------------\n\r");
        rck_toggle_signal(STOP_gpio, 1);
    }

    printf("ENDEXPERIMENT\n\r");
    return 0;
}