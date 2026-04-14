#include "sw/device/lib/dif/dif_spi_host.h"
// #include "reckon/reckon.h"
#include "reckon/reckon_params_vec.h"

#include "regs/cheshire.h"
#include "params.h"
#include "util.h"
#include "dif/uart.h"
#include "printf.h"

#define N_EPOCHS  10
#define N_SAMPLES 200

int main() {

    mmio_region_t SPI_MMIO = mmio_region_from_addr((uintptr_t)__base_spih);
    dif_spi_host_t *chs_spi;
    dif_spi_host_config_t chs_spi_config;
    
    uint32_t train_accuracy[N_EPOCHS], val_accuracy[N_EPOCHS];

    //uint32_t rtc_freq = *reg32(&__base_regs, CHESHIRE_RTC_FREQ_REG_OFFSET);

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

    write_spi_confreg(chs_spi, INFERACC_DELAY);
    write_spi_confreg(chs_spi, LABEL_DELAY);

    /// FINISH CONFIGURATION

    write_axirf(BATCH_SIZE_ADD, 200);
    write_axirf(N_SAMPLES_ADD,  200);
    write_axirf(N_EPOCH_ADD,    N_EPOCHS);
    write_axirf(DO_EPROP_ADD,   7);

    // Once configured, start experiment

    for (int i = 0; i < N_EPOCHS; i++) {
        write_axirf(DO_EPROP_ADD,   7);
        write_axirf(TEST_REG,       0);

        toggle_signal(NEW_EPOCH_REG, 1);

        wait_for_signal(EPOCH_DONE_REG);

        inference_train[i] = read_accuracy();

        printf("Train accuracy at epoch %d - %u/%d", i, inference_train[i], N_SAMPLES);
        toggle_signal(STOP_REG, 1);

        write_axirf(DO_EPROP_ADD,   0);
        write_axirf(TEST_REG,       1);
        
        toggle_signal(NEW_EPOCH_REG, 1);

        wait_for_signal(EPOCH_DONE_REG);

        inference_val[i] = read_accuracy();

        printf("Validation accuracy at epoch %d - %u/%d", i, inference_val[i], N_SAMPLES);
        toggle_signal(STOP_REG, 1);
    }

}