#include "reckon/reckon.h"

#define RST_MODE_ADD            8
//#define DO_EPROP_ADD            9
#define LOCAL_TICK_ADD          10
#define ERROR_HALT_ADD          11
#define FP_LOC_WINP_ADD         12
#define FP_LOC_WREC_ADD         13
#define FP_LOC_WOUT_ADD         14
#define FP_LOC_TINP_ADD         15
#define FP_LOC_TREC_ADD         16
#define FP_LOC_TOUT_ADD         17
#define LEARN_SIG_SCALE_ADD     18
#define REGUL_MODE_ADD          19
#define REGUL_W_ADD             20
#define EN_STOCH_ROUND_ADD      21
#define TIMING_MODE_ADD         23
#define REGRESSION_ADD          25
#define SINGLE_LABEL_ADD        26
#define NO_OUT_ACT_ADD          27
#define SEND_PER_TIMESTEP_ADD   30
#define SEND_LABEL_ONLY_ADD     31
#define NOISE_EN_ADD            32
#define FORCE_TRACES_ADD        33
#define LABEL_DELAY_ADD         37
#define INFERACC_DELAY_ADD      39
#define LABEL_DELAY_ADD         37
#define CYCLES_PER_TICK_ADD     64
#define ALPHA_CONF0_ADD         65
#define ALPHA_CONF1_ADD         66
#define ALPHA_CONF2_ADD         67
#define ALPHA_CONF3_ADD         68
#define KAPPA_ADD               69
#define THR_H_0_ADD             70
#define THR_H_1_ADD             71
#define THR_H_2_ADD             72
#define THR_H_3_ADD             73
#define H_0_ADD                 74
#define H_1_ADD                 75
#define H_2_ADD                 76
#define H_3_ADD                 77
#define H_4_ADD                 78
#define LR_R_WINP_ADD           79
#define LR_P_WINP_ADD           80
#define LR_R_WREC_ADD           81
#define LR_P_WREC_ADD           82
#define LR_R_WOUT_ADD           83
#define LR_P_WOUT_ADD           84
#define SEED_INP_ADD            85
#define SEED_REC_ADD            86
#define SEED_OUT_ADD            87
#define SEED_STRND_NEUR_ADD     88
#define SEED_STRND_ONEUR_ADD    89
#define SEED_STRND_TINP_ADD     90
#define SEED_STRND_TREC_ADD     91
#define SEED_STRND_TOUT_ADD     92
#define SEED_NOISE_NEUR_ADD     93
#define NUM_INP_NEUR_ADD        94
#define NUM_REC_NEUR_ADD        95
#define NUM_OUT_NEUR_ADD        96
#define REGUL_F0_ADD            98
#define REGUL_K_INP_R_ADD       99
#define REGUL_K_INP_P_ADD       100
#define REGUL_K_REC_R_ADD       101
#define REGUL_K_REC_P_ADD       102
#define REGUL_K_MUL_ADD         103
#define NOISE_STR_ADD           104

/* =========================================================
 * SPI Parameter Initializers
 * ========================================================= */

