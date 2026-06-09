// Generated register defines for spi_host

// Copyright information found in source file:
// Copyright lowRISC contributors.

// Licensing information found in source file:
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifdef __cplusplus
extern "C" {
#endif
// The number of active-low chip select (cs_n) lines to create.
// #define SPI_HOST_PARAM_NUM_C_S 3

// The size of the Tx FIFO (in words)
// #define SPI_HOST_PARAM_TX_DEPTH 72

// The size of the Rx FIFO (in words)
// #define SPI_HOST_PARAM_RX_DEPTH 64

// The size of the Cmd FIFO (one segment descriptor per entry)
// #define SPI_HOST_PARAM_CMD_DEPTH 4

// Number of alerts
//  #define SPI_HOST_PARAM_NUM_ALERTS 1

// Register width
// #define SPI_HOST_PARAM_REG_WIDTH 32

// Common Interrupt Offsets
// #define SPI_HOST_INTR_COMMON_ERROR_BIT 0
// #define SPI_HOST_INTR_COMMON_SPI_EVENT_BIT 1

// Interrupt State Register
// #define SPI_HOST_INTR_STATE_REG_OFFSET 0x0

// Interrupt Enable Register
// #define SPI_HOST_INTR_ENABLE_REG_OFFSET 0x4

// Interrupt Test Register
// #define SPI_HOST_INTR_TEST_REG_OFFSET 0x8

// Alert Test Register
// #define SPI_HOST_ALERT_TEST_REG_OFFSET 0xc

// Control register
#define SPI_HOST_CONTROL_REG_OFFSET_NEW 0x10

// Status register
#define SPI_HOST_STATUS_REG_OFFSET_NEW  0x14
#define SPI_HOST_STATUS_READY_BIT_NEW   31
#define SPI_HOST_STATUS_TXEMPTY_BIT_NEW 28

// Configuration options register.
#define SPI_HOST_CONFIGOPTS_0_REG_OFFSET_NEW 0x18

// Configuration options register.
#define SPI_HOST_CONFIGOPTS_1_REG_OFFSET_NEW 0x1c

// Configuration options register.
#define SPI_HOST_CONFIGOPTS_2_REG_OFFSET_NEW 0x20

// Chip-Select ID
#define SPI_HOST_CSID_REG_OFFSET_NEW 0x1C

// Command Register
#define SPI_HOST_COMMAND_REG_OFFSET_NEW 0x20

// Memory area: SPI Receive Data.
#define SPI_HOST_RXDATA_REG_OFFSET_NEW 0x24

// Memory area: SPI Transmit Data.
#define SPI_HOST_TXDATA_REG_OFFSET_NEW 0x28

// Controls which classes of errors raise an interrupt.
#define SPI_HOST_ERROR_ENABLE_REG_OFFSET_NEW 0x2C

// Indicates that any errors that have occurred.
#define SPI_HOST_ERROR_STATUS_REG_OFFSET_NEW 0x30

// Controls which classes of SPI events raise an interrupt.
#define SPI_HOST_EVENT_ENABLE_REG_OFFSET_NEW 0x34

#ifdef __cplusplus
}  // extern "C"
#endif

// End generated register defines for spi_host