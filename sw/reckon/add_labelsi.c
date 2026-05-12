#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>

#define STR_HELPER(x) #x
#define STR(x) STR_HELPER(x)

#define TRAIN 0
#define VAL   1

int main(void) {
    // Organize pointers into arrays to loop through them
    FILE *in_ds[2], *in_lb[2], *out_mem[2];

    // Open Training Files
    in_ds[TRAIN]  = fopen(STR(TRAIN_DS_PATH), "r");
    in_lb[TRAIN]  = fopen(STR(TRAIN_LB_PATH), "r");
    out_mem[TRAIN] = fopen("target/xilinx/memfile/aertrain_ds.mem", "w");

    // Open Validation Files
    in_ds[VAL]  = fopen(STR(VAL_DS_PATH), "r");
    in_lb[VAL]  = fopen(STR(VAL_LB_PATH), "r");
    out_mem[VAL] = fopen("target/xilinx/memfile/aerval_ds.mem", "w");

    // CRITICAL: Verify all files opened successfully
    for (int i = 0; i < 2; i++) {
        if (!in_ds[i] || !in_lb[i] || !out_mem[i]) {
            fprintf(stderr, "Error: One or more files failed to open for index %d\n", i);
            return 1; 
        }
    }

    char line[12], label_line[5];
    u_int32_t word, label_word, label, tick_n, tick_o, code;

    // Loop through both datasets (Train and Val)
    for (int i = 0; i < 2; i++) {
        int cnt = 0;
        tick_n = 0;
        tick_o = 0;

        while (fgets(line, sizeof(line), in_ds[i])) {
            cnt++;
            word = (u_int32_t)strtoul(line, NULL, 16);
            code = (word >> 24) & 0xFF;

            if (code == 0x01) {
                tick_n = 0;
            } else {
                tick_n = word & 0x00000FFF;
            }

            // Logic for inserting labels based on delay
            if ((tick_o < LABEL_DELAY) && (tick_n >= LABEL_DELAY) && (code == 3)) {
                if (fgets(label_line, sizeof(label_line), in_lb[i])) {
                    label = (u_int32_t)strtoul(label_line, NULL, 10);
                    label_word = 0x02000000 | (label << 12);
                    fprintf(out_mem[i], "%08X\n", label_word);
                }
            }

            fprintf(out_mem[i], "%08X\n", word);
            tick_o = tick_n;
        }

        // Close files for this iteration
        fclose(in_ds[i]);
        fclose(in_lb[i]);
        fclose(out_mem[i]);
    }

    return 0;
}