// #define DO_EPROP_VAL            0x0
#define RST_MODE_VAL            1
#define LOCAL_TICK_VAL          0
#define ERROR_HALT_VAL          1
#define FP_LOC_WINP_VAL         3
#define FP_LOC_WREC_VAL         3
#define FP_LOC_WOUT_VAL         3
#define FP_LOC_TINP_VAL         3
#define FP_LOC_TREC_VAL         4
#define FP_LOC_TOUT_VAL         6
#define LEARN_SIG_SCALE_VAL     5
#define REGUL_MODE_VAL          2
#define REGUL_W_VAL             3
#define EN_STOCH_ROUND_VAL      1
#define TIMING_MODE_VAL         0
#define REGRESSION_VAL          0
#define SINGLE_LABEL_VAL        1
#define NO_OUT_ACT_VAL          0
#define SEND_PER_TIMESTEP_VAL   0
#define SEND_LABEL_ONLY_VAL     1
#define NOISE_EN_VAL            0
#define FORCE_TRACES_VAL        0
#define LABEL_DELAY_VAL         2
#define INFERACC_DELAY_VAL      2
#define KAPPA_VAL               0x7A
#define CYCLES_PER_TICK_VAL     4
#define ALPHA_CONF0_VAL         0
#define ALPHA_CONF1_VAL         0
#define ALPHA_CONF2_VAL         0
#define ALPHA_CONF3_VAL         0
#define THR_H_0_VAL             0xCD
#define THR_H_1_VAL             0xCD
#define THR_H_2_VAL             0xCD
#define THR_H_3_VAL             0xCD
#define H_0_VAL                 0
#define H_1_VAL                 0
#define H_2_VAL                 0
#define H_3_VAL                 0
#define H_4_VAL                 1
#define LR_R_WINP_VAL           0
#define LR_P_WINP_VAL           5
#define LR_R_WREC_VAL           0
#define LR_P_WREC_VAL           5
#define LR_R_WOUT_VAL           0
#define LR_P_WOUT_VAL           5
#define SEED_INP_VAL            0xF0F0
#define SEED_REC_VAL            0xF1F1
#define SEED_OUT_VAL            0xF2F2
#define SEED_STRND_NEUR_VAL     0x3F3FF3F3
#define SEED_STRND_ONEUR_VAL    0xF4F4
#define SEED_STRND_TINP_VAL     0x3F5FF5F5
#define SEED_STRND_TREC_VAL     0x3F6FF6F6
#define SEED_STRND_TOUT_VAL     0x3F7FF7F7
#define SEED_NOISE_NEUR_VAL     0xFF0
#define NUM_INP_NEUR_VAL        0xFF
#define NUM_REC_NEUR_VAL        0xFF
#define NUM_OUT_NEUR_VAL        0xF
#define REGUL_F0_VAL            0xA0
#define REGUL_K_INP_R_VAL       0
#define REGUL_K_INP_P_VAL       10
#define REGUL_K_REC_R_VAL       0
#define REGUL_K_REC_P_VAL       10
#define REGUL_K_MUL_VAL         0
#define NOISE_STR_VAL           0

// reckon_spi_command_t DO_EPROP = {
//     .address = DO_EPROP_ADD,
//     .data = DO_EPROP_VAL
// };

reckon_spi_command_t RST_MODE = {
    .address = RST_MODE_ADD,
    .data = RST_MODE_VAL
};

reckon_spi_command_t LOCAL_TICK = {
    .address = LOCAL_TICK_ADD,
    .data = LOCAL_TICK_VAL
};

reckon_spi_command_t ERROR_HALT = {
    .address = ERROR_HALT_ADD,
    .data = ERROR_HALT_VAL
};

reckon_spi_command_t FP_LOC_WINP = {
    .address = FP_LOC_WINP_ADD,
    .data = FP_LOC_WINP_VAL
};

reckon_spi_command_t FP_LOC_WREC = {
    .address = FP_LOC_WREC_ADD,
    .data = FP_LOC_WREC_VAL
};

reckon_spi_command_t FP_LOC_WOUT = {
    .address = FP_LOC_WOUT_ADD,
    .data = FP_LOC_WOUT_VAL
};

reckon_spi_command_t FP_LOC_TINP = {
    .address = FP_LOC_TINP_ADD,
    .data = FP_LOC_TINP_VAL
};

reckon_spi_command_t FP_LOC_TREC = {
    .address = FP_LOC_TREC_ADD,
    .data = FP_LOC_TREC_VAL
};

reckon_spi_command_t FP_LOC_TOUT = {
    .address = FP_LOC_TOUT_ADD,
    .data = FP_LOC_TOUT_VAL
};

reckon_spi_command_t LEARN_SIG_SCALE = {
    .address = LEARN_SIG_SCALE_ADD,
    .data = LEARN_SIG_SCALE_VAL
};

