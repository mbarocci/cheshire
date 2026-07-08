#include "sw/device/lib/dif/dif_spi_host.h"

#define INFER_COUNT_REG 0
#define BATCH_DONE_REG  1
#define EPOCH_DONE_REG  2
#define TEST_REG        3

#define N_READ_REGS     4

#define BATCH_SIZE_ADD  0
#define N_EPOCH_ADD     1
#define N_SAMPLES_ADD   2
#define DO_EPROP_ADD    3

#define NEW_EPOCH_gpio  4
#define NEW_BATCH_gpio  5
#define STOP_gpio       6
#define TEST_gpio       7

#define N_WRITE_REGS    8

#define N_GPIO_REGS     3

#define COUNTER_CONF_START_ADD N_READ_REGS + N_WRITE_REGS + N_GPIO_REGS
#define COUNTER_READ_ADD COUNTER_CONF_START_ADD + 8

#define COUNTER_IDLE_STATE  0
#define COUNTER_READM_STATE 1
#define COUNTER_ENDS_STATE  2
#define COUNTER_TICK_STATE  3
#define COUNTER_ENDE_STATE  4
#define COUNTER_LABEL_STATE 5
#define COUNTER_ENDB_STATE  6
#define COUNTER_SPIKE_STATE 7
#define COUNTER_NIDLE_STATE 8
#define COUNTER_NSAMPLE_STATE 9
#define COUNTER_NSAMPLE_LENGTH 11
#define COUNTER_SMPLEP_BIT    20
#define COUNTER_SMPLBT_BIT    21

#define SPI_BASE_ADDR (mmio_region_t){.base = (void *)&__base_spih}

///////////////////////////////
///////////// SPI /////////////
///////////////////////////////

uint32_t rck_write_txfifo_byteorder(uint32_t data);

uint32_t rck_gen_spi_cmd(uint32_t N_bytes);

bool wait_for_ready(mmio_region_t base, ptrdiff_t offset, bitfield_bit32_index_t bit_index);

///////////////////////////////
///////////// AXI /////////////
///////////////////////////////

void rck_write_axirf(int offset, uint32_t value);

unsigned int rck_read_axirf(int offset);

void rck_toggle_signal(int offset, int value);

bool rck_wait_for_signal(int offset);

uint32_t rck_read_accuracy();

void rck_set_counter_conf(int nr_count, uint32_t value);

uint32_t rck_get_counter_value(int nr_count);