reckon_spi_command_t REGUL_MODE = {
    .address = REGUL_MODE_ADD,
    .data = REGUL_MODE_VAL
};

reckon_spi_command_t REGUL_W = {
    .address = REGUL_W_ADD,
    .data = REGUL_W_VAL
};

reckon_spi_command_t EN_STOCH_ROUND = {
    .address = EN_STOCH_ROUND_ADD,
    .data = EN_STOCH_ROUND_VAL
};

reckon_spi_command_t TIMING_MODE = {
    .address = TIMING_MODE_ADD,
    .data = TIMING_MODE_VAL
};

reckon_spi_command_t REGRESSION = {
    .address = REGRESSION_ADD,
    .data = REGRESSION_VAL
};

reckon_spi_command_t SINGLE_LABEL = {
    .address = SINGLE_LABEL_ADD,
    .data = SINGLE_LABEL_VAL
};

reckon_spi_command_t NO_OUT_ACT = {
    .address = NO_OUT_ACT_ADD,
    .data = NO_OUT_ACT_VAL
};

reckon_spi_command_t SEND_PER_TIMESTEP = {
    .address = SEND_PER_TIMESTEP_ADD,
    .data = SEND_PER_TIMESTEP_VAL
};

reckon_spi_command_t SEND_LABEL_ONLY = {
    .address = SEND_LABEL_ONLY_ADD,
    .data = SEND_LABEL_ONLY_VAL
};

reckon_spi_command_t NOISE_EN = {
    .address = NOISE_EN_ADD,
    .data = NOISE_EN_VAL
};

reckon_spi_command_t FORCE_TRACES = {
    .address = FORCE_TRACES_ADD,
    .data = FORCE_TRACES_VAL
};

reckon_spi_command_t KAPPA = {
    .address = KAPPA_ADD,
    .data = KAPPA_VAL
};

reckon_spi_command_t CYCLES_PER_TICK = {
    .address = CYCLES_PER_TICK_ADD,
    .data = CYCLES_PER_TICK_VAL
};

reckon_spi_command_t ALPHA_CONF0 = {
    .address = ALPHA_CONF0_ADD,
    .data = ALPHA_CONF0_VAL
};

reckon_spi_command_t ALPHA_CONF1 = {
    .address = ALPHA_CONF1_ADD,
    .data = ALPHA_CONF1_VAL
};

reckon_spi_command_t ALPHA_CONF2 = {
    .address = ALPHA_CONF2_ADD,
    .data = ALPHA_CONF2_VAL
};

reckon_spi_command_t ALPHA_CONF3 = {
    .address = ALPHA_CONF3_ADD,
    .data = ALPHA_CONF3_VAL
};

reckon_spi_command_t THR_H_0 = {
    .address = THR_H_0_ADD,
    .data = THR_H_0_VAL
};

reckon_spi_command_t THR_H_1 = {
    .address = THR_H_1_ADD,
    .data = THR_H_1_VAL
};

reckon_spi_command_t THR_H_2 = {
    .address = THR_H_2_ADD,
    .data = THR_H_2_VAL
};

reckon_spi_command_t THR_H_3 = {
    .address = THR_H_3_ADD,
    .data = THR_H_3_VAL
};

reckon_spi_command_t H_0 = {
    .address = H_0_ADD,
    .data = H_0_VAL
};

reckon_spi_command_t H_1 = {
    .address = H_1_ADD,
    .data = H_1_VAL
};

reckon_spi_command_t H_2 = {
    .address = H_2_ADD,
    .data = H_2_VAL
};

reckon_spi_command_t H_3 = {
    .address = H_3_ADD,
    .data = H_3_VAL
};

reckon_spi_command_t H_4 = {
    .address = H_4_ADD,
    .data = H_4_VAL
};

reckon_spi_command_t LR_R_WINP = {
    .address = LR_R_WINP_ADD,
    .data = LR_R_WINP_VAL
};

reckon_spi_command_t LR_P_WINP = {
    .address = LR_P_WINP_ADD,
    .data = LR_P_WINP_VAL
};

reckon_spi_command_t LR_R_WREC = {
    .address = LR_R_WREC_ADD,
    .data = LR_R_WREC_VAL
};

reckon_spi_command_t LR_P_WREC = {
    .address = LR_P_WREC_ADD,
    .data = LR_P_WREC_VAL
};

reckon_spi_command_t LR_R_WOUT = {
    .address = LR_R_WOUT_ADD,
    .data = LR_R_WOUT_VAL
};

reckon_spi_command_t LR_P_WOUT = {
    .address = LR_P_WOUT_ADD,
    .data = LR_P_WOUT_VAL
};

reckon_spi_command_t SEED_INP = {
    .address = SEED_INP_ADD,
    .data = SEED_INP_VAL
};

reckon_spi_command_t SEED_REC = {
    .address = SEED_REC_ADD,
    .data = SEED_REC_VAL
};

reckon_spi_command_t SEED_OUT = {
    .address = SEED_OUT_ADD,
    .data = SEED_OUT_VAL
};

reckon_spi_command_t SEED_STRND_NEUR = {
    .address = SEED_STRND_NEUR_ADD,
    .data = SEED_STRND_NEUR_VAL
};

reckon_spi_command_t SEED_STRND_ONEUR = {
    .address = SEED_STRND_ONEUR_ADD,
    .data = SEED_STRND_ONEUR_VAL
};

reckon_spi_command_t SEED_STRND_TINP = {
    .address = SEED_STRND_TINP_ADD,
    .data = SEED_STRND_TINP_VAL
};

reckon_spi_command_t SEED_STRND_TREC = {
    .address = SEED_STRND_TREC_ADD,
    .data = SEED_STRND_TREC_VAL
};

reckon_spi_command_t SEED_STRND_TOUT = {
    .address = SEED_STRND_TOUT_ADD,
    .data = SEED_STRND_TOUT_VAL
};

reckon_spi_command_t SEED_NOISE_NEUR = {
    .address = SEED_NOISE_NEUR_ADD,
    .data = SEED_NOISE_NEUR_VAL
};

reckon_spi_command_t NUM_INP_NEUR = {
    .address = NUM_INP_NEUR_ADD,
    .data = NUM_INP_NEUR_VAL
};

reckon_spi_command_t NUM_REC_NEUR = {
    .address = NUM_REC_NEUR_ADD,
    .data = NUM_REC_NEUR_VAL
};

reckon_spi_command_t NUM_OUT_NEUR = {
    .address = NUM_OUT_NEUR_ADD,
    .data = NUM_OUT_NEUR_VAL
};

reckon_spi_command_t REGUL_F0 = {
    .address = REGUL_F0_ADD,
    .data = REGUL_F0_VAL
};

reckon_spi_command_t REGUL_K_INP_R = {
    .address = REGUL_K_INP_R_ADD,
    .data = REGUL_K_INP_R_VAL
};

reckon_spi_command_t REGUL_K_INP_P = {
    .address = REGUL_K_INP_P_ADD,
    .data = REGUL_K_INP_P_VAL
};

reckon_spi_command_t REGUL_K_REC_R = {
    .address = REGUL_K_REC_R_ADD,
    .data = REGUL_K_REC_R_VAL
};

reckon_spi_command_t REGUL_K_REC_P = {
    .address = REGUL_K_REC_P_ADD,
    .data = REGUL_K_REC_P_VAL
};

reckon_spi_command_t REGUL_K_MUL = {
    .address = REGUL_K_MUL_ADD,
    .data = REGUL_K_MUL_VAL
};

reckon_spi_command_t NOISE_STR = {
    .address = NOISE_STR_ADD,
    .data = NOISE_STR_VAL
};

reckon_spi_command_t LABEL_DELAY = {
    .address = LABEL_DELAY_ADD,
    .data = LABEL_DELAY_VAL
};

reckon_spi_command_t INFERACC_DELAY = {
    .address = INFERACC_DELAY_ADD,
    .data = INFERACC_DELAY_VAL